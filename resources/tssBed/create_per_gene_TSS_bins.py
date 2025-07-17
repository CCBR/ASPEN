#!/usr/bin/env python3
import pysam, sys, os, numpy, subprocess
import argparse
import tempfile, shutil
import gzip


def _get_gene_metadata(l, what):
    for i, j in enumerate(l):
        if j == what:
            return l[i + 1].replace(";", "").replace('"', "")
    else:
        return ""


def get_gene_metadata(l):
    metadata_str_list = l[8].strip().split()
    geneID = _get_gene_metadata(metadata_str_list, "gene_id")
    geneName = _get_gene_metadata(metadata_str_list, "gene_name")
    geneType = ""
    geneType = _get_gene_metadata(metadata_str_list, "gene_type")
    if geneType == "":
        geneType = _get_gene_metadata(metadata_str_list, "gene_biotype")
    chrom = l[0]
    strand = l[6]
    start = int(l[3]) - 1
    end = int(l[4]) - 1
    if strand == "-":
        tmp = start
        start = end
        end = tmp
    score = "."
    return geneID, geneName, geneType, chrom, start, strand


parser = argparse.ArgumentParser(
    description="Create windows around TSS for each gene in GTF file"
)
# parser.add_argument('--gtf',required=True,help='GTF',type=argparse.FileType('r'))
parser.add_argument("--gtf", required=True, help="GTF file path")
parser.add_argument("--out", required=True, help="Output tar.gz file")
args = parser.parse_args()

gtfFile = open(args.gtf, "r")
genes_dict = dict()
gtfLines = gtfFile.readlines()
gtfFile.close()

for l in gtfLines:
    l = l.strip()
    if not l.startswith("#"):
        l = l.split("\t")
        if l[2] == "gene":
            geneID, geneName, geneType, chrom, start, strand = get_gene_metadata(l)
            if geneName == "":
                geneName = geneID
            if geneType == "protein_coding":
                genes_dict[geneID] = dict()
                genes_dict[geneID]["geneName"] = geneName
                genes_dict[geneID]["start"] = start
                genes_dict[geneID]["strand"] = strand
                genes_dict[geneID]["chrom"] = chrom


tmp_folder = tempfile.mkdtemp()

for geneID, metaData in genes_dict.items():
    outBED = os.path.join(str(tmp_folder), geneID + ".bed")
    outBuffer = open(outBED, "w")
    if metaData["strand"] == "-":
        r = range(400, 0, -1)
    else:
        r = range(1, 401, 1)
    newstart = metaData["start"] - 2000
    for i, j in enumerate(r):
        s = newstart + i * 10
        e = s + 10
        regionName = geneID + "|" + metaData["geneName"] + "|" + str(j)
        outList = [
            metaData["chrom"],
            str(s),
            str(e),
            regionName,
            ".",
            metaData["strand"],
        ]
        outStr = "\t".join(outList)
        outBuffer.write(outStr + "\n")
    outBuffer.close()

wd = os.getcwd()
os.chdir(tmp_folder)
cmd = "tar czvf " + args.out + " *.bed"
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
shutil.move(os.path.join(tmp_folder, args.out), os.path.join(wd, args.out))
shutil.rmtree(tmp_folder)
print(tmp_folder)
# chrX	HAVANA	gene	100627109	100639991	.	-	.	gene_id "ENSG00000000003.14"; gene_type "protein_coding"; gene_name "TSPAN6"; level 2; havana_gene "OTTHUMG00000022002.1";
# chrX	100625108	100625118	ENSG00000000003.14|TSPAN6|400	.	-
