### Limitations of ASPEN

- **Paired-End data required**: ASPEN necessitates paired-end sequencing libraries, as its current design does not support single-end data. Future updates aim to incorporate single-end data compatibility.

- **Infrastructure limit**: Designed primarily for the [BIOWULF](https://hpc.nih.gov/) High-Performance Computing (HPC) system at the National Institutes of Health (NIH), ASPEN's configuration relies on resources specified in the config.yaml file, which are tailored to the BIOWULF file system. Adapting ASPEN for use on other HPC platforms may require adjustments, such as replicating or generating local reference data, modifying code, and accommodating different job schedulers. Plans are underway to deploy ASPEN on the Frederick Research Computing Environment (FRCE) cluster in Frederick.

- **Footprinting analysis**: While ASPEN does not perform footprinting analysis, it is compatible with the [CCBR-TOBIAS](https://github.com/CCBR/CCBR_tobias) pipeline, a separate tool designed for this purpose. TOBIAS (Transcription factor Occupancy prediction By Investigation of ATAC-seq Signal) analyzes ATAC-seq data to predict transcription factor occupancy but generates a substantial number of small files. ASPEN's output can serve as direct input for the CCBR_TOBIAS pipeline, facilitating integrated analyses.

- **Genomes supported**: Genomes supported is limited to:

| Genome Assembly | Organism        | Scientific Name                                             |
| --------------- | --------------- | ----------------------------------------------------------- |
| hg38            | Human           | _Homo sapiens_                                              |
| hg19            | Human           | _Homo sapiens_                                              |
| mm10            | Mouse           | _Mus musculus_                                              |
| mmul10          | Rhesus Monkey   | _Macaca mulatta_                                            |
| bosTau9         | Domestic Cattle | _Bos taurus_                                                |
| hs1             | Human           | _Homo sapiens_ (T2T-CHM13)                                  |
| hs1_chrR        | Human           | _Homo sapiens_ (T2T-CHM13 + chrR rDNA unit; see note below) |

    !!! tip "Use `hs1_chrR` for ribosomal DNA chromatin accessibility studies"
        Standard genome assemblies mask or collapse ribosomal DNA (rDNA) repeat
        loci, making it impossible to call ATAC-seq peaks in these regions.
        `hs1_chrR` is a customized version of the T2T-CHM13 (`hs1`) assembly
        where endogenous rDNA-like sequences are masked throughout the canonical
        chromosomes, and a single consensus rDNA unit (NCBI KY962518.1, modified)
        is inserted as an additional chromosome **chrR**. This design ensures that
        rDNA-mapping reads are captured unambiguously on chrR rather than being
        lost to multi-mapping or suppressed by masking.

        **When to choose `hs1_chrR` over `hs1`:**

        - Your experiment involves a perturbation that may affect nucleolar
          chromatin or ribosomal gene accessibility (e.g., RNA Pol I inhibition,
          nucleolar stress, epigenetic reprogramming).
        - You want to quantify ATAC-seq peaks at rDNA promoters, the transcribed
          region, or the intergenic spacer (IGS) of the ribosomal repeat unit.
        - You need FRiP scores, TSS enrichment, or differential accessibility
          analysis specifically for rDNA loci alongside the rest of the genome.

        **Reference:**
        George SS, Pimkin M, Paralkar VR.
        *"Construction and validation of customized genomes for human and mouse ribosomal DNA mapping."*
        J Biol Chem (2023). <https://doi.org/10.1016/j.jbc.2023.105529>

        Genome files: <https://github.com/vikramparalkar/rDNA-Mapping-Genomes>

- **Spike-in genomes supported**: Spike-in genomes supported is limited to:

| Genome Assembly | Organism  | Scientific Name           |
| --------------- | --------- | ------------------------- |
| dmelr6.32       | Fruit Fly | _Drosophila melanogaster_ |
| ecoli_k12       | E. coli   | _Escherichia coli_        |
