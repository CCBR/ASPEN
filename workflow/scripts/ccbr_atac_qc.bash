#!/bin/bash

function delete_file_if_present() {
	filename=$1
	if [ -f "$filename" ];then
	rm -f $filename
	fi
}

function randomtext() {
chars=abcd1234ABCD
for i in {1..8} ; do
	    echo -n "${chars:RANDOM%${#chars}:1}"
    done
    echo
}

set -e -x -o pipefail

ARGPARSE_DESCRIPTION="Create all files required to generate a MultiQC report"
source /opt2/argparse.bash || \
source <(curl -s https://raw.githubusercontent.com/CCBR/Tools/master/scripts/argparse.bash) || \
exit 1
argparse "$@" <<EOF || exit 1
parser.add_argument('--qcfolder',required=True, help='path to the qc folder')
parser.add_argument('--multiqcconfig',required=False, help='path to the multiqc yaml file')
parser.add_argument('--multiqcextraparams',required=False, help='extra multiqc parameters')
EOF

SCRIPTSDIR=$(dirname $0)
SCRIPTSDIR=$(readlink -f $SCRIPTSDIR)

cd $QCFOLDER

#####
#make_nreads_table
#OUTPUT:Nreads_mqc.csv
#####
delete_file_if_present Nreads_mqc.csv

count=0
for f in `find . -name "*.nreads.txt"`;do
count=$((count+1))
if [ "$count" -eq "1" ]; then
echo -ne "replicateName\tTrimmed\tMitoRibo\tUnMapped\tDuplicates\tForPeakCalling\n" > Nreads_mqc.csv.header
fi
data=$(grep -v "^#" $f|sh ${SCRIPTSDIR}/_transpose.sh|head -n1|awk -F"\t" '{printf("%d\t%d\t%d\t%d\t%d\n",$1-$2,$2-$3,$3-$4,$4-$5,$5)}')
samplename=$(basename $f|awk -F".nreads" '{print $1}')
echo -ne "$samplename\t$data\n" >> Nreads_mqc.csv
done
cat Nreads_mqc.csv.header > Nreads_mqc.csv.tmp
rm -f Nreads_mqc.csv.header
sort Nreads_mqc.csv >> Nreads_mqc.csv.tmp
mv Nreads_mqc.csv.tmp Nreads_mqc.csv

#####
#make_nrf_table.sh
#OUTPUT:NRF_stats.tsv
#####
count=0
delete_file_if_present NRF_stats.tsv
for f in `find . -name "*.nrf"`;do
count=$((count+1))
if [ "$count" -eq "1" ]; then
head=$(cat $f|sed "s/:/\t/g"|sh ${SCRIPTSDIR}/_transpose.sh|head -n1)
echo -ne "replicateName\t$head\n" > NRF_stats.txt.header
fi
data=$(cat $f|sed "s/:/\t/g"|sh ${SCRIPTSDIR}/_transpose.sh|tail -n1)
samplename=$(basename $f|awk -F".nrf" '{print $1}')
echo -ne "$samplename\t$data\n" >> NRF_stats.txt
done
cat NRF_stats.txt.header > NRF_stats.txt.tmp
rm -f NRF_stats.txt.header
sort NRF_stats.txt >> NRF_stats.txt.tmp
mv NRF_stats.txt.tmp NRF_stats.tsv

#####
#annotated2peakwidthdensity.sh
#OUTPUT:.peak_width_density files in peak_annotation subfolder
#####
for f in `find . -name "*consensus*annotated"`;do
echo $f
python ${SCRIPTSDIR}/_qc_annotated2peakwidthdensity.py $f > ${f}.peak_width_density
gzip -n $f
done


#####
#make_tss_scatter_table.sh
#OUTPUT:data.tss_knicking_sites.txt
#####
delete_file_if_present data.tss_nicking_sites.txt
for f in `find . -name "*.tss.txt"`;do
samplename=$(basename $f|awk -F".tss" '{print $1}')
enrich=$(grep "enrichment" $f|awk '{print $NF}')
nsites=$(grep "20 or more Tn5" $f|awk '{print $NF}')
echo -ne "$samplename\t$nsites\t$enrich\n" >> data.tss_nicking_sites.txt
done

#####
#make_frip_table.sh
#OUTPUT:FRiP_stats.txt
#####
delete_file_if_present FRiP_stats.tsv
RANDOMTXT=$(randomtext)
find . -name "*.frip" -exec cat {} \; > $RANDOMTXT
bash ${SCRIPTSDIR}/_qc_create_frip_stats_table.bash $RANDOMTXT > FRiP_stats.tsv
rm -f $RANDOMTXT


#####
#make_fld_table.sh
#OUTPUT:FLD_stats.txt
#####
count=0
delete_file_if_present FLD_stats_peaks.tsv
delete_file_if_present FLD_stats_fractions_ratios.tsv
for f in `find . -name "*fld.txt"`;do
count=$((count+1))
if [ "$count" -eq "1" ]; then
head1=$(grep "^#" $f|grep -v PEAKS|sed "s/# //g"|sed "s/://g"|grep "_PRESENT"|sh ${SCRIPTSDIR}/_transpose.sh|head -n1)
head2=$(grep "^#" $f|grep -v PEAKS|sed "s/# //g"|sed "s/://g"|grep -v "_PRESENT"|sh ${SCRIPTSDIR}/_transpose.sh|head -n1)
echo -ne "replicateName\t$head1\n" > FLD_stats_peaks.txt.header
echo -ne "replicateName\t$head2\n" > FLD_stats_fractions_ratios.txt.header
fi
data1=$(grep "^#" $f|grep -v PEAKS|sed "s/# //g"|sed "s/://g"|grep "_PRESENT"|sh ${SCRIPTSDIR}/_transpose.sh|tail -n1)
data2=$(grep "^#" $f|grep -v PEAKS|sed "s/# //g"|sed "s/://g"|grep -v "_PRESENT"|sh ${SCRIPTSDIR}/_transpose.sh|tail -n1)
samplename=$(basename $f|awk -F".fld" '{print $1}')
echo -ne "$samplename\t$data1\n" >> FLD_stats_peaks.tsv
echo -ne "$samplename\t$data2\n" >> FLD_stats_fractions_ratios.tsv
done
sort FLD_stats_peaks.tsv > FLD_stats_peaks.tsv.sorted
sort FLD_stats_fractions_ratios.tsv >> FLD_stats_fractions_ratios.tsv.sorted
cat FLD_stats_peaks.txt.header FLD_stats_peaks.tsv.sorted > FLD_stats_peaks.tsv
cat FLD_stats_fractions_ratios.txt.header FLD_stats_fractions_ratios.tsv.sorted > FLD_stats_fractions_ratios.tsv
rm -f FLD_stats_*.header FLD_stats_*.sorted

#####
#make_macs2_annotation_table.sh
#OUTPUT:MACS2_Peak_Annotations_mqc.csv
#####
count=0
delete_file_if_present MACS2_Peak_Annotations_mqc.csv
for f in `find . -name "*.macs2.narrowPeak.annotation_distribution"` `find . -name "*.macs2.consensus.bed.annotation_distribution"`;do
count=$((count+1))
if [ "$count" -eq "1" ]; then
head=$(grep -v "^#" $f|sh ${SCRIPTSDIR}/_transpose.sh|head -n1)
echo -ne "replicateName\t$head\n" > MACS2_Peak_Annotations_mqc.csv.header
fi
data=$(grep -v "^#" $f|sh ${SCRIPTSDIR}/_transpose.sh|tail -n1)
samplename=$(basename $f|awk -F".macs2" '{print $1}')
echo -ne "$samplename\t$data\n" | sort >> MACS2_Peak_Annotations_mqc.csv
done
if [ -f MACS2_Peak_Annotations_mqc.csv.header ];then # MACS2_Peak_Annotations_mqc.csv.header may not get created if *.macs2.narrowPeak.annotation_distribution files dont exist ... ie if ChiPSeeker was not run ... like mmul10 case
cat MACS2_Peak_Annotations_mqc.csv.header > MACS2_Peak_Annotations_mqc.csv.tmp
rm -f MACS2_Peak_Annotations_mqc.csv.header
sort MACS2_Peak_Annotations_mqc.csv >> MACS2_Peak_Annotations_mqc.csv.tmp
mv MACS2_Peak_Annotations_mqc.csv.tmp MACS2_Peak_Annotations_mqc.csv
fi


#####
#make_genrich_annotation_table.sh
#OUTPUT:Genrich_Peak_Annotations_mqc.csv
#####
count=0
delete_file_if_present Genrich_Peak_Annotations_mqc.csv
for f in `find . -name "*.genrich.narrowPeak.annotation_distribution"` `find . -name "*.genrich.consensus.bed.annotation_distribution"`;do
count=$((count+1))
if [ "$count" -eq "1" ]; then
head=$(grep -v "^#" $f|sh ${SCRIPTSDIR}/_transpose.sh|head -n1)
echo -ne "replicateName\t$head\n" > Genrich_Peak_Annotations_mqc.csv.header
fi
data=$(grep -v "^#" $f|sh ${SCRIPTSDIR}/_transpose.sh|tail -n1)
samplename=$(basename $f|awk -F".genrich" '{print $1}')
echo -ne "$samplename\t$data\n" | sort >> Genrich_Peak_Annotations_mqc.csv
done
if [ -f Genrich_Peak_Annotations_mqc.csv.header ];then
cat Genrich_Peak_Annotations_mqc.csv.header > Genrich_Peak_Annotations_mqc.csv.tmp
rm -f Genrich_Peak_Annotations_mqc.csv.header
sort Genrich_Peak_Annotations_mqc.csv >> Genrich_Peak_Annotations_mqc.csv.tmp
mv Genrich_Peak_Annotations_mqc.csv.tmp Genrich_Peak_Annotations_mqc.csv
fi

#####
#Run multiqc
#OUTPUT:multi_qc_report.html
#####
multiqccmd="multiqc -f --interactive -v ."
if [ $MULTIQCCONFIG ];then
	multiqccmd="$multiqccmd -c $MULTIQCCONFIG"
fi
if [ $MULTIQCEXTRAPARAMS ];then
	multiqccmd="$multiqccmd $MULTIQCEXTRAPARAMS"
fi
eval $multiqccmd
# multiqc -c ${MULTIQCCONFIG} -f --interactive -v .

#####
#Create a QC stats table
#OUTPUT: QCStats.txt
#####
python $SCRIPTSDIR/_qc_make_qcstats_table.py
