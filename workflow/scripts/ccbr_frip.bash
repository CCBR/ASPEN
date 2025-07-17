#!/bin/bash

set -e -x -o pipefail
ARGPARSE_DESCRIPTION="fraction of reads in peaks (and DHS/Enhancers/Promoters [if genome is provided])"
source /opt2/argparse.bash || \
source <(curl -s https://raw.githubusercontent.com/CCBR/Tools/master/scripts/argparse.bash) || \
exit 1
argparse "$@" <<EOF || exit 1
parser.add_argument('--narrowpeak',required=True, help='input narrowPeak or bed file')
parser.add_argument('--peakcaller',required=False, default="", help='peakcaller either Genrich or MACS2')
parser.add_argument('--dedupbam',required=True, help='input deduplicated bam file')
parser.add_argument('--samplename',required=True, help='sample name')
parser.add_argument('--dhsbed',required=False, help='known DHS sites')
parser.add_argument('--promoterbed',required=False, help='known Promoter sites')
parser.add_argument('--enhancerbed',required=False, help='known Enhancer sites')
EOF

set -e -x -o pipefail
nreads=$(samtools view -c $DEDUPBAM)

frip_reads=$(bedtools intersect -u -a $DEDUPBAM -b $NARROWPEAK|samtools view -c)
frip=$(echo "scale=3;$frip_reads/$nreads"|bc)
echo -ne "$SAMPLENAME\tFRiP\t${PEAKCALLER}\t$frip\n"

if [ "$PEAKCALLER" == "Genrich" ];then

if [ $DHSBED ];then
if [ "$DHSBED" != "" ];then
fridhs_reads=$(bedtools intersect -u -a $DEDUPBAM -b $DHSBED|samtools view -c)
fridhs=$(echo "scale=3;$fridhs_reads/$nreads"|bc)
echo -ne "$SAMPLENAME\tFRiDHS\t$fridhs\n"
fi
fi

if [ $PROMOTERBED ];then
if [ "$PROMOTERBED" != "" ];then
fripro_reads=$(bedtools intersect -u -a $DEDUPBAM -b $PROMOTERBED|samtools view -c)
fripro=$(echo "scale=3;$fripro_reads/$nreads"|bc)
echo -ne "$SAMPLENAME\tFRiPro\t$fripro\n"
fi
fi

if [ $ENHANCERBED ];then
if [ "$ENHANCEDBED" != "" ];then
frienh_reads=$(bedtools intersect -u -a $DEDUPBAM -b $ENHANCEDBED|samtools view -c)
frienh=$(echo "scale=3;$frienh_reads/$nreads"|bc)
echo -ne "$SAMPLENAME\tFRiEnh\t$frienh\n"
fi
fi

fi
