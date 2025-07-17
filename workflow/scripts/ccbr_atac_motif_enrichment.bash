#!/bin/bash

set -e -x -o pipefail

ARGPARSE_DESCRIPTION="use homer(findMotifsGenome.pl) and meme(ame) to perform motif enrichment analysis using HOCOMOCO_v11 motifs"      # this is optional
source /opt2/argparse.bash || exit 1
argparse "$@" <<EOF || exit 1
parser.add_argument('--narrowpeak',required=True, help='narrowPeak or bed input file')
parser.add_argument('--genomefa',required=True, help='genomefasta')
parser.add_argument('--homermotif',required=True, help='hocomoco motifs file for homer (.motif)')
parser.add_argument('--mememotif',required=True, help='hocomoco motifs file for meme (tar.gz)')
parser.add_argument('--ntop',required=False, default=50000, type=int, help='use the top x peaks ... default 50k (only for narrowPeak files)')
parser.add_argument('--threads',required=False, default=2, type=int, help='number of threads')
parser.add_argument('--outdir',required=True, help='output dir')
parser.add_argument('--tmpdir',required=False, default="/dev/shm", help='tmp dir')
EOF

ncpus=$THREADS
samplename=$(echo $NARROWPEAK|awk -F"/" '{print $NF}'|awk -F"." '{print $1}')
filetype=$(echo $NARROWPEAK|awk -F"/" '{print $NF}'|awk -F"." '{print $NF}')
genomefa=$GENOMEFA
outdirbasename=$(basename $OUTDIR)

cd $TMPDIR
mkdir -p $outdirbasename

homermotif=$HOMERMOTIF
mememotiftar=$MEMEMOTIF

cp $homermotif .
cp $mememotiftar .
tar xzvf $(basename $mememotiftar)

if [ "$filetype" == "narrowPeak" ];then
	sort -k9,9gr $NARROWPEAK|cut -f1-3 |awk -v n=$NTOP '{if (NR<=n) {print}}' > ${samplename}.input.bed
else
	cut -f1-3 $NARROWPEAK > ${samplename}.input.bed
fi
bedSort ${samplename}.input.bed ${samplename}.input.bed

findMotifsGenome.pl ${samplename}.input.bed $genomefa $outdirbasename \
-nomotif \
-size given \
-mknown $(basename $homermotif) \
-N $(wc -l ${samplename}.input.bed|awk '{print $1*4}') \
-h \
-p $ncpus \
-dumpFasta \
-cpg \
-maxN 0.1 \
-len 10 \
-preparsedDir preparsed

# remove -nomotif from the above command if you want to look for de novo motifs as well..... this will take a long time.... as it is a serial homer2 job

targetfa="${outdirbasename}/target.fa"
backgroundfa="${outdirbasename}/background.fa"

ls *.meme |sort > memes
while read a;do echo "ame --o ${a}_ame_out --noseq --control $backgroundfa --seed 12345 --verbose 1 $targetfa $a";done < memes > do_memes
parallel -j $ncpus < do_memes
while read a;do cat ${a}_ame_out/ame.tsv;done < memes |grep "^rank"|sort|uniq > ame_results.txt
while read a;do cat ${a}_ame_out/ame.tsv;done < memes |grep -v "^#"|grep -v "^$"|grep -v "^rank" |sort -k6,6g|awk -F"\t" '{printf("%d\t%s\n",NR,$_)}'|cut -f1,3- >> ame_results.txt
if [ "$(grep CTCF_ ame_results.txt|wc -l)" -ne "0" ]; then
	ctcf_enrich=$(grep -m1 CTCF_ ame_results.txt |awk -F"\t" '{print $(NF-2)/$NF}')
else
	ctcf_enrich="NA"
fi
echo -ne "# CTCF_enrichment = $ctcf_enrich\n" >> ame_results.txt

mv ame_results.txt ${outdirbasename}
rsync -az --progress --verbose ${outdirbasename}/ $OUTDIR/
rm -rf *.*
