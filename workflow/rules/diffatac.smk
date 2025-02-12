# functions
def get_diffatac_input():
    expected_filelist = list()
    deffiles = list()
# diffatac only works for hg38 and mm10
    if GENOME == "mm10" or GENOME == "hg38":
        if CONTRASTS.shape[0] != 0:
            expected_filelist = [ join(RESULTSDIR,"peaks","genrich","DiffATAC","degs.done") ]
            expected_filelist.append([ join(RESULTSDIR,"peaks","genrich","DiffATAC","all_diff_atacs.html"),
                                    join(RESULTSDIR,"peaks","genrich","DiffATAC","all_diff_atacs.tsv")])
    return expected_filelist



rule atac_calculate_regions_of_interest_for_diffatac:
# """
# take genrich/macs consensus fixed width peaks and calculate ROIs
# """
    input:
        expand(join(RESULTSDIR,"peaks","{{peakcaller}}","fixed_width","{sample}.renormalized.fixed_width.consensus.narrowPeak"),sample=SAMPLES)
    output:
        roi              = join(RESULTSDIR,"peaks","{peakcaller}","fixed_width","ROI.narrowPeak"),
        roi_bed          = join(RESULTSDIR,"peaks","{peakcaller}","fixed_width","ROI.bed"),
        roi_gtf          = join(RESULTSDIR,"peaks","{peakcaller}","fixed_width","ROI.gtf"),
        roi_renormalized = join(RESULTSDIR,"peaks","{peakcaller}","fixed_width","ROI.renormalized.narrowPeak")
    params:
        script      =   "ccbr_atac_get_fixedwidth_consensus_renormalized_peaks.sh",
        scriptsdir  =   SCRIPTSDIR,
        width       =   config["fixed_width"],
        roi_min_rep =   config['roi_min_replicates'],
        roi_min_spm =   config['roi_min_spm'],
    container: config["masterdocker"]
    shell:"""
set -exo pipefail
TMPDIR="/lscratch/$SLURM_JOB_ID"
if [ ! -d $TMPDIR ];then
    TMPDIR="/dev/shm"
fi

# get bedToGenePred genePredToGtf these are missing from the docker
cd $TMPDIR
wget -q -O bedToGenePred https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToGenePred
chmod a+x bedToGenePred
wget -q -O genePredToGtf https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/genePredToGtf
chmod a+x genePredToGtf

NPS=""
SAMPLENAMES=""
count=0
for i in {input}
do
    count=$((count+1))
    samplename=`basename $i | awk -F".renormalized" '{{print $1}}'`
    if [ "$count" == "1" ];then
        NPS="${{i}}"
        SAMPLENAMES="${{samplename}}"
        outdir=`dirname $i`
    else
        NPS="${{NPS}},${{i}}"
        SAMPLENAMES="${{SAMPLENAMES}},${{samplename}}"
    fi
done

cd $outdir
bash {params.scriptsdir}/{params.script} \
    --narrowpeaks $NPS \
    --replicatenames $SAMPLENAMES \
    --width {params.width} \
    --samplename "ROI" \
    --consensusnp {output.roi} \
    --consensusrenormnp {output.roi_renormalized} \
    --consensusminrep {params.roi_min_rep} \
    --consensusminspm {params.roi_min_spm} \
    --tmpdir $TMPDIR \
    --nofixedwidth \
    --scriptsfolder {params.scriptsdir}
cut -f1-6 {output.roi} > {output.roi_bed}
bedSort {output.roi_bed} {output.roi_bed}
${{TMPDIR}}/bedToGenePred {output.roi_bed} /dev/stdout | ${{TMPDIR}}/genePredToGtf file /dev/stdin {output.roi_gtf}
"""

rule get_counts_table:
    input:
        files   =   expand(join(RESULTSDIR,"peaks","{{peakcaller}}","{sample}.{{peakcaller}}.tn5nicksbedfiles"),sample=SAMPLES),
        gtf     =   join(RESULTSDIR,"peaks","{peakcaller}","fixed_width","ROI.gtf")
    output:
        counts  =   join(RESULTSDIR,"peaks","{peakcaller}","ROI.counts.tsv")
    params:
        scriptsdir  =   SCRIPTSDIR,
    threads: getthreads("get_counts_table")
    container: config['featurecountsdocker']
    shell:"""
set -exo pipefail
TMPDIR="/lscratch/$SLURM_JOB_ID"
if [ ! -d $TMPDIR ];then
    TMPDIR="/dev/shm"
fi
cd $TMPDIR
unset PYTHONPATH

bams=""
count=0
for f in {input.files}
do
while read a b c;do
    count=$((count+1))
    if [ "$count" == "1" ];then
        bams="$c"
    else
        bams="$bams $c"
    fi
done < $f
done

featureCounts -a {input.gtf} -o ${{TMPDIR}}/`basename {output.counts}` -s 0 -t transcript -g transcript_id -T {threads} $bams > featureCounts.log 2>&1
cat ${{TMPDIR}}/`basename {output.counts}` | python {params.scriptsdir}/_featureCounts_header_fix.py - > {output.counts}
"""

rule diffatac:
    input:
        counts      = join(RESULTSDIR,"peaks","{peakcaller}","ROI.counts.tsv"),
    output:
        degsdone    = join(RESULTSDIR,"peaks","{peakcaller}","DiffATAC","degs.done"),
    params:
        contrasts   = config['contrasts'],
        scriptsdir  = SCRIPTSDIR,
        sampleinfo  = SAMPLEINFO,
        genome      = config['genome'],
        fc_cutoff   = config['contrasts_fc_cutoff'],
        fdr_cutoff  = config['contrasts_fdr_cutoff'],
        manifest    = config['samplemanifest'],
    container: config['baser']
    shell:"""
set -exo pipefail
TMPDIR="/lscratch/$SLURM_JOB_ID"
if [ ! -d $TMPDIR ];then
    TMPDIR="/dev/shm"
fi
outdir=$(dirname {output.degsdone})
if [ ! -d $outdir ];then
    mkdir -p $outdir
fi
cd $outdir

echo "Contrast file:"
cat "{params.contrasts}" 

# Ensure contrasts file is not empty
if [ ! -s "{params.contrasts}" ]; then
    echo "Error: {params.contrasts} is empty"
    exit 1
fi

# Read contrasts file into an array
mapfile -t lines < "{params.contrasts}"

# Ensure mapfile read lines successfully
if [ ${{#lines[@]}} -eq 0 ]; then
    echo "Error: {params.contrasts} is empty after reading with mapfile"
    exit 1
fi

# Process each contrast line
for line in "${{lines[@]}}"; do
    IFS=$'\\t' read -r g1 g2 <<< "$line"
    
    if [ -z "$g1" ] || [ -z "$g2" ]; then
        echo "Error: Invalid contrast line: '$line'"
        continue
    fi

    echo "Processing contrast: g1=$g1, g2=$g2"
    Rscript {params.scriptsdir}/DESeq2_runner.R \\
        --countsmatrix {input.counts} \\
        --genome {params.genome} \\
        --coldata {params.sampleinfo} \\
        --contrastnumerator $g1 \\
        --contrastdenominator $g2 \\
        --foldchange {params.fc_cutoff} \\
        --fdr {params.fdr_cutoff} \\
        --indexcols Geneid \\
        --excludecols Chr,Start,End,Strand,Length \\
        --outdir $outdir \\
        --tmpdir $TMPDIR \\
        --scriptsdir {params.scriptsdir}
done && \
touch {output.degsdone}

"""

rule diffatac_aggregate:
    input:
        counts      = join(RESULTSDIR,"peaks","{peakcaller}","ROI.counts.tsv"),
        degsdone    = join(RESULTSDIR,"peaks","{peakcaller}","DiffATAC","degs.done"),
    output:
        alldegshtml = join(RESULTSDIR,"peaks","{peakcaller}","DiffATAC","all_diff_atacs.html"),
        alldegstsv  = join(RESULTSDIR,"peaks","{peakcaller}","DiffATAC","all_diff_atacs.tsv"),
    params:
        contrasts   = config['contrasts'],
        scriptsdir  = SCRIPTSDIR,
        sampleinfo  = SAMPLEINFO,
        genome      = config['genome'],
        fc_cutoff   = config['contrasts_fc_cutoff'],
        fdr_cutoff  = config['contrasts_fdr_cutoff'],
    container:config['baser']
    shell:"""
set -exo pipefail
TMPDIR="/lscratch/$SLURM_JOB_ID"
if [ ! -d $TMPDIR ];then
    TMPDIR="/dev/shm"
fi
outdir=$(dirname {input.degsdone})
cd $outdir
Rscript {params.scriptsdir}/aggregate_results_runner.R \\
    --countsmatrix {input.counts} \\
    --diffatacdir $outdir \\
    --coldata {params.sampleinfo} \\
    --foldchange {params.fc_cutoff} \\
    --fdr {params.fdr_cutoff} \\
    --indexcols Geneid \\
    --excludecols Chr,Start,End,Strand,Length \\
    --diffatacdir $outdir \\
    --tmpdir $TMPDIR \\
    --scriptsdir {params.scriptsdir}
"""
