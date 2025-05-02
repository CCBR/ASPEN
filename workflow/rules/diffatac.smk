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


#########################################################


rule atac_calculate_regions_of_interest_for_diffatac:
# """
# take genrich/macs consensus fixed width peaks and calculate ROIs
# """
    input:
        expand(join(RESULTSDIR,"peaks","{{peakcaller}}","fixed_width","{sample}.{{peakcaller}}.renormalized.fixed_width.consensus.narrowPeak"),sample=SAMPLES)
    output:
        roi              = join(RESULTSDIR,"peaks","{peakcaller}","fixed_width","ROI.{peakcaller}.narrowPeak"),
        roi_bed          = join(RESULTSDIR,"peaks","{peakcaller}","fixed_width","ROI.{peakcaller}.bed"),
        roi_gtf          = join(RESULTSDIR,"peaks","{peakcaller}","fixed_width","ROI.{peakcaller}.gtf"),
        roi_renormalized = join(RESULTSDIR,"peaks","{peakcaller}","fixed_width","ROI.{peakcaller}.renormalized.narrowPeak")
    params:
        script      =   "ccbr_atac_get_fixedwidth_consensus_renormalized_peaks.sh",
        annotatescript = "ccbr_annotate_bed.R",
        scriptsdir  =   SCRIPTSDIR,
        genome      =   GENOME,
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
bedToGenePred {output.roi_bed} /dev/stdout | genePredToGtf file /dev/stdin {output.roi_gtf}
"""


#########################################################

rule annotate_roi:
    input:
        roi_bed = join(RESULTSDIR, "peaks", "{peakcaller}", "fixed_width", "ROI.{peakcaller}.bed"),
    output:
        roi_annotated = join(RESULTSDIR, "peaks", "{peakcaller}", "fixed_width", "ROI.{peakcaller}.bed.annotated.gz"),
        roi_genelist = join(RESULTSDIR, "peaks", "{peakcaller}", "fixed_width", "ROI.{peakcaller}.bed.genelist"),
        roi_annotation_summary = join(RESULTSDIR, "peaks", "{peakcaller}", "fixed_width", "ROI.{peakcaller}.bed.annotation_summary"),
        roi_annotation_distribution = join(RESULTSDIR, "peaks", "{peakcaller}", "fixed_width", "ROI.{peakcaller}.bed.annotation_distribution"),
    params:
        genome = config['genome'],
        scriptsdir = SCRIPTSDIR,
        annotatescript = "ccbr_annotate_bed.R"
    container: config['masterdocker']
    shell:"""
set -exo pipefail
annotated=$(echo {output.roi_annotated} | awk -F'.gz' '{{print $1}}')
Rscript {params.scriptsdir}/{params.annotatescript} -b {input.roi_bed} -a $annotated -g {params.genome} -l {output.roi_genelist} -f {output.roi_annotation_summary}
cut -f1,2 {output.roi_annotation_summary} > {output.roi_annotation_distribution}
gzip -n -f $annotated
ls -alrth $(dirname {output.roi_annotated})
"""

#########################################################


rule get_counts_table:
    input:
        bam_files = lambda wildcards: expand(
            join(RESULTSDIR, "visualization", "{method}_bam", "{replicate}.{method}.bam"),
            method=wildcards.method,
            replicate=REPLICATES
        ),
        gtf = join(RESULTSDIR,"peaks","{peakcaller}","fixed_width","ROI.{peakcaller}.gtf"),
    output:
        counts = join(RESULTSDIR, "peaks", "{peakcaller}", "fixed_width", "counts", "ROI.{peakcaller}.{method}_counts.tsv"),
    params:
        scriptsdir = SCRIPTSDIR,
        script = "_featureCounts_header_fix.py"
    threads: getthreads("get_counts_table")
    container: config['featurecountsdocker']
    shell:
        """
        set -exo pipefail
        TMPDIR="/lscratch/$SLURM_JOB_ID"
        if [ ! -d $TMPDIR ]; then
            TMPDIR="/dev/shm"
        fi
        cd $TMPDIR
        unset PYTHONPATH
        # Create output directory if it doesn't exist
        outdir=$(dirname {output.counts})
        if [ ! -d $outdir ]; then
            mkdir -p $outdir
        fi

        # Run featureCounts
        featureCounts -a {input.gtf} -o $TMPDIR/$(basename {output.counts}) -s 0 -t transcript -g transcript_id -T {threads} {input.bam_files} > featureCounts.log 2>&1
        cat $TMPDIR/$(basename {output.counts}) | python {params.scriptsdir}/{params.script} - > {output.counts}
        """


#########################################################


localrules: scale_counts_table
rule scale_counts_table:
    input:
        scaling_factors = rules.compute_scaling_factors.output.scaling_factors,
        counts = join(RESULTSDIR, "peaks", "{peakcaller}", "fixed_width", "counts", "ROI.{peakcaller}.{method}_counts.tsv"),
    output:
        scaledcounts = join(RESULTSDIR, "peaks", "{peakcaller}", "fixed_width", "counts", "ROI.{peakcaller}.{method}_scaled_counts.tsv")
    params:
        scriptsdir=SCRIPTSDIR,
        script="_scale_counts.py",
    container: config['masterdocker']
    shell:"""
set -exo pipefail
unset PYTHONPATH
python {params.scriptsdir}/{params.script} --counts {input.counts} --scaling_factors {input.scaling_factors} --output {output.scaledcounts}
"""


#########################################################


rule diffatac:
    input:
        counts = join(RESULTSDIR, "peaks", "{peakcaller}", "fixed_width", "counts", "ROI.{peakcaller}.{method}_counts.tsv")
    output:
        degsdone = join(PEAKSDIR, "{peakcaller}", "DiffATAC", "{method}", "degs.done")
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
    Rscript "{params.scriptsdir}/DESeq2_runner.R" \\
        --countsmatrix "{input.counts}" \\
        --genome "{params.genome}" \\
        --coldata "{params.sampleinfo}" \\
        --contrastnumerator "$g1" \\
        --contrastdenominator "$g2" \\
        --foldchange "{params.fc_cutoff}" \\
        --fdr "{params.fdr_cutoff}" \\
        --indexcols "Geneid" \\
        --excludecols "Chr,Start,End,Strand,Length" \\
        --outdir "$outdir" \\
        --tmpdir "$TMPDIR" \\
        --scriptsdir "{params.scriptsdir}"
done && \
touch {output.degsdone}

"""


#########################################################


rule diffatac_aggregate:
    input:
        counts      = join(RESULTSDIR, "peaks", "{peakcaller}", "fixed_width", "counts", "ROI.{peakcaller}.{method}_counts.tsv"),
        degsdone    = join(RESULTSDIR,"peaks","{peakcaller}","DiffATAC","{method}","degs.done"),
    output:
        alldegshtml = join(RESULTSDIR,"peaks","{peakcaller}","DiffATAC","{method}","all_diff_atacs.html"),
        alldegstsv  = join(RESULTSDIR,"peaks","{peakcaller}","DiffATAC","{method}","all_diff_atacs.tsv"),
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
Rscript "{params.scriptsdir}/aggregate_results_runner.R" \\
    --countsmatrix "{input.counts}" \\
    --diffatacdir "$outdir" \\
    --coldata "{params.sampleinfo}" \\
    --foldchange "{params.fc_cutoff}" \\
    --fdr "{params.fdr_cutoff}" \\
    --indexcols "Geneid" \\
    --excludecols "Chr,Start,End,Strand,Length" \\
    --diffatacdir "$outdir" \\
    --tmpdir "$TMPDIR" \\
    --scriptsdir "{params.scriptsdir}"
"""


#########################################################
