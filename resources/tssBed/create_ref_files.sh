#!/bin/bash
python3 create_per_gene_TSS_bins.py --gtf /data/CCBR_Pipeliner/db/PipeDB/Indices/GTFs/hg19/gencode.v42lift37.basic.annotation.gtf --out hg19_v42_tssbeds.tar.gz
python3 create_per_gene_TSS_bins.py --gtf /data/CCBR_Pipeliner/db/PipeDB/Indices/GTFs/hg38/gencode.v42.primary_assembly.annotation.gtf --out hg38_v42_tssbed.tar.gz
python3 create_per_gene_TSS_bins.py --gtf /data/CCBR_Pipeliner/db/PipeDB/Indices/GTFs/mm10/gencode.vM25.annotation.gtf --out mm10_M25_tssbeds.tar.gz
python3 create_per_gene_TSS_bins.py --gtf /data/CCBR_Pipeliner/db/PipeDB/Indices/Mmul_8.0.1_basic/genes.gtf --out mmul_tssbeds.tar.gz
python3 create_per_gene_TSS_bins.py --gtf /data/CCBR_Pipeliner/db/PipeDB/Indices/mmul10/genes.gtf --out mmul10_v108_tssbeds.tar.gz
python3 create_per_gene_TSS_bins.py --gtf /data/CCBR_Pipeliner/db/PipeDB/Indices/bosTau9/genes.gtf --out  bosTau9_v108_tssbeds.tar.gz
