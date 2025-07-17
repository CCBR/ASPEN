## Creation of test dataset

Using the **D4_Meso_iCre_Dox** and **iCre_D0** samples from the ccbr872 mouse dataset:

- Select 2 replicates for each group .. total samples = 4
- extract readids from the _chr19:10000000-20000000_ region using:

```
% samtools view /data/CCBR/projects/ccbr872/atacseq/test/bam/iCre_D0_1.dedup.bam chr19:10000000-20000000|awk -F"\t" '{print $1}' |sort|uniq > iCre_D0_1.chr19.readids &
% samtools view /data/CCBR/projects/ccbr872/atacseq/test/bam/iCre_D0_2.dedup.bam chr19:10000000-20000000|awk -F"\t" '{print $1}' |sort|uniq > iCre_D0_2.chr19.readids &
% samtools view /data/CCBR/projects/ccbr872/atacseq/test/bam/D4_Meso_iCre_Dox_1.dedup.bam chr19:10000000-20000000|awk -F"\t" '{print $1}' |sort|uniq > D4_Meso_iCre_Dox_1.chr19.readids &
% samtools view /data/CCBR/projects/ccbr872/atacseq/test/bam/D4_Meso_iCre_Dox_2.dedup.bam chr19:10000000-20000000|awk -F"\t" '{print $1}' |sort|uniq > D4_Meso_iCre_Dox_2.chr19.readids &
```

- create subsampled fastq files using these readids:

```
% cd /data/CCBR/rawdata/ccbr872/ccbr872_atacseq/fastq
% python /data/kopardevn/GitRepos/Tools/scripts/filter_fastq_by_readids_highmem_pe.py --infq iCre_D0_1.R1.fastq.gz --infq2 iCre_D0_1.R2.fastq.gz --outfq iCre_D0_1.subset.R1.fastq.gz --outfq2 iCre_D0_1.subset.R2.fastq.gz --readids iCre_D0_1.chr19.readids
% python /data/kopardevn/GitRepos/Tools/scripts/filter_fastq_by_readids_highmem_pe.py --infq iCre_D0_2.R1.fastq.gz --infq2 iCre_D0_2.R2.fastq.gz --outfq iCre_D0_2.subset.R1.fastq.gz --outfq2 iCre_D0_2.subset.R2.fastq.gz --readids iCre_D0_2.chr19.readids
% python /data/kopardevn/GitRepos/Tools/scripts/filter_fastq_by_readids_highmem_pe.py --infq D4_Meso_iCre_Dox_1.R1.fastq.gz --infq2 D4_Meso_iCre_Dox_1.R2.fastq.gz --outfq D4_Meso_iCre_Dox_1.subset.R1.fastq.gz --outfq2 D4_Meso_iCre_Dox_1.subset.R2.fastq.gz --readids D4_Meso_iCre_Dox_1.chr19.readids
% python /data/kopardevn/GitRepos/Tools/scripts/filter_fastq_by_readids_highmem_pe.py --infq D4_Meso_iCre_Dox_2.R1.fastq.gz --infq2 D4_Meso_iCre_Dox_2.R2.fastq.gz --outfq D4_Meso_iCre_Dox_2.subset.R1.fastq.gz --outfq2 D4_Meso_iCre_Dox_2.subset.R2.fastq.gz --readids D4_Meso_iCre_Dox_2.chr19.readids
```

Now, the **samples.tsv** will look something like this:

```
sampleName	path_to_R1_fastq	path_to_R2_fastq
D4_Meso_iCre_Dox_1	/data/CCBR/rawdata/ccbr872/ccbr872_atacseq/fastq/D4_Meso_iCre_Dox_1.subset.R1.fastq.paired.fq.gz	/data/CCBR/rawdata/ccbr872/ccbr872_atacseq/fastq/D4_Meso_iCre_Dox_1.subset.R2.fastq.pai
red.fq.gz
D4_Meso_iCre_Dox_2	/data/CCBR/rawdata/ccbr872/ccbr872_atacseq/fastq/D4_Meso_iCre_Dox_2.subset.R1.fastq.paired.fq.gz	/data/CCBR/rawdata/ccbr872/ccbr872_atacseq/fastq/D4_Meso_iCre_Dox_2.subset.R2.fastq.pai
red.fq.gz
iCre_D0_1	/data/CCBR/rawdata/ccbr872/ccbr872_atacseq/fastq/iCre_D0_1.subset.R1.fastq.paired.fq.gz	/data/CCBR/rawdata/ccbr872/ccbr872_atacseq/fastq/iCre_D0_1.subset.R2.fastq.paired.fq.gz
iCre_D0_2	/data/CCBR/rawdata/ccbr872/ccbr872_atacseq/fastq/iCre_D0_2.subset.R1.fastq.paired.fq.gz	/data/CCBR/rawdata/ccbr872/ccbr872_atacseq/fastq/iCre_D0_2.subset.R2.fastq.paired.fq.gz
```
