# ASPEN

**A**tac **S**eq **P**ip**E**li**N**e :

[CCBR](https://bioinformatics.ccr.cancer.gov/ccbr/) recommends ASPEN to effectively analyze ATAC-seq datasets on the [BIOWULF](https://hpc.nih.gov) HPC system at the [NIH](https://www.nih.gov/).

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.13755867.svg)](https://doi.org/10.5281/zenodo.13755867)
[![release](https://img.shields.io/github/v/release/CCBR/ASPEN?color=blue&label=latest%20release)](https://github.com/CCBR/ASPEN/releases/latest)

## QuickStart guide

```bash
module load ccbrpipeliner
```

> **Note**: This is illustrative example output captured at doc-writing time — exact values (e.g. `pipeline_home`, `git commit/tag`, `aspen_version`) will differ depending on which ASPEN version/branch is installed at your site. Run `aspen --help` yourself to see the current values for your installation.

```bash
aspen --help
```

```bash
##########################################################################################

Welcome to

╔══════════════════════════════════╗
║  ASPEN PIPELINE                  ║
║  v1.3.0                          ║
╚══════════════════════════════════╝

ATAC-Seq Analysis Pipeline

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
  * hs1           [Human T2T-CHM13]
  * hs1_chrR      [Human T2T-CHM13 + chrR rDNA unit]

aspen calls peaks using the following tools:

 * MACS2
 * Genrich        [RECOMMENDED FOR USE]

USAGE:
  bash /data/CCBR_Pipeliner/Pipelines/ASPEN/release/1.3.0/aspen -w/--workdir=<WORKDIR> -m/--runmode=<RUNMODE>

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
  bash /data/CCBR_Pipeliner/Pipelines/ASPEN/release/1.3.0/aspen -w=/my/output/folder -m=init
  bash /data/CCBR_Pipeliner/Pipelines/ASPEN/release/1.3.0/aspen -w=/my/output/folder -m=dryrun
  bash /data/CCBR_Pipeliner/Pipelines/ASPEN/release/1.3.0/aspen -w=/my/output/folder -m=run

##########################################################################################

VersionInfo:
  python          : python/3.10
  snakemake       : snakemake
  pipeline_home   : /data/CCBR_Pipeliner/Pipelines/ASPEN/release/1.3.0
  git commit/tag  : 8d197d39927be3f60558911bd8b2756f36835deb    v1.3.0
  aspen_version   : v1.3.0

##########################################################################################
```

Visit ASPEN [documentation](https://ccbr.github.io/ASPEN/) for details.

For comments/suggestions/advice please reach out to [Vishal Koparde](mailto:vishal.koparde@nih.gov) or [CCBR_Pipeliner](mailto:CCBR_Pipeliner@mail.nih.gov). You can also open a new issue [here](https://github.com/CCBR/ASPEN/issues).

<hr>
<p align="center">
	<a href="#aspen">Back to Top</a>
</p>

<hr>
