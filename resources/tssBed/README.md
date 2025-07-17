# Promoter regions

### BIOWULF location for GTFs: /data/CCBR_Pipeliner/db/PipeDB/Indices/GTFs/

### script: ./create_per_gene_TSS_bins.py creates the required tssbed tarball. It:

- reads "gene" lines from the GTF
- is strand aware
- extracts chrom, start, geneid, geneName from the "gene" line for gene_type == "protein_coding" only
- creates 400 bins around the TSS
  - start if on + strand
  - end if on - strand
- each bin is 10 bp width so total -2k through +2k rgeion is covered in the 400 bins

```bash
 % ./create_per_gene_TSS_bins.py
usage: create_per_gene_TSS_bins.py [-h] --gtf GTF --out OUT
create_per_gene_TSS_bins.py: error: the following arguments are required: --gtf, --out
```

> NOTE: gencode version 42 is used for hg38 and hg19, gencode version M25 is used for mm10
