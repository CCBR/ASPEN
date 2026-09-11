# 🚀 ASPEN Outputs

## 📂 Workdir

The workdir which is supplied as `-w` while running aspen `init`, `dryrun` and `run` commands will contain the following files:

```bash
WORKDIR
├── cluster.json
├── config.yaml
├── contrasts.tsv
├── dryrun_git_commit.txt
├── dryrun.log
├── fastqs
├── logs
├── results
├── run_git_commit.txt
├── runinfo.yaml
├── runslurm_snakemake_report.html
├── sampleinfo.txt
├── samples.tsv
├── scripts
├── slurm-XXXXXXX.out
├── snakemake.log
├── snakemake.log.jobby
├── snakemake.log.jobby.short
├── snakemake.stats
├── submit_script.sbatch
└── tools.yaml
```

Here are more details about these files:

| **File**                         | **File Type** | **Mode (`-m`) When This File is Created/Overwritten** | **Description**                                                                                                                                                       |
| -------------------------------- | ------------- | ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cluster.json`                   | JSON          | init                                                  | Defines cluster resources per snakemake rule; this file can be edited to override default computate resource allocations per snakemake rule                           |
| `config.yaml`                    | YAML          | init; can be edited later                             | Configurable parameters for this specific run                                                                                                                         |
| `contrasts.tsv`                  | TSV           | Needs to be added in after init                       | List of contrasts to run, one per line; has no header                                                                                                                 |
| `dryrun_git_commit.txt`          | TXT           | dryrun                                                | The git commit hash of the version of ASPEN used at dryrun                                                                                                            |
| `dryrun.log`                     | TXT           | dryrun                                                | Log from `-m=dryrun`                                                                                                                                                  |
| `fastqs`                         | FOLDER        | dryrun                                                | Folder containing symlinks to raw data                                                                                                                                |
| `logs`                           | FOLDER        | dryrun                                                | Folder containing all logs including Slurm `.out` and `.err` files. Also contains older timestamped `runinfo.yaml` and `snakemake.stats` files.                       |
| `results`                        | FOLDER        | Created at dryrun but populated during run            | Main outputs folder                                                                                                                                                   |
| `runinfo.yaml`                   | YAML          | After completion of run                               | Metadata about the run executor, etc.                                                                                                                                 |
| `runslurm_snakemake_report.html` | HTML          | After completion of run                               | HTML report including DAG and resource utilization                                                                                                                    |
| `sampleinfo.txt`                 | TXT           | dryrun, run                                           | Tab-delimited mappings between `replicateNames` and `sampleNames`                                                                                                     |
| `samples.tsv`                    | TSV           | init; can be edited later                             | Tab-delimited manifest with `replicateName`, `sampleName`, `path_to_R1_fastq`, `path_to_R2_fastq`. This file has a header.                                            |
| `scripts`                        | FOLDER        | init                                                  | Folder keeps local copy of scripts called by various rules                                                                                                            |
| `run_git_commit.txt`             | TXT           | run                                                   | The git commit hash of the version of ASPEN used at run                                                                                                               |
| `slurm-XXXXXXX.out`              | TXT           | run                                                   | Slurm `.out` file for the master job                                                                                                                                  |
| `snakemake.log`                  | TXT           | run                                                   | Snakemake `.log` file for the master job; older copies timestamped and moved into `logs` folder                                                                       |
| `snakemake.stats`                | JSON          | run                                                   | per rule runtime stats                                                                                                                                                |
| `submit_script.sbatch`           | TXT           | run                                                   | Slurm script to kickstart the main Snakemake job                                                                                                                      |
| `tools.yaml`                     | YAML          | run                                                   | YAML containing the version of tools used in the pipeline (obsolete; was used to load specific module versions prior to moving over to Docker/Singularity containers) |

## 📊 `results` folder

The results directory contains the actual output files. Below are the folders that you may find within it.

```bash
WORKDIR
├── results
    ├── alignment
    │   ├── dedupBam
    │   ├── filteredBam
    │   ├── qsortedBam
    │   └── tagAlign
    ├── peaks
    │   ├── genrich
    │   │   ├── DiffATAC
    │   │   │   ├── dedup
    │   │   │   │   ├── reads
    │   │   │   │   └── tn5sites
    │   │   │   └── nondedup
    │   │   │       ├── reads
    │   │   │       └── tn5sites
    │   │   └── fixed_width
    │   │       └── counts
    │   │           ├── dedup
    │   │           └── nondedup
    │   └── macs2
    │       ├── DiffATAC
    │       │   ├── dedup
    │       │   │   ├── reads
    │       │   │   └── tn5sites
    │       │   └── nondedup
    │       │       ├── reads
    │       │       └── tn5sites
    │       └── fixed_width
    │           └── counts
    │               ├── dedup
    │               └── nondedup
    ├── QC
    │   ├── fastqc
    │   ├── fld
    │   ├── FQscreen
    │   ├── frip
    │   ├── multiqc_data
    │   ├── peak_annotation
    │   ├── preseq
    │   └── tss
    ├── spikein
    │   ├── <sample_1>
    │   ├── <sample_2>
    │   ├── <sample_3>
    │   │ ...
    │   └── <sample_n>
    ├── tmp
    │   ├── BL
    │   ├── genrichReads
    │   └── trim
    └── visualization
        ├── dedup
        │   ├── reads_bam
        │   ├── reads_bed
        │   ├── reads_bigwig
        │   ├── tn5sites_bam
        │   └── tn5sites_bigwig
        └── nondedup
            ├── reads_bam
            ├── reads_bed
            ├── reads_bigwig
            ├── tn5sites_bam
            └── tn5sites_bigwig
```

Content details:

| Folder        | SubFolder           | Description                                                                                                                                                                                                                                         |
| ------------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| alignment     | qsortedBam          | - Query sorted Bowtie2 alignments in BAM format. <br> - Excludes unmapped and platform/vendor quality failing reads. <br> - Used for Genrich peak calling.                                                                                          |
| alignment     | filteredBam         | - Filtered BAM files after excluding non-primary, supplementary, and MAPQ <=5 alignments. <br> - This is the `nondedup` BAM (i.e. before duplicate removal) used for the `nondedup` counts/DiffATAC variant. <br> - Derived from `qsortedBam`.                                                        |
| alignment     | dedupBam            | - Deduplicated filtered BAM files (PCR/optical duplicates marked with PicardTools and excluded). <br> - Derived from `filteredBam`. <br> - Used for MACS2 peak calling, FRiP, and the recommended `dedup` counts/DiffATAC variant. <br> - Can also be used downstream with CCBR_TOBIAS pipeline.               |
| alignment     | tagAlign            | - `tagAlign.gz` files used for MACS2 peak calling. <br> - Derived from `dedupBam`.                                                                                                                                                                  |
| peaks         | genrich & macs      | - Genrich/MACS2 peak calls (raw, consensus, fixed-width). <br> - Contains ROI files with Diff-ATAC results if `contrasts.tsv` is provided. <br> - Calculated with DESeq2 using both read counts and tn5 nicking sites in ROI. <br> - Counts matrices and DiffATAC results are generated separately for `dedup` (PCR duplicates removed, recommended) and `nondedup` (duplicates retained) BAMs, in like-named subfolders.               |
| visualization | dedup / nondedup    | - Tn5 nicking-site/read BAMs, BEDs, and bigwigs, split into `dedup` and `nondedup` subfolders depending on whether PCR duplicates were removed from the source BAM before generating them.                                                        |
| QC            | various             | - Flagstats. <br> - Dupmetrics. <br> - Read counts. <br> - Motif enrichments. <br> - FLD stats. <br> - Fqscreen. <br> - FRiP. <br> - ChIPSeeker results. <br> - TSS enrichments. <br> - Preseq. <br> - Homer/AME motif enrichments. <br> - MultiQC. |
| QC            | peak_annotation     | detailed peak annotations described below                                                                                                                                                                                                           |
| spikein       | 1 folder per sample | - Per sample spike-in counts. <br> - Overall scaling factors table.                                                                                                                                                                                 |
| tmp           | various             | - Can be deleted. <br> - Blacklist index. <br> - Intermediate FASTQs. <br> - Genrich output reads.                                                                                                                                                  |

!!! note
BAM files from `dedupBam` can be used for downstream footprinting analysis using [CCBR_TOBIAS](https://github.com/CCBR/CCBR_Tobias) pipeline

!!! note
[bamCompare](https://deeptools.readthedocs.io/en/develop/content/tools/bamCompare.html) from deeptools can be run to compare BAMs from `dedupBam` for comprehensive BAM comparisons.

!!! note
BAM files from `dedupBam` can also be converted to BED format and processed with [chromVAR](https://github.com/GreenleafLab/chromVAR) to identify variability in motif accessibility across samples and assess differentially active transcription factors from the JASPAR database.

#### How consensus peaks are generated

**Why two rounds?** A single replicate's peak calls are noisy — some "peaks"
are just sequencing/technical artifacts that happened to occur in one
replicate. Pooling and filtering peaks *within* a sample (Round 1) gives a
reproducibility-checked, per-sample truth set. But differential accessibility
testing needs to compare counts *across* samples/conditions, which requires
one shared set of regions measured identically everywhere — a per-sample
peak set alone doesn't give you that. Round 2 solves this by merging the
per-sample consensus peaks into a single, fixed-width Region of Interest
(ROI) set shared by every sample, so the same coordinates can be quantified
and compared across the whole experiment.

ASPEN produces peaks at two levels of consensus. Understanding the distinction is
important for interpreting output files and configuring the pipeline correctly.

ASPEN generates three related-but-distinct peak representations, not three
competing choices: `pooled.narrowPeak` (diagnostic — how many peaks exist in
the pooled replicate data, before requiring individual-replicate
reproducibility), `consensus.bed` (Round 1 — variable-width,
reproducibility-filtered peaks per sample, useful for peak annotation and for
comparing against other pipelines' conventional peak outputs), and the
`fixed_width` consensus (Round 2 — same width for every ROI, specifically so
that read/Tn5 counts and DESeq2 differential testing aren't confounded by
peak-length differences or broken by daisy-chained merges across many
samples). **Use the fixed-width ROI set for differential accessibility
testing; use `consensus.bed`/`pooled.narrowPeak` for peak annotation, QC, or
cross-pipeline comparison.**

**Round 1 — Per-sample consensus** (`*.macs2.consensus.bed` / `*.genrich.consensus.bed`)

> _"Which peaks are reproducible across biological replicates of the same sample?"_

1. All replicate tagAlign files for a sample are **pooled** and passed to MACS2/Genrich together → produces a large set of candidate peaks from the pooled data.
2. Each candidate peak is checked for overlap with peaks called in each **individual replicate**.
3. A peak is retained in the consensus only if it overlaps peaks in **≥ `consensus_min_replicates`** replicates (default: 2, meaning present in at least 2 replicates). Adjust `consensus_min_replicates` in `config.yaml` to make this filter stricter.

```
replicate 1 peaks ─┐
replicate 2 peaks ─┼─► pooled peaks ─► overlap filter ─► sample.consensus.bed
replicate 3 peaks ─┘                    (≥ min_replicates)
```

**Round 2 — ROI consensus** (`ROI.macs2.bed` / `ROI.genrich.bed`)

> _"Across ALL samples, what is the unified set of fixed-width windows for differential accessibility analysis?"_

1. Per-sample consensus peaks are converted to **fixed-width windows** (default: 500 bp, centered on the peak summit) using the method from [Corces et al. 2018](https://doi.org/10.1038/nmeth.4396). Window width is controlled by `fixed_width` in `config.yaml`.
2. Each fixed-width peak is additionally required to overlap peaks in **≥ `roi_min_replicates`** samples/replicates (default: 1) and to meet the **`roi_min_spm`** signal-per-million threshold (default: 2) — analogous to, but independent from, the Round 1 `consensus_min_*` filters above. Adjust `roi_min_replicates`/`roi_min_spm` in `config.yaml` to change how strict this cross-sample filter is.
3. Fixed-width peaks passing that filter are **merged** → `ROI.macs2.bed` — the master set of regions used for DESeq2 read counting and differential accessibility analysis.
4. P-values across the fixed-width consensus are re-normalized (`*.renormalized.fixed_width.consensus.narrowPeak`) to account for the pooling.

```
sample1.consensus.bed ─► fixed-width peaks ─┐
sample2.consensus.bed ─► fixed-width peaks ─┼─► merge ─► ROI.bed ─► DESeq2
sample3.consensus.bed ─► fixed-width peaks ─┘
```

!!! tip "Config knobs that control consensus"

| Parameter                  | Default | Round | Effect                                                                       |
| -------------------------- | ------- | ----- | ---------------------------------------------------------------------------- |
| `consensus_min_replicates` | `2`     | 1     | Min. replicates a peak must appear in to be retained in per-sample consensus |
| `consensus_min_spm`        | `5`     | 1     | Min. signal-per-million reads threshold for a peak to be included            |
| `roi_min_replicates`       | `1`     | 2     | Min. samples/replicates a fixed-width peak must appear in to be kept in the ROI set |
| `roi_min_spm`              | `2`     | 2     | Min. signal-per-million reads threshold for a fixed-width peak to be kept in the ROI set |
| `fixed_width`              | `500`   | 1     | Width (bp) of fixed-width peaks used to build the ROI set                    |

#### Counts matrices: reads vs Tn5 nicking sites, and `dedup` vs `nondedup`

Once the ROIs are established, ASPEN generates two distinct count matrices:

- **Tn5 Nicking Sites Count Matrix**: This matrix quantifies the frequency of Tn5 transposase insertion events at each ROI. The number of insertion events serves as a proxy for chromatin accessibility, since Tn5 transposase preferentially inserts into accessible regions of the chromatin. By counting these insertion sites, researchers can accurately infer the openness of chromatin regions under different experimental conditions.

- **Read Counts Matrix**: This matrix records the number of sequencing reads mapped to each ROI. While Tn5 nicking sites provide a more direct measure of chromatin accessibility, read counts are included in ASPEN as they have been widely used in recent publications. Analyzing both matrices together offers a comprehensive view of chromatin accessibility dynamics.

Both count matrices (and the corresponding DiffATAC/DESeq2 results) are generated **twice** — once from `dedup.bam` (PCR/optical duplicates removed) and once from `filtered.bam` (quality-filtered, duplicates retained, labeled `nondedup`) — under separate `dedup`/`nondedup` output folders (see the folder tree above). Previously only the duplicate-retaining `filtered.bam` was used, which was inconsistent with how MACS2 peaks are called (from `dedup.bam`-derived `tagAlign.gz`) and how FRiP is computed (also from `dedup.bam`).

**Recommendation: use the `dedup` counts/DiffATAC results for standard differential accessibility analysis.** PCR duplication rate varies across samples (input amount, PCR cycles, library complexity), and this variability is not corrected by DESeq2/edgeR size factors — leaving duplicates in can confound differential calls. This also matches standard ATAC-seq practice (e.g. the ENCODE ATAC-seq pipeline, ArchR, Signac).

The `nondedup` outputs are retained for comparison/legacy reasons, with one caveat worth knowing: because Tn5 preferentially inserts into a limited set of highly accessible positions, independent DNA molecules can genuinely land on the same insertion coordinate at very open/narrow sites, and naive deduplication can occasionally discard some true (non-PCR) signal there. Picard's paired-end duplicate definition (which requires *both* fragment ends to match, not just one nick site) substantially — though not perfectly — mitigates this. If you suspect this is affecting your data, cross-check the per-replicate NRF/PBC (`QC/preseq`) library-complexity metrics: unexpectedly high duplication despite high library complexity points to this effect rather than true PCR over-amplification.

#### Peak Annotation folder

This folder will contain ChIPseeker results for:

- individual replicate `*.narrowPeak` files
- `*.consensus.bed` files
- `*.fixed_width.consensus.narrowPeak` files

The `QC` folder contains the `multiqc_report.html` file which provides a comprehensive summary of the quality control metrics across all samples, including read quality, duplication rates, and other relevant statistics. This report aggregates results from various QC tools such as FastQC, FastqScreen, FLD, TSS enrichment, Peak Annotations, and others, presenting them in an easy-to-read format with interactive plots and tables. It helps in quickly identifying any issues with the sequencing data and ensures that the data quality is sufficient for downstream analysis.

| File                                  | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `*.narrowPeak.annotated.gz`           | peak calls annotated using ChIPseeker, gzipped                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `*.narrowPeak.annotated.distribution` | annotation bins : <br> - **3'UTR**: No. of peaks in the 3' untranslated region. <br> - **5'UTR**: No. of peaks in the 5' untranslated region. <br> - **Distal Intergenic**: No. of peaks in distal intergenic regions. <br> - **Downstream (<1kb)**: No. of peaks annotated downstream within 1kb. <br> - **Downstream (1-2kb)**: No. of peaks annotated downstream between 1-2kb. <br> - **Downstream (2-3kb)**: No. of peaks annotated downstream between 2-3kb. <br> - **Promoter (<=1kb)**: No. of peaks in promoters within 1kb. <br> - **Promoter (1-2kb)**: No. of peaks in promoters between 1-2kb. <br> - **Exon**: No. of peaks in exonic regions. |
| `*.narrowPeak.annotated_summary`      | More stats on each of the above bins .. like: <br> - medianWidth <br> - medianpValue <br> - medianqValue                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `*.narrowPeak.genelist`               | ensemblID and gene symbols of genes with peaks in their promoter regions (including 5' UTR)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |

### MACS2 output folder

For a typical 2 sample analysis with 2 replicates each this folder should look like this:

```bash
WORKDIR
├── results
    ├── peaks
        └── macs2
            ├── sample1
            │   ├── sample1_replicate1.macs2.narrowPeak
            │   ├── sample1_replicate1.macs2.narrowPeak_motif_enrichment
            │   │   ├── ame_results.txt
            │   │   ├── background.fa
            │   │   ├── knownResults
            │   │   ├── knownResults.html
            │   │   ├── knownResults.txt
            │   │   ├── motifFindingParameters.txt
            │   │   ├── seq.autonorm.tsv
            │   │   └── target.fa
            │   ├── sample1_replicate1.macs2.unfiltered.narrowPeak
            │   ├── sample1_replicate2.macs2.narrowPeak
            │   ├── sample1_replicate2.macs2.narrowPeak_motif_enrichment
            │   │   ├── ame_results.txt
            │   │   ├── background.fa
            │   │   ├── knownResults
            │   │   ├── knownResults.html
            │   │   ├── knownResults.txt
            │   │   ├── motifFindingParameters.txt
            │   │   ├── seq.autonorm.tsv
            │   │   └── target.fa
            │   ├── sample1_replicate2.macs2.unfiltered.narrowPeak
            │   ├── sample1.macs2.consensus.bed
            │   ├── sample1.macs2.consensus.bed_motif_enrichment
            │   │   ├── ame_results.txt
            │   │   ├── background.fa
            │   │   ├── knownResults
            │   │   ├── knownResults.html
            │   │   ├── knownResults.txt
            │   │   ├── motifFindingParameters.txt
            │   │   ├── seq.autonorm.tsv
            │   │   └── target.fa
            │   ├── sample1.macs2.pooled.narrowPeak
            │   ├── sample1.macs2.pooled_summits.bed
            │   └── sample1.macs2.pooled.unfiltered.narrowPeak
            ├── sample1.consensus.macs2.peakfiles
            ├── sample1.replicate.macs2.peakfiles
            ├── DiffATAC
            │   ├── dedup
            │   │   ├── reads
            │   │   │   ├── all_diff_atacs.html
            │   │   │   ├── all_diff_atacs.tsv
            │   │   │   ├── degs.done
            │   │   │   ├── sample2_vs_sample1.html
            │   │   │   └── sample2_vs_sample1.tsv
            │   │   └── tn5sites
            │   │       ├── all_diff_atacs.html
            │   │       ├── all_diff_atacs.tsv
            │   │       ├── degs.done
            │   │       ├── sample2_vs_sample1.html
            │   │       └── sample2_vs_sample1.tsv
            │   └── nondedup
            │       ├── reads
            │       │   ├── all_diff_atacs.html
            │       │   ├── all_diff_atacs.tsv
            │       │   ├── degs.done
            │       │   ├── sample2_vs_sample1.html
            │       │   └── sample2_vs_sample1.tsv
            │       └── tn5sites
            │           ├── all_diff_atacs.html
            │           ├── all_diff_atacs.tsv
            │           ├── degs.done
            │           ├── sample2_vs_sample1.html
            │           └── sample2_vs_sample1.tsv
            ├── sample2
            │   ├── sample2_replicate1.macs2.narrowPeak
            │   ├── sample2_replicate1.macs2.narrowPeak_motif_enrichment
            │   │   ├── ame_results.txt
            │   │   ├── background.fa
            │   │   ├── knownResults
            │   │   ├── knownResults.html
            │   │   ├── knownResults.txt
            │   │   ├── motifFindingParameters.txt
            │   │   ├── seq.autonorm.tsv
            │   │   └── target.fa
            │   ├── sample2_replicate1.macs2.unfiltered.narrowPeak
            │   ├── sample2_replicate2.macs2.narrowPeak
            │   ├── sample2_replicate2.macs2.narrowPeak_motif_enrichment
            │   │   ├── ame_results.txt
            │   │   ├── background.fa
            │   │   ├── knownResults
            │   │   ├── knownResults.html
            │   │   ├── knownResults.txt
            │   │   ├── motifFindingParameters.txt
            │   │   ├── seq.autonorm.tsv
            │   │   └── target.fa
            │   ├── sample2_replicate2.macs2.unfiltered.narrowPeak
            │   ├── sample2.macs2.consensus.bed
            │   ├── sample2.macs2.consensus.bed_motif_enrichment
            │   │   ├── ame_results.txt
            │   │   ├── background.fa
            │   │   ├── knownResults
            │   │   ├── knownResults.html
            │   │   ├── knownResults.txt
            │   │   ├── motifFindingParameters.txt
            │   │   ├── seq.autonorm.tsv
            │   │   └── target.fa
            │   ├── sample2.macs2.pooled.narrowPeak
            │   ├── sample2.macs2.pooled_summits.bed
            │   └── sample2.macs2.pooled.unfiltered.narrowPeak
            ├── sample2.consensus.macs2.peakfiles
            ├── sample2.replicate.macs2.peakfiles
            └── fixed_width
                ├── sample1_replicate1.macs2.fixed_width.narrowPeak
                ├── sample1_replicate2.macs2.fixed_width.narrowPeak
                ├── sample1.fixed_width.consensus.narrowPeak
                ├── sample1.renormalized.fixed_width.consensus.narrowPeak
                ├── sample1.renormalized.fixed_width.consensus.narrowPeak.annotated.gz
                ├── counts
                │   ├── dedup
                │   │   ├── ROI.macs2.reads_counts.tsv
                │   │   └── ROI.macs2.tn5sites_counts.tsv
                │   └── nondedup
                │       ├── ROI.macs2.reads_counts.tsv
                │       └── ROI.macs2.tn5sites_counts.tsv
                ├── sample2_replicate1.macs2.fixed_width.narrowPeak
                ├── sample2_replicate2.macs2.fixed_width.narrowPeak
                ├── sample2.fixed_width.consensus.narrowPeak
                ├── sample2.renormalized.fixed_width.consensus.narrowPeak
                ├── sample2.renormalized.fixed_width.consensus.narrowPeak.annotated.gz
                ├── ROI.macs2.bed
                ├── ROI.macs2.bed.annotated.gz
                ├── ROI.macs2.bed.annotated.gz.gz
                ├── ROI.macs2.bed.annotation_distribution
                ├── ROI.macs2.bed.annotation_summary
                ├── ROI.macs2.bed.genelist
                ├── ROI.macs2.gtf
                ├── ROI.macs2.narrowPeak
                ├── ROI.macs2.renormalized.narrowPeak
                └── Rplots.pdf
```

Some of the key output files are:

| File                                                | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `*.macs2.narrowPeak`                                | peak calls from MACS2 filtered by q-value for each samples each replicate                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `*.macs2.unfiltered.narrowPeak`                     | peak calls from MACS2 (unfiltered) for each samples each replicate                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `*.narrowPeak_motif_enrichment/ame_results.txt`     | motif enrichment results from AME tool from MEME suite using HOCOMOCO v11 database                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `*.narrowPeak_motif_enrichment/knownResults.txt`    | motif enrichment results using HOMER with HOCOMOCO v11 database                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `*.macs2.consensus.bed`                             | consensus peak call between multiple replicates of each sample. **Note:** consensus bed annotations are located in `QC/peak_annotations`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `DiffATAC/dedup/reads`, `DiffATAC/nondedup/reads`       | folder containing differential open chromatin results: <br> - computated using read counts in MACS2 regions of interest (ROIs) <br> - `dedup` uses `dedup.bam`-derived counts (PCR/optical duplicates removed, recommended); `nondedup` uses `filtered.bam`-derived counts (duplicates retained) <br> - `all_diff_atacs.html` HTML report aggregated across all contrasts from `contrasts.tsv` <br> - `all_diff_atacs.tsv` DESeq2 results in TSV format aggregated across all contrasts from `contrasts.tsv` <br> - HTML and TSV file each per contrast in `contrasts.tsv`                                                                                                                                                                                                                                   |
| `DiffATAC/dedup/tn5sites`, `DiffATAC/nondedup/tn5sites` | folder containing differential open chromatin results: <br> - computated using Tn5 nicking site counts in MACS2 regions of interest (ROIs) <br> - `dedup` uses `dedup.bam`-derived counts (PCR/optical duplicates removed, recommended); `nondedup` uses `filtered.bam`-derived counts (duplicates retained) <br> - `all_diff_atacs.html` HTML report aggregated across all contrasts from `contrasts.tsv` <br> - `all_diff_atacs.tsv` DESeq2 results in TSV format aggregated across all contrasts from `contrasts.tsv` <br> - HTML and TSV file each per contrast in `contrasts.tsv`                                                                                                                                                                                                                       |
| `fixed_width`                                       | `fixed_width` can be set in `config.yaml` to create peaks of a user defined fixed width (default 500bp). This folder contains: <br> - individual replicate `*.fixed_width.narrowPeak` files <br> - `*.renormalized.fixed_width.consensus.narrowPeak` per sample; [_Corces et. al._](https://doi.org/10.1038/nmeth.4396) method is used for consensus calling; used to generate MACS2 regions of interest (ROI) peaks which are used to generate a reads or Tn5 sites counts matrix for DESeq2 <br> - ROI related files: `ROI.macs2.bed`, `ROI.macs2.bed.annotated.gz`, `ROI.macs2.annotation_summary`, `ROI.macs2.annotation_distribution` |
| `fixed_width/counts/{dedup,nondedup}/ROI.macs2.read_counts.tsv`      | read counts in MACS2 ROIs using featureCounts; generated separately from `dedup.bam` (duplicates removed, recommended) and `filtered.bam`/`nondedup` (duplicates retained)                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `fixed_width/counts/{dedup,nondedup}/ROI.reads_scaled_counts.tsv`    | `ROI.macs2.read_counts.tsv` scaled using spike-in scaling factors                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `fixed_width/counts/{dedup,nondedup}/ROI.tn5sites_counts.tsv`        | Tn5 nicking site counts in MACS2 ROIs using featureCounts; generated separately from `dedup.bam` (duplicates removed, recommended) and `filtered.bam`/`nondedup` (duplicates retained)                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `fixed_width/counts/{dedup,nondedup}/ROI.tn5sites_scaled_counts.tsv` | `ROI.macs2.tn5sites_counts.tsv` scaled using spike-in scaling factors                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |

### Genrich output folder

For a typical 2 sample analysis with 2 replicates each this folder should look like very similar to the MACS2 output structure described above.

## `logs` folder

This directory contains all .err and .out log files generated by SLURM for jobs submitted via Snakemake. Each file follows a consistent naming convention:

```bash
<SLURM_JOB_ID of master/head job>.<SLURM_JOB_ID of child job>.<Snakemake Rule Name>.<wildcard1_name=wildcard1_value,wildcard2_name=wildcard2_value>.<out or err>
```

This structure is particularly useful for troubleshooting and debugging, especially when the SLURM job IDs of failed jobs are known. By examining the corresponding .err or .out files, users can efficiently identify the source of errors within specific Snakemake rules and wildcards.

> DISCLAIMER: This folder hierarchy is significantly different than v1.2.0 and is subject to change with subsequent versions.
