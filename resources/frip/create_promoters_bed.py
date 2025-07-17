#!/usr/bin/env python3
import pysam, sys, os, numpy, subprocess
import argparse
import tempfile, shutil


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
parser.add_argument("--out", required=True, help="Output BED file")
args = parser.parse_args()

gtfFile = open(args.gtf, "r")
genes_dict = dict()
gtfLines = gtfFile.readlines()
gtfFile.close()

# chroms=['chr1', 'chr2', 'chr3', 'chr4', 'chr5', 'chr6', 'chr7', 'chr8', 'chr9', 'chr10',
# 		'chr11', 'chr12', 'chr13', 'chr14', 'chr15', 'chr16', 'chr17', 'chr18', 'chr19', 'chr20',
# 		'chr21', 'chr22', 'chrX', 'chrY', 'chrM', 'chrMT']

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


# chr1    67091   69291   chr1-67091:69291|ENSG00000186092.4|OR4F5        0       +
outBED = open(args.out, "w")
for geneID, metaData in genes_dict.items():
    if metaData["strand"] == "-":
        s = metaData["start"] - 200
        e = metaData["start"] + 2000
    else:
        s = metaData["start"] - 2000
        e = metaData["start"] + 200
    if s <= 0:
        continue
    regionName = (
        metaData["chrom"]
        + ":"
        + str(s)
        + "-"
        + str(e)
        + "|"
        + geneID
        + "|"
        + metaData["geneName"]
    )
    outList = [
        metaData["chrom"],
        str(s),
        str(e),
        regionName,
        str(0),
        metaData["strand"],
    ]
    outStr = "\t".join(outList)
    outBED.write(outStr + "\n")
outBED.close()
