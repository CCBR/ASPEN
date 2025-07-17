#!/bin/bash
####################################################################
#functions
####################################################################
function randomtext() {
chars=abcd1234ABCD
for i in {1..8} ; do
	    echo -n "${chars:RANDOM%${#chars}:1}"
    done
    echo
}
function create_part1() {
replicateName=$1
echo -ne "replicateName\n$replicateName\n" > ${replicateName}.part1
}

function create_part2() {
replicateName=$1
cat $FRIPFILE|grep "^${replicateName}\b"|cut -f2,3|bash $SCRIPTSDIR/_transpose.sh > ${replicateName}.part2
}


####################################################################
#scripts starts here
####################################################################
SCRIPTSDIR=$(dirname $0)
SCRIPTSDIR=$(readlink -f $SCRIPTSDIR)

RANDOMTXT=$(randomtext)

FRIPFILE=$1
replicates=$(cut -f1 $FRIPFILE|sort|uniq)

for r in $replicates;do
	create_part1 $r
	create_part2 $r
	paste ${replicateName}.part1 ${replicateName}.part2
	rm -f ${replicateName}.part*
done > $RANDOMTXT

grep -m1 "replicateName" $RANDOMTXT > ${RANDOMTXT}.header
grep -v "replicateName" $RANDOMTXT | sort > ${RANDOMTXT}.body

cat ${RANDOMTXT}.header ${RANDOMTXT}.body

rm -f ${RANDOMTXT}*
