#!/bin/bash
# . /opt2/conda/etc/profile.d/conda.sh
# conda activate python3

set -e -x -o pipefail
ARGPARSE_DESCRIPTION="calculate TSS score from tagAlign file"
source /opt2/argparse.bash || \

source <(curl -s https://raw.githubusercontent.com/CCBR/Tools/master/scripts/argparse.bash) || \
exit 1
argparse "$@" <<EOF || exit 1
parser.add_argument('--tagaligngz',required=True, help='tagalign.gz file')
parser.add_argument('--genome',required=True, help='genome file')
parser.add_argument('--tsstxt',required=True, help='output TSS file')
parser.add_argument('--ncpus',required=False, default=2, help='Number of CPUs')
parser.add_argument('--tsstargz',required=True, help='tssbed tar gz')

EOF

set -e -x -o pipefail

SCRIPTSDIR=$(dirname $0)
SCRIPTSDIR=$(readlink -f $SCRIPTSDIR)
# create Tn5 nicks file
nicksbed=$(echo $TAGALIGNGZ|sed "s/.tagAlign.gz/.tn5nicks.bed/g")
zcat $TAGALIGNGZ |awk -F"\t" -v OFS="\t" '{if ($6=="+") {print $1,$2,$2+1} else {print $1,$3,$3+1}}' > $nicksbed

# untar tss bed and create do file for gnu parallel
cp $TSSTARGZ .
tar xzvf $(basename $TSSTARGZ)
tar tzf $TSSTARGZ > beds.lst
while read f;do
# for f in `ls *.bed|grep -v tn5nicks`;do
echo "bedmap --echo --count $f $nicksbed|awk -F\"\t\" '{if (\$6!=\"+|0\" && \$6!=\"-|0\"){print \$4,\$6}}'|sed \"s/ /|/g\"|awk -F\"|\" -v OFS=\"\t\" '{print \$3,\$5}' > ${f}.counts"
done < beds.lst > do_bedmap
head do_bedmap

# run bedmap, get counts and calculate density from all counts
# filter out TSS regions with <=20 nicks
parallel -j $NCPUS < do_bedmap
while read a;do
f="${a}.counts"
# for f in $(ls *bed.counts);do
	c=$(awk -F"\t" '{sum=sum+$2}END{print sum}' $f)
	if [ "$c" -gt "20" ];then
		echo $f
	fi
done < beds.lst > countfiles
ntss=$(wc -l countfiles|awk '{print $1}')
if [ "$ntss" -gt "0" ]; then
while read a; do cat $a;done < countfiles | awk -F"\t" -v OFS="\t" '{if (NF==2){s[$1]+=$2}}END{for (var in s){print var,s[var]}}'|sort -k1,1n|awk -F"\t" -v OFS="\t" '{if ($2!=0){print $1,$2}}'|python ${SCRIPTSDIR}/_ccbr_counts2density.py - > $TSSTXT
else
	echo -ne "# TSS enrichment: 0.0000\n" > $TSSTXT
fi
echo "# TSS with 20 or more Tn5 nicking sites: $ntss" >> $TSSTXT


# conda deactivate
