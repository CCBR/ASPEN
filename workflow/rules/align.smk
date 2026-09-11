#########################################################
# FUNCTION DEFINITIONS
#########################################################

def get_fastqs(wildcards):
    """
    Return a dictionary of input files for the trimming rule.
    """
    d=dict()
    d["R1"]=REPLICATESDF["R1"][wildcards.replicate]
    d["R2"]=REPLICATESDF["R2"][wildcards.replicate]
    return d

#########################################################

localrules: align_stats

#########################################################

rule trim:
# """
# First step of TAD
# Input: raw fastq files
# Output: trimmed fastq files in "tmp" folder, so they can be
# deleted if no longer required.
# """
    # group: "TAD"
    input:
        unpack(get_fastqs)
    output:
        R1=join(RESULTSDIR,"tmp","trim","{replicate}.R1.trim.fastq.gz"),
        R2=join(RESULTSDIR,"tmp","trim","{replicate}.R2.trim.fastq.gz"),
    params:
        replicate="{replicate}",
        scriptsdir=SCRIPTSDIR,
        script="ccbr_cutadapt_pe.bash"
    container: config["cutadaptdocker"]
    threads: getthreads("trim")
    shell:"""
if [ -w "/lscratch/${{SLURM_JOB_ID}}" ];then cd /lscratch/${{SLURM_JOB_ID}};else cd /dev/shm;fi
unset PYTHONPATH
bash {params.scriptsdir}/{params.script} \
--infastq1 {input.R1} \
--infastq2 {input.R2} \
--samplename {params.replicate} \
--threads {threads} \
--outfastq1 {output.R1} \
--outfastq2 {output.R2}
"""

#########################################################

rule create_BL_index:
# """
# Create bwa index from blacklist fasta file
# """
    # group: "TAD"
    input:
        fa=BLACKLISTFA,
    output:
        sa=join(RESULTSDIR,"tmp","BL",GENOME+"_blacklist.sa")
    params:
        # bldir=join(RESULTSDIR,"tmp","BL"),
        genome=GENOME,
    container: config["masterdocker"]
    threads: getthreads("create_BL_index")
    shell:"""
blindexdir=$(dirname {output.sa})
sabasename=$(basename {output.sa})
indexprefix=${{sabasename%.*}}
cd $blindexdir
bwa index -p $indexprefix {input.fa}
"""

#########################################################

rule remove_BL:
# """
# Second step of TAD
# Input: trimmed fastq files
# Output: not aligning to blacklisted regions, trimmed fastq files
# in "tmp" folder, so they can be deleted if no longer required.
# """
    # group: "TAD"
    input:
        R1=rules.trim.output.R1,
        R2=rules.trim.output.R2,
        sa=rules.create_BL_index.output.sa
    output:
        R1=join(RESULTSDIR,"tmp","trim","{replicate}.R1.noBL.fastq.gz"),
        R2=join(RESULTSDIR,"tmp","trim","{replicate}.R2.noBL.fastq.gz"),
    params:
        replicate="{replicate}",
        scriptsdir=SCRIPTSDIR,
        script="ccbr_remove_blacklisted_reads_pe.bash"
    container: config["masterdocker"]
    threads: getthreads("remove_BL")
    shell:"""
if [ -w "/lscratch/${{SLURM_JOB_ID}}" ];then cd /lscratch/${{SLURM_JOB_ID}};else cd /dev/shm;fi
sa={input.sa}
blindex=${{sa%.*}}
bash {params.scriptsdir}/{params.script} \
--infastq1 {input.R1} \
--infastq2 {input.R2} \
--samplename {params.replicate} \
--blindexdir $blindex \
--threads {threads} \
--outfastq1 {output.R1} \
--outfastq2 {output.R2}
"""

#########################################################

rule align:
# """
# Third (final) step of TAD
# Alignment is handled by bowtie
# Filtering is based off of ENCODEs pipeline (atac_assign_multimappers.py is directly pulled from ENCODE)
# Input: not aligning to blacklisted regions, trimmed fastq files
# Output:
#     1. aligned and filtered alignment files:
#         * tagAlign --> for MACS2
#         * dedup bam --> for TOBIAS
#         * qsorted bam --> for Genrich
#     2. QC files:
#         * nrf --> non-redundant fraction using preseq
#         * dupmetric --> to quantify duplication level using picard
#         * flagstat files --> quatify surviving reads at each step
# """
    # group: "TAD"
    input:
        R1=rules.remove_BL.output.R1,
        R2=rules.remove_BL.output.R2,
    output:
        tagAlign=join(RESULTSDIR,"alignment","tagAlign","{replicate}.tagAlign.gz"),
        filteredBam=join(RESULTSDIR,"alignment","filteredBam","{replicate}.filtered.bam"),
        dedupBam=join(RESULTSDIR,"alignment","dedupBam","{replicate}.dedup.bam"),
        qsortedBam=join(RESULTSDIR,"alignment","qsortedBam","{replicate}.qsorted.bam"),
        fs1=join(QCDIR,"{replicate}.bowtie2.bam.flagstat"),
        fs2=join(QCDIR,"{replicate}.dedup.bam.flagstat"),
        fs3=join(QCDIR,"{replicate}.filtered.bam.flagstat"),
        dupmetric=join(QCDIR,"{replicate}.dupmetric"),
        nrf=join(QCDIR,"preseq","{replicate}.nrf"),
    params:
        replicate="{replicate}",
        workdir=RESULTSDIR,
        qcdir=QCDIR,
        indexdir=INDEXDIR,
        scriptsdir=SCRIPTSDIR,
        genome=GENOME,
        chromosomes=CHROMS,
        script="ccbr_bowtie2_align_pe.bash",
        multimapping=config["multimapping"],
        mem=getmemG("align")
    container: config["masterdocker"]
    threads: getthreads("align")
    shell:"""
set -exo pipefail
if [ -w "/lscratch/${{SLURM_JOB_ID}}" ];then cd /lscratch/${{SLURM_JOB_ID}};else cd /dev/shm;fi
unset PYTHONPATH

# make folder if they do not exist
for  f in {output.tagAlign} {output.dedupBam} {output.qsortedBam} {output.filteredBam};do
if [ ! -w $(dirname $f) ];then
mkdir -p $(dirname $f)
fi
done

bash {params.scriptsdir}/{params.script} \
--infastq1 {input.R1} \
--infastq2 {input.R2} \
--samplename {params.replicate} \
--genomename {params.genome} \
--threads {threads} \
--mem {params.mem} \
--chromosomes "{params.chromosomes}" \
--indexdir {params.indexdir} \
--multimapping {params.multimapping} \
--scriptsfolder {params.scriptsdir}

rsync -az --progress --verbose --remove-source-files {params.replicate}.tagAlign.gz {output.tagAlign}
rsync -az --progress --verbose --remove-source-files {params.replicate}.qsorted.bam {output.qsortedBam}


rsync -az --progress --verbose --remove-source-files {params.replicate}.bowtie2.bam.flagstat {params.qcdir}/
rsync -az --progress --verbose --remove-source-files {params.replicate}.bowtie2.log {params.qcdir}/
rsync -az --progress --verbose --remove-source-files {params.replicate}.filtered.bam {output.filteredBam}
rsync -az --progress --verbose --remove-source-files {params.replicate}.filtered.bam.bai $(dirname {output.filteredBam})/
rsync -az --progress --verbose --remove-source-files {params.replicate}.dedup.bam {output.dedupBam}
rsync -az --progress --verbose --remove-source-files {params.replicate}.dedup.bam.bai $(dirname {output.dedupBam})/

rsync -az --progress --verbose --remove-source-files {params.replicate}.dedup.bam.flagstat {params.qcdir}/
rsync -az --progress --verbose --remove-source-files {params.replicate}.dupmetric {params.qcdir}/
rsync -az --progress --verbose --remove-source-files {params.replicate}.filtered.bam.flagstat {params.qcdir}/

rsync -az --progress --verbose --remove-source-files {params.replicate}.nrf {params.qcdir}/preseq/
rsync -az --progress --verbose --remove-source-files {params.replicate}.preseq {params.qcdir}/preseq/
rsync -az --progress --verbose --remove-source-files {params.replicate}.preseq.log {params.qcdir}/preseq/
"""

#########################################################

rule align_stats:
# """
# Collect stats at each TAD step
# Output: per-replicate nreads.txt file --> required by MultiQC for reporting.
# """
    # group: "TAD"
    input:
        unpack(get_fastqs),
        trimR1=rules.trim.output.R1,
        noBLR1=rules.remove_BL.output.R1,
        fs1=rules.align.output.fs3,
        fs2=rules.align.output.fs2
    output:
        nreads=join(QCDIR,"{replicate}.nreads.txt"),
    params:
        replicate="{replicate}",
    shell:"""
nreads=`zcat {input.R1}|wc -l`
nreadstrim=`zcat {input.trimR1}|wc -l`
echo "$nreads $nreadstrim"|awk '{{printf("%d\\tInput Nreads\\n%d\\tAfter trimming\\n",$1/2,$2/2)}}' > {output.nreads}
nreads=`zcat {input.noBLR1}|wc -l`
echo "$nreads"|awk '{{printf("%d\\tAfter removing mito-ribo reads\\n",$1/2)}}' >> {output.nreads}
nreads=`grep -m1 total {input.fs1}|awk '{{print $1}}'`
echo "$nreads"|awk '{{printf("%d\\tMapped reads\\n",$1)}}' >> {output.nreads}
nreads=`grep -m1 total {input.fs2}|awk '{{print $1}}'`
echo "$nreads"|awk '{{printf("%d\\tAfter deduplication\\n",$1)}}' >> {output.nreads}
"""


#########################################################


rule align2spikein:
# """
# Align reads to spike-in genome and count aligned reads
# Input: trimmed fastq files
# Output: spike-in read counts
# This rule aligns the trimmed fastq files to the spike-in genome and counts the number of aligned reads.
# Note: bwa-mem2 is use for alignment unlike bowtie2 for aligning to host genome.
# If spike-in is not enabled, the count is set to 0.
# """
    input:
        R1=rules.remove_BL.output.R1,
        R2=rules.remove_BL.output.R2,
    output:
        counts=join(RESULTSDIR,"spikein","{replicate}","{replicate}.counts"),
    params:
        replicate="{replicate}",
        workdir=RESULTSDIR,
        spikein=str(SPIKEIN).lower(),
        spikein_indexdir=SPIKEINDEXDIR,
        spikein_genome=SPIKEINGENOME,
        mem=getmemG("align2spikein")
    container: config["bwadocker"]
    threads: getthreads("align2spikein")
    shell:"""
set -exo pipefail
if [ -w "/lscratch/${{SLURM_JOB_ID}}" ];then cd /lscratch/${{SLURM_JOB_ID}};else cd /dev/shm;fi
unset PYTHONPATH

echo -ne "{params.replicate}\\t" > {output.counts}
if [[ "{params.spikein}" == "true" ]];then
# getting this errors
# Please verify that both the operating system and the processor support Intel(R) X87, CMOV, MMX, FXSAVE, SSE, SSE2, SSE3, SSSE3, SSE4_1, SSE4_2, MOVBE, POPCNT, F16C, AVX, FMA, BMI, LZCNT, AVX2, AVX512DQ, AVX512F, ADX, AVX512CD, AVX512BW, AVX512VL and CLWB instructions.
# hence changing the following line
for bwa_bin in bwa-mem2.avx512bw bwa-mem2.avx2 bwa-mem2.sse41; do
${{bwa_bin}} mem -t {threads} {params.spikein_indexdir}/{params.spikein_genome} {input.R1} {input.R2} | samtools view -@ {threads} -bS - > ${{TMPDIR}}/{params.replicate}.bam && break
done
samtools view -@ {threads} -f 2 -q 30 ${{TMPDIR}}/{params.replicate}.bam | wc -l | awk '{{printf "%d\\n", $1/2}}' >> {output.counts}
else
echo -ne "0\\n" >> {output.counts}
fi
"""

localrules: compute_scaling_factors
rule compute_scaling_factors:
# """
# Compute scaling factors for spike-in normalization
# Input: spike-in read counts for each replicate
# Output: scaling factors for each replicate
# This rule computes the scaling factors for each replicate based on the spike-in counts.
# If spike-in is enabled, the scaling factors are computed using the provided script.
# If spike-in is not enabled, the scaling factor is set to 1.0 for all replicates.
# """
    input:
        counts=expand(join(RESULTSDIR,"spikein","{replicate}","{replicate}.counts"),replicate=REPLICATES),
    output:
        scaling_factors=join(RESULTSDIR,"spikein","scaling_factors.tsv"),
    log:
        join(RESULTSDIR,"spikein","compute_scaling_factors.log"),
    params:
        replicates=REPLICATES,
        workdir=RESULTSDIR,
        scriptsdir=SCRIPTSDIR,
        spikein=str(SPIKEIN).lower(),
        script="_compute_downsampling_scaling_factors.py",
    container: config["masterdocker"]
    shell:"""
set -exo pipefail
TMPDIR="/lscratch/$SLURM_JOB_ID"
if [ ! -d $TMPDIR ];then
    TMPDIR="/dev/shm"
fi
unset PYTHONPATH

# Check if spike-in is enabled
if [[ "{params.spikein}" == "true" ]];then
    # Compute scaling factors using the provided script
    cat {input.counts} | python {params.scriptsdir}/{params.script} 2> {log} | sort > {output.scaling_factors}
else
    # If spike-in is not enabled, set scaling factor to 1.0 for all replicates
    cat {input.counts} | sort > ${{TMPDIR}}/allcounts.txt
    while read replicateName count;do
        echo -ne "$replicateName\\t$count\\t1.0\\n"
    done < ${{TMPDIR}}/allcounts.txt > {output.scaling_factors}
fi
"""


#########################################################


def get_bam_by_bamtype(wildcards):
# """
# Resolve the source BAM for a given {bamtype} wildcard value:
#   dedup    -> dedup.bam (PCR/optical duplicates removed by Picard MarkDuplicates)
#   nondedup -> filtered.bam (quality-filtered but duplicates retained)
# """
    if wildcards.bamtype == "dedup":
        return join(ALIGNDIR,"dedupBam",wildcards.replicate+".dedup.bam")
    elif wildcards.bamtype == "nondedup":
        return join(ALIGNDIR,"filteredBam",wildcards.replicate+".filtered.bam")
    else:
        raise ValueError("Unknown bamtype wildcard: "+wildcards.bamtype)

rule create_tn5bams:
# """
# Create tn5 and reads bam files for creating bigwigs
# Input: dedup or filtered (nondedup) BAM file from alignment step, selected via {bamtype}
# Output: tn5 and reads BAM files
# This rule generates tn5 and reads BAM files from the {bamtype} BAM file obtained after alignment.
# The tn5 BAM file contains the positions of Tn5 insertions, while the reads BAM file contains
# the positions of the filtered original reads. These BAM files are used to create bigwig files for
# visualization in genome browsers.
# """
    # group: "TAD"
    input:
        bam=get_bam_by_bamtype,
    output:
        tn5bam=join(RESULTSDIR,"visualization","{bamtype}","tn5sites_bam","{replicate}.tn5sites.bam"),
        readsbed=join(RESULTSDIR,"visualization","{bamtype}","reads_bed","{replicate}.reads.bed.gz"), # these will be used by chromVar
        readsbam=join(RESULTSDIR,"visualization","{bamtype}","reads_bam","{replicate}.reads.bam"),
    params:
        replicate="{replicate}",
        bamtype="{bamtype}",
        genome=GENOME,
        genomefile=GENOMEFILE,
        scriptsdir=SCRIPTSDIR,
        script="ccbr_atac_bam2tn5bed.py"
    container: config["masterdocker"]
    threads: getthreads("create_tn5bams")
    shell:"""
set -exo pipefail
unset PYTHONPATH
TMPDIR="/lscratch/$SLURM_JOB_ID"
if [ ! -d $TMPDIR ];then
    TMPDIR="/dev/shm"
fi
outdir=$(dirname {output.tn5bam})
if [ ! -d $outdir ];then
    mkdir -p $outdir
fi

# Sort the input BAM file by query name for faster access using pysam in the following python script
samtools sort -@ {threads} -n -o ${{TMPDIR}}/{params.replicate}.qSorted.bam {input.bam}

# Run the custom script to generate tn5 and reads bed files; input BAM needs to be sorted by query name
python {params.scriptsdir}/{params.script} \
    --bam ${{TMPDIR}}/{params.replicate}.qSorted.bam \
    --tn5bed ${{TMPDIR}}/{params.replicate}.tn5sites.bed \
    --readsbed ${{TMPDIR}}/{params.replicate}.reads.bed \
    --genomefile {params.genomefile}

# Sort the tn5 bed file
bedSort ${{TMPDIR}}/{params.replicate}.tn5sites.bed  ${{TMPDIR}}/{params.replicate}.tn5sites.bed

# Convert the tn5 bed file to BAM format
bedToBam -i  ${{TMPDIR}}/{params.replicate}.tn5sites.bed  -g {params.genomefile} > ${{TMPDIR}}/{params.replicate}.tn5sites.bam

# Sort and index the tn5 BAM file
samtools sort -@ {threads} -o {output.tn5bam} ${{TMPDIR}}/{params.replicate}.tn5sites.bam
samtools index {output.tn5bam}

# Sort the reads bed file
bedSort ${{TMPDIR}}/{params.replicate}.reads.bed  ${{TMPDIR}}/{params.replicate}.reads.bed
pigz -p {threads} -c ${{TMPDIR}}/{params.replicate}.reads.bed > {output.readsbed}

# Convert the reads bed file to BAM format
bedToBam -i  ${{TMPDIR}}/{params.replicate}.reads.bed  -g {params.genomefile} > ${{TMPDIR}}/{params.replicate}.reads.bam

# Sort and index the reads BAM file
samtools sort -@ {threads} -o {output.readsbam} ${{TMPDIR}}/{params.replicate}.reads.bam
samtools index {output.readsbam}
"""


#########################################################


rule create_bigwigs:
# """
# Create spike-in scaled bigwigs for visualization
# Input: tn5 and reads BAM files (per {bamtype}: dedup or nondedup), scaling factors
# Output: tn5 and reads bigwig files
# This rule generates bigwig files from tn5 and reads BAM files, applying the scaling factors
# computed from spike-in counts to normalize the coverage. The resulting bigwig files can be
# used for visualization in genome browsers.
# """
    input:
        tn5bam=rules.create_tn5bams.output.tn5bam,
        readsbam=rules.create_tn5bams.output.readsbam,
        scaling_factors=rules.compute_scaling_factors.output.scaling_factors
    output:
        tn5bw=join(RESULTSDIR,"visualization","{bamtype}","tn5sites_bigwig","{replicate}.tn5sites.bw"),
        readsbw=join(RESULTSDIR,"visualization","{bamtype}","reads_bigwig","{replicate}.reads.bw"),
    params:
        spikein=str(SPIKEIN).lower(),
        replicate="{replicate}",
        bamtype="{bamtype}",
        scriptsdir=SCRIPTSDIR,
        script="_print_replicate_scaling_factor.py"
    container: config["deeptoolsdocker"]
    threads: getthreads("create_bigwigs")
    shell:"""
set -exo pipefail
unset PYTHONPATH
TMPDIR="/lscratch/$SLURM_JOB_ID"
if [ ! -d $TMPDIR ];then
    TMPDIR="/dev/shm"
fi
outdir=$(dirname {output.tn5bw})
# Create output directory if it doesn't exist
if [ ! -d $outdir ];then
    mkdir -p $outdir
fi

# Get the scaling factor for the current replicate
sf=$(cat {input.scaling_factors} | python {params.scriptsdir}/{params.script} {params.replicate})

# Generate bigWig file from tn5 BAM file with scaling factor applied
bamCoverage \
    -b {input.tn5bam} \
    -o {output.tn5bw} \
    --binSize 10 \
    --normalizeUsing RPKM \
    --scaleFactor $sf \
    --numberOfProcessors {threads}

# Generate bigWig file from reads BAM file with scaling factor applied
bamCoverage \
    -b {input.readsbam} \
    -o {output.readsbw} \
    --binSize 10 \
    --normalizeUsing RPKM \
    --scaleFactor $sf \
    --numberOfProcessors {threads}
"""
