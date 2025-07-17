### Limitations of ASPEN

- **Paired-End data required**: ASPEN necessitates paired-end sequencing libraries, as its current design does not support single-end data. Future updates aim to incorporate single-end data compatibility.

- **Infrastructure limit**: Designed primarily for the [BIOWULF](https://hpc.nih.gov/) High-Performance Computing (HPC) system at the National Institutes of Health (NIH), ASPEN's configuration relies on resources specified in the config.yaml file, which are tailored to the BIOWULF file system. Adapting ASPEN for use on other HPC platforms may require adjustments, such as replicating or generating local reference data, modifying code, and accommodating different job schedulers. Plans are underway to deploy ASPEN on the Frederick Research Computing Environment (FRCE) cluster in Frederick.

- **Footprinting analysis**: While ASPEN does not perform footprinting analysis, it is compatible with the [CCBR-TOBIAS](https://github.com/CCBR/CCBR_tobias) pipeline, a separate tool designed for this purpose. TOBIAS (Transcription factor Occupancy prediction By Investigation of ATAC-seq Signal) analyzes ATAC-seq data to predict transcription factor occupancy but generates a substantial number of small files. ASPEN's output can serve as direct input for the CCBR_TOBIAS pipeline, facilitating integrated analyses.

- **Genomes supported**: Genomes supported is limited to:

| Genome Assembly | Organism        | Scientific Name  |
| --------------- | --------------- | ---------------- |
| hg38            | Human           | _Homo sapiens_   |
| hg19            | Human           | _Homo sapiens_   |
| mm10            | Mouse           | _Mus musculus_   |
| mmul10          | Rhesus Monkey   | _Macaca mulatta_ |
| bosTau9         | Domestic Cattle | _Bos taurus_     |

- **Spike-in genomes supported**: Spike-in genomes supported is limited to:

| Genome Assembly | Organism  | Scientific Name           |
| --------------- | --------- | ------------------------- |
| dmelr6.32       | Fruit Fly | _Drosophila melanogaster_ |
| ecoli_k12       | E. coli   | _Escherichia coli_        |
