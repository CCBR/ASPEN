# Running ASPEN

To effectively run the ASPEN (ATAC-Seq PipEliNe) on the Biowulf High-Performance Computing (HPC) system, please follow the detailed user guide below:

## 🛠️ Prerequisites

- **Biowulf Account:** Ensure you have an active Biowulf account.
- **Data Preparation:** Store your raw ATAC-Seq paired-end FASTQ files in a directory accessible from Biowulf.

## 🌐 Setting Up the Environment

### 🚀 Load the ASPEN Module on Biowulf

To access ASPEN, load the `ccbrpipeliner` module:

```bash
module load ccbrpipeliner/8
```

This command adds aspen to your system's PATH, allowing you to execute pipeline commands directly.

> **Note**: If you're operating outside of Biowulf, ensure that dependencies such as snakemake, python, and singularity are installed and accessible in your system's PATH.

### 📝 Create a Sample Manifest

ASPEN requires a sample manifest file (`samples.tsv`) to identify and organize your input data. This tab-separated file should include the following columns:

- `replicateName`: Unique identifier for each replicate.
- `sampleName`: Identifier for the sample; multiple replicates can share the same sample name.
- `path_to_R1_fastq`: Absolute path to the Read 1 FASTQ file.
- `path_to_R2_fastq`: Absolute path to the Read 2 FASTQ file (required for paired-end data).

!!! note
Symlinks for R1 and R2 files will be created in the results directory, named as <replicateName>.R1.fastq.gz and <replicateName>.R2.fastq.gz, respectively. Therefore, original filenames do not need to be altered.

!!! note
The `replicateName` is used as a prefix for individual peak calls, while the `sampleName` serves as a prefix for consensus peak calls.

!!! note
For differential ATAC analysis, create a `contrasts.tsv` file with two columns (Group1 and Group2 ... aka Sample1 and Sample2, without headers) and place it in the output directory after initialization. Ensure each group/sample in the contrast has at least two replicates, as DESeq2 requires this for accurate contrast calculations.

## 🏃 Running the ASPEN Pipeline

ASPEN operates through a series of modes to facilitate various stages of the analysis.

### 🗂️ Initialize the Working Directory

Begin by initializing your working directory, which will house configuration files and results. Replace <path_to_output_folder> with your desired output directory path:

```bash
aspen -m=init -w=<path_to_output_folder>
```

This command generates a config.yaml and a placeholder `samples.tsv` in the specified directory. Edit these files to reflect your experimental setup, replacing the placeholder `samples.tsv` with your prepared manifest. If performing differential analysis, include the `contrasts.tsv` file at this stage.

!!! note
To explore all possible options of the `aspen` command you can either run it without any arguments or run `aspen --help`

Here is what help looks like:

```bash

##########################################################################################

Welcome to
____ ____ ___  ____ _  _
|__| [__  |__] |___ |\ |
|  | ___] |    |___ | \|

A_TAC_S_eq A_nalysis P_ip_E_li_N_e

##########################################################################################

This pipeline was built by CCBR (https://bioinformatics.ccr.cancer.gov/ccbr)
Please contact Vishal Koparde for comments/questions (vishal.koparde@nih.gov)

##########################################################################################

Here is a list of genome supported by aspen:

  * hg19          [Human]
  * hg38          [Human]
  * mm10          [Mouse]
  * mmul10        [Macaca mulatta(Rhesus monkey) or rheMac10]
  * bosTau9       [Bos taurus(cattle)]

aspen calls peaks using the following tools:

 * MACS2
 * Genrich        [RECOMMENDED FOR USE]

USAGE:
  bash ./aspen -w/--workdir=<WORKDIR> -m/--runmode=<RUNMODE>

Required Arguments:
1.  WORKDIR     : [Type: String]: Absolute or relative path to the output folder with write permissions.

2.  RUNMODE     : [Type: String] Valid options:
    * init      : initialize workdir
    * dryrun    : dry run snakemake to generate DAG
    * run       : run with slurm
    * runlocal  : run without submitting to sbatch
    ADVANCED RUNMODES (use with caution!!)
    * unlock    : unlock WORKDIR if locked by snakemake NEVER UNLOCK WORKDIR WHERE PIPELINE IS CURRENTLY RUNNING!
    * reconfig  : recreate config file in WORKDIR (debugging option) EDITS TO config.yaml WILL BE LOST!
    * reset     : DELETE workdir dir and re-init it (debugging option) EDITS TO ALL FILES IN WORKDIR WILL BE LOST!
    * printbinds: print singularity binds (paths)
    * local     : same as runlocal

Optional Arguments:

--genome|-g     : genome eg. hg38
--manifest|-s   : absolute path to samples.tsv. This will be copied to output folder                    (--runmode=init only)
--help|-h       : print this help

Example commands:
  bash ./aspen -w=/my/output/folder -m=init
  bash ./aspen -w=/my/output/folder -m=dryrun
  bash ./aspen -w=/my/output/folder -m=run

##########################################################################################

VersionInfo:
  python          : python/3.10
  snakemake       : snakemake
  pipeline_home   : /data/CCBR_Pipeliner/Pipelines/ASPEN/feature_spikeins
  git commit/tag  : fc0699d6a7f9766963c8e7020c01214966616fab    v1.0.6-29-gfc0699d
  aspen_version   : v1.0.6-dev-spikeins

##########################################################################################
```

### ⚙️ Configurational Changes

#### MACS2

MACS2 parameters can be changed by editing this block in the `config.yaml`:

```yaml
macs2:
  extsize: 200
  shiftsize: 100
  p: 0.01
  qfilter: 0.05
  annotatePeaks: True
```

#### Genrich

Genrich paramaters can be changed by editing this block in the `config.yaml`:

```yaml
genrich:
  s: 5
  m: 6
  q: 1
  l: 100
  g: 100
  d: 100
  qfilter: 0.05
  annotatePeaks: True
```

#### Contrasts

If contrasts are to be calculated then fixed-width peaks are used with the following changable options:

```yaml
# peak fixed width
fixed_width: 500

# contrasts info
contrasts: "WORKDIR/contrasts.tsv"
contrasts_fc_cutoff: 2
contrasts_fdr_cutoff: 0.05
```

### 🧬 Enabling Spike-In Normalization (Optional)

ASPEN supports spike-in normalization, which is useful for controlling technical variability or comparing global shifts in chromatin accessibility across samples. Spike-in reads (e.g., from _Drosophila melanogaster_ or _E. coli_) are aligned separately and used to compute normalization factors that are applied to host genome accessibility counts.

To enable spike-in normalization, edit the `config.yaml` file that was generated during `init`. You can find it in your output directory (`<path_to_output_folder>/config.yaml`).

Open the file and locate the following lines:

<pre><code>spikein: False
# spikein: True

spikein_genome: "dmelr6.32" # Drosophila mel.
# spikein_genome: "ecoli_k12" # E. coli
</code></pre>

To activate spike-in normalization:

1. Set `spikein` to `True`
2. Uncomment or change the `spikein_genome` to match your experiment

#### 📝 Example Configuration

For _Drosophila_ spike-in:

<pre><code>spikein: True
spikein_genome: "dmelr6.32"
</code></pre>

For _E. coli_ spike-in:

<pre><code>spikein: True
spikein_genome: "ecoli_k12"
</code></pre>

> **Note**: The spike-in genome must be pre-indexed and available in the reference directory used by ASPEN. Please contact the pipeline maintainers if you need to add a new spike-in genome.

Once enabled, ASPEN will:

- Align reads to both the host and spike-in genomes.
- Quantify spike-in counts per sample.
- Normalize accessibility counts using spike-in-derived scaling factors.
- Report both normalized and raw counts in the output tables and reports.

This step is optional but highly recommended when you expect global changes in chromatin accessibility due to treatments or perturbations.

### 🛠️ Dry Run the Pipeline

Before executing the full analysis and after editing the `config.yaml` as needed, perform a dry run to visualize the workflow and identify potential issues:

```bash
aspen -m=dryrun -w=<path_to_output_folder>
```

This step outlines the sequence of tasks (Directed Acyclic Graph - DAG) without actual execution, allowing you to verify the planned operations.

### 🚀 Execute the Pipeline

If the dry run output is satisfactory, proceed to execute the pipeline:

```bash
aspen -m=run -w=<path_to_output_folder>
```

This command submits a master job to the Slurm workload manager, which orchestrates the entire analysis workflow, managing job submissions and monitoring progress.

- 🛠️ **Optional Argument**:

`--singcache` or `-c`: Specify a Singularity cache directory. The default is `/data/${USER}/.singularity` if available; otherwise, it defaults to `${WORKDIR}/snakemake/.singularity`.

**💡 Example Command**:

```bash
aspen -m=run -w=<path_to_output_folder> -c /data/${USER}/.singularity
```

This command runs the pipeline with the specified working directory and Singularity cache directory.

> **Note**: If deploying on Biowulf, try setting the `--singcache` to `/data/CCBR_Pipeliner/SIFS` to reuse the pre-pulled containers and save time.

## 📊 Monitor ASPEN Runs

To monitor the status of your ASPEN pipeline and its associated jobs on a Slurm-managed system, you can utilize the squeue and scontrol commands. The squeue command provides information about jobs in the scheduling queue, while scontrol offers detailed insights into specific jobs.

To view all your active and pending jobs, execute:

```bash
squeue -u $USER --format="%.18i %.30j %.11P %.15T %.10r %.10M %.10l %.5D %.5C %.10m %.25b %.8N" --sort=-S
```

This command lists all jobs submitted by your user account, displaying details such as job IDs, partitions, job names, user names, job states, and the nodes allocated.

For more granular information about a specific job, including its child jobs spawned by ASPEN, use the scontrol command:

```bash
scontrol show job <jobid>
```

Replace <jobid> with the specific Job ID of interest. This will provide comprehensive details about the job's configuration and status, aiding in effective monitoring and management of your ASPEN pipeline processes.

To quickly guage the process of the entire pipeline run:

```bash
grep "done$" <path_to_output_folder>/snakemake.log
```
