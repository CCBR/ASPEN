#!/bin/bash

callPeaks(){
# inputs
    TAGALIGN=$1
    PREFIX=$2
    RUNCHIPSEEKER=$3
    FILTERPEAKS=$4

# call peaks
    macs2 callpeak \
        -t $TAGALIGN \
        -f BED \
        -n $PREFIX \
        -g $EFFECTIVEGENOMESIZE \
        -p $PVALUE \
        --shift -$SHIFTSIZE \
        --extsize $EXTSIZE \
        --keep-dup all \
        --call-summits \
        --nomodel \
        --SPMR -B \
        --outdir $OUTDIR

# remove duplicate peak calls
    mv ${PREFIX}_peaks.narrowPeak ${PREFIX}_peaks.narrowPeak.tmp
    sort -k9,9gr ${PREFIX}_peaks.narrowPeak.tmp|awk -F"\t" '!NF || !seen[$1":"$2"-"$3]++'|sort -k1,1 -k2,2n > ${PREFIX}_peaks.narrowPeak
    rm -f ${PREFIX}_peaks.narrowPeak.tmp
    mv ${PREFIX}_peaks.narrowPeak ${PREFIX}.narrowPeak

# apply qfilter
    if [ $FILTERPEAKS == "True" ];then
      qvalue=$QFILTER
      unfilteredpeakfile="${PREFIX}.unfiltered.narrowPeak"
      mv ${PREFIX}.narrowPeak $unfilteredpeakfile
      awk -F"\t" -v q=$qvalue '{if ($9>q){print}}' $unfilteredpeakfile > ${PREFIX}.narrowPeak
    fi

# annotate
    if [ "$RUNCHIPSEEKER" == "True" ];then
    for f in ${PREFIX}.unfiltered.narrowPeak ${PREFIX}.narrowPeak;do
        npeaks=$(wc -l $f|awk '{print $1}')
        if [ "$npeaks" -gt "0" ];then
            Rscript ${SCRIPTSFOLDER}/ccbr_annotate_peaks.R -n $f  -a ${f}.annotated -g $GENOME -l ${f}.genelist -f ${f}.annotation_summary
            cut -f1,2 ${f}.annotation_summary > ${f}.annotation_distribution
        else
            touch ${f}.annotated
            touch ${f}.genelist
            touch ${f}.annotation_summary
            touch ${f}.annotation_distribution
        fi
    done
    fi


# save bigwig
# MAY NEED TO BE NORMALIZED FOR GENOME SIZE ... DONT KNOW FOR SURE
# MACS says
#
# MACS will save fragment pileup signal per million reads
#
# Genrich normalization is as per 1x genome coverage... and macs2 normalization is per million reads
#     bedSort ${PREFIX}_treat_pileup.bdg ${PREFIX}_treat_pileup.bdg
# # some coordinates go out of chromosome size in macs2 bam2bw conversion.... using a working around
#     awk -F"\t" -v OFS="\t" '{print $1,"0",$2}' $GENOMEFILE > /dev/shm/${PREFIX}.genome.bed
#     bedtools intersect -a ${PREFIX}_treat_pileup.bdg -b /dev/shm/${PREFIX}.genome.bed > /dev/shm/${PREFIX}.bg
#     mv /dev/shm/${PREFIX}.bg ${PREFIX}_treat_pileup.bdg
#     rm -f /dev/shm/${PREFIX}.genome.bed
# #
#     bedGraphToBigWig ${PREFIX}_treat_pileup.bdg $GENOMEFILE ${PREFIX}.bw
#     rm -f ${PREFIX}_treat_pileup.bdg
#     rm -f ${PREFIX}_control_lambda.bdg
#     mv ${PREFIX}.bw ${OUTDIR}/bigwig/${PREFIX}.bw

# save nicks bam and bed

#   nicksBED=${PREFIX}.tn5nicks.bed
#   nicksBAM=${PREFIX}.tn5nicks.bam
#   zcat $TAGALIGN|awk -F"\t" -v OFS="\t" '{if ($6=="+") {print $1,$2,$2+1} else {print $1,$3,$3+1}}'> $nicksBED
#   bedSort $nicksBED $nicksBED
#   awk -F"\t" -v OFS="\t" '{print $1,$2,$3,$1":"$2"-"$3}' $nicksBED > ${nicksBED%.*}.tmp.bed
#   bedToBam -i ${nicksBED%.*}.tmp.bed -g $GENOMEFILE > $nicksBAM
#   samtools sort -@4 -o ${nicksBAM%.*}.sorted.bam $nicksBAM
#   mv ${nicksBAM%.*}.sorted.bam $nicksBAM
#   rm -f ${nicksBED%.*}.tmp.bed
#   pigz -f -p4 $nicksBED
#   mv ${nicksBED}.gz ${OUTDIR}/tn5nicks/${nicksBED}.gz
#   mv ${nicksBAM} ${OUTDIR}/tn5nicks/${nicksBAM}
#   samtools index ${OUTDIR}/tn5nicks/${nicksBAM}
}

set -e -x -o pipefail
ARGPARSE_DESCRIPTION="""This scripts takes in Tn5-shifted tagAligne files as input and
1. Calls atac-seq peaks using macs2
2. Filters low-quality script using q-value
3. Annotates peaks using ChIPseeker
4. Calls atac-seq peaks for pooled replicates and annotates them
5. Calls consensus peaks for multiple replicates and annotates them
* Currently supports upto 4 replicates
Output files:
* Per replicate:
    ** narrowPeak file
    ** annotated file from ChIPseeker
    ** annotations summary file
    ** annotation distribution file (for pie-charting)
    ** genelist file
    ** sorted tn5nicks BED file (in tn5nicks subfolder)
    ** tn5nicks BAM file (required for downstream DiffBind analysis ... in tn5nicks subfolder)
    ** bigwig files (in bigwig subfolder)
* Pooled narrowPeak file with annotations
* Consensus BED file with annotations
"""
source /opt2/argparse.bash || exit 1
argparse "$@" <<EOF || exit 1
parser.add_argument('--tagalignfiles',required=True, nargs = '+', help = 'space separated list of tagAlignGz files')
parser.add_argument('--outdir',required=True, help= 'outputfolder')

parser.add_argument('--effectivegenomesize',required=True,help="2700000000 for human or 1870000000 for mouse")
parser.add_argument('--genome',required=True,help="genome only hg38/hg19/mm10 are supported by ChIPseeker")
parser.add_argument('--genomefile',required=True,help=".genome file")

parser.add_argument('--extsize',required=False, default=200, help='extsize')
parser.add_argument('--shiftsize',required=False, default=100, help='shiftsize')
parser.add_argument('--pvalue',required=False, default=0.1, help='pvalue cutoff for peak calling')
parser.add_argument('--samplename',required=True, help='samplename,i.e., all replicates belong to this sample')

# only required if filtering
parser.add_argument('--filterpeaks',required=False, default="True", help='filterpeaks by qvalue: True or False')
parser.add_argument('--qfilter',required=False, default=1.301, help='default qfiltering value is 1.301 (-log10 of 0.05) for q=0.05')

parser.add_argument('--scriptsfolder',required=True,  help='folder where the scripts are... probably <path to workflow>/scripts')
parser.add_argument('--runchipseeker',required=True, default="False", help='annotate peaks with chipseeker')
parser.add_argument('--cleanupbdg',required=False, default="True", help='remove unwanted bdg files')
parser.add_argument('--cleanuppooled',required=False, default="True", help='remove unwanted pooled.tagAlign.gz files')
parser.add_argument('--cleanupxls',required=False, default="True", help='remove unwanted xls files')
parser.add_argument('--cleanupsummits',required=False, default="True", help='remove unwanted summits files')
EOF

cd $OUTDIR

CONSENSUSBEDFILE="${SAMPLENAME}.macs2.consensus.bed"
# fraction of replicates that need representation in each peak.. default > 50% of samples
CONSENSUSFILTER=0.5

#ChIPseeker in the container only works for hg19/hg38/mm10... so you cannot annotate other genomes here
genome_is_known=0
if [ "$RUNCHIPSEEKER" == "True" ];then
    if [ "$GENOME" == "hg19" ];then
        genome_is_known=1
    elif [ "$GENOME" == "hg38" ];then
        genome_is_known=1
    elif [ "$GENOME" == "mm10" ];then
        genome_is_known=1
    fi
    if [ "$genome_is_known" == "0" ];then
    RUNCHIPSEEKER="False"
    fi
fi


nreplicates=$(echo $TAGALIGNFILES|wc -w)
TAGALIGN1=$(echo $TAGALIGNFILES|awk '{print $1}')
REP1NAME=`echo $(basename $TAGALIGN1)|awk -F".tag" '{print $1}'`
if [ "$nreplicates" -ge 2 ]; then
    TAGALIGN2=$(echo $TAGALIGNFILES|awk '{print $2}')
    REP2NAME=`echo $(basename $TAGALIGN2)|awk -F".tag" '{print $1}'`
fi
if [ "$nreplicates" -ge 3 ]; then
    TAGALIGN3=$(echo $TAGALIGNFILES|awk '{print $3}')
    REP3NAME=`echo $(basename $TAGALIGN3)|awk -F".tag" '{print $1}'`
fi
if [ "$nreplicates" -ge 4 ]; then
    TAGALIGN4=$(echo $TAGALIGNFILES|awk '{print $4}')
    REP4NAME=`echo $(basename $TAGALIGN4)|awk -F".tag" '{print $1}'`
fi
if [ "$nreplicates" -ge 5 ]; then
    TAGALIGN5=$(echo $TAGALIGNFILES|awk '{print $5}')
    REP5NAME=`echo $(basename $TAGALIGN5)|awk -F".tag" '{print $1}'`
fi
if [ "$nreplicates" -ge 6 ]; then
    TAGALIGN6=$(echo $TAGALIGNFILES|awk '{print $6}')
    REP6NAME=`echo $(basename $TAGALIGN6)|awk -F".tag" '{print $1}'`
fi


# replicate 1 peak calling
callPeaks $TAGALIGN1 ${REP1NAME}.macs2 $RUNCHIPSEEKER $FILTERPEAKS
# replicate 2 peak calling
if [ "$nreplicates" -ge 2 ]; then
callPeaks $TAGALIGN2 ${REP2NAME}.macs2 $RUNCHIPSEEKER $FILTERPEAKS
fi
# replicate 3 peak calling
if [ "$nreplicates" -ge 3 ]; then
callPeaks $TAGALIGN3 ${REP3NAME}.macs2 $RUNCHIPSEEKER $FILTERPEAKS
fi
# replicate 4 peak calling
if [ "$nreplicates" -ge 4 ]; then
callPeaks $TAGALIGN4 ${REP4NAME}.macs2 $RUNCHIPSEEKER $FILTERPEAKS
fi
# replicate 5 peak calling
if [ "$nreplicates" -ge 5 ]; then
callPeaks $TAGALIGN5 ${REP5NAME}.macs2 $RUNCHIPSEEKER $FILTERPEAKS
fi
# replicate 6 peak calling
if [ "$nreplicates" -ge 6 ]; then
callPeaks $TAGALIGN6 ${REP6NAME}.macs2 $RUNCHIPSEEKER $FILTERPEAKS
fi

if [ "$nreplicates" -eq 1 ];then
    for f in `ls ${REP1NAME}.macs2*`;do
        newf=$(echo $f|sed "s/.macs2./.macs2.pooled./g")
        cp $f $newf
    done
    cut -f1-3 ${REP1NAME}.macs2.narrowPeak > $CONSENSUSBEDFILE
fi

if [ "$nreplicates" -eq 2 ];then
pooled="${REP1NAME}_${REP2NAME}.pooled.tagAlign"
zcat $TAGALIGN1 $TAGALIGN2 > ${pooled}
fi

if [ "$nreplicates" -eq 3 ];then
pooled="${REP1NAME}_${REP2NAME}_${REP3NAME}.pooled.tagAlign"
zcat $TAGALIGN1 $TAGALIGN2 $TAGALIGN3 > ${pooled}
fi

if [ "$nreplicates" -eq 4 ];then
pooled="${REP1NAME}_${REP2NAME}_${REP3NAME}_${REP4NAME}.pooled.tagAlign"
zcat $TAGALIGN1 $TAGALIGN2 $TAGALIGN3 $TAGALIGN4 > ${pooled}
fi

if [ "$nreplicates" -eq 5 ];then
pooled="${REP1NAME}_${REP2NAME}_${REP3NAME}_${REP4NAME}_${REP5NAME}.pooled.tagAlign"
zcat $TAGALIGN1 $TAGALIGN2 $TAGALIGN3 $TAGALIGN4 $TAGALIGN5 > ${pooled}
fi

if [ "$nreplicates" -eq 6 ];then
pooled="${REP1NAME}_${REP2NAME}_${REP3NAME}_${REP4NAME}_${REP5NAME}_${REP6NAME}.pooled.tagAlign"
zcat $TAGALIGN1 $TAGALIGN2 $TAGALIGN3 $TAGALIGN4 $TAGALIGN5 $TAGALIGN6 > ${pooled}
fi

# pooled peak calling
if [ "$nreplicates" -ge 2 ];then
bedSort ${pooled} ${pooled}
pigz -f -p4 ${pooled}
callPeaks ${pooled}.gz ${SAMPLENAME}.macs2.pooled $RUNCHIPSEEKER $FILTERPEAKS
fi

# consensus peak calling
if [ "$nreplicates" -eq 2 ];then
python ${SCRIPTSFOLDER}/ccbr_get_consensus_peaks.py --filter $CONSENSUSFILTER --peakfiles ${REP1NAME}.macs2.narrowPeak ${REP2NAME}.macs2.narrowPeak --outbed $CONSENSUSBEDFILE
fi

if [ "$nreplicates" -eq 3 ];then
python ${SCRIPTSFOLDER}/ccbr_get_consensus_peaks.py --filter $CONSENSUSFILTER --peakfiles ${REP1NAME}.macs2.narrowPeak ${REP2NAME}.macs2.narrowPeak ${REP3NAME}.macs2.narrowPeak --outbed $CONSENSUSBEDFILE
fi

if [ "$nreplicates" -eq 4 ];then
python ${SCRIPTSFOLDER}/ccbr_get_consensus_peaks.py --filter $CONSENSUSFILTER --peakfiles ${REP1NAME}.macs2.narrowPeak ${REP2NAME}.macs2.narrowPeak ${REP3NAME}.macs2.narrowPeak ${REP4NAME}.macs2.narrowPeak --outbed $CONSENSUSBEDFILE
fi

if [ "$nreplicates" -eq 5 ];then
python ${SCRIPTSFOLDER}/ccbr_get_consensus_peaks.py --filter $CONSENSUSFILTER --peakfiles ${REP1NAME}.macs2.narrowPeak ${REP2NAME}.macs2.narrowPeak ${REP3NAME}.macs2.narrowPeak ${REP4NAME}.macs2.narrowPeak ${REP5NAME}.macs2.narrowPeak --outbed $CONSENSUSBEDFILE
fi

if [ "$nreplicates" -eq 6 ];then
python ${SCRIPTSFOLDER}/ccbr_get_consensus_peaks.py --filter $CONSENSUSFILTER --peakfiles ${REP1NAME}.macs2.narrowPeak ${REP2NAME}.macs2.narrowPeak ${REP3NAME}.macs2.narrowPeak ${REP4NAME}.macs2.narrowPeak ${REP5NAME}.macs2.narrowPeak ${REP6NAME}.macs2.narrowPeak --outbed $CONSENSUSBEDFILE
fi

if [ "$RUNCHIPSEEKER" == "True" ];then
    f="$CONSENSUSBEDFILE"
    npeaks_consensus=$(wc -l $f|awk '{print $1}')
    if [ "$npeaks_consensus" -gt "0" ];then
        Rscript ${SCRIPTSFOLDER}/ccbr_annotate_bed.R -b $f -a ${f}.annotated -g $GENOME -l ${f}.genelist -f ${f}.annotation_summary
        cut -f1,2 ${f}.annotation_summary > ${f}.annotation_distribution
    else
        touch ${f}.annotated
        touch ${f}.genelist
        touch ${f}.annotation_summary
        touch ${f}.annotation_distribution
    fi
fi

# cleanup
if [ "$CLEANUPBDG" == "True" ];then
    rm -f *.bdg
fi
if [ "$CLEANUPXLS" == "True" ];then
    rm -f *.xls
fi
if [ "$CLEANUPSUMMITS" == "True" ];then
    rm -f *macs2_summits.bed
fi
if [ "$CLEANUPPOOLED" == "True" ];then
    rm -f ${pooled}.gz
fi
