# ASPEN

**A**tac **S**eq **P**ip**E**li**N**e :

[CCBR](https://bioinformatics.ccr.cancer.gov/ccbr/) recommends ASPEN to effectively analyze ATAC-seq datasets on the [BIOWULF](https://hpc.nih.gov) HPC system at the [NIH](https://www.nih.gov/).

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.13755867.svg)](https://doi.org/10.5281/zenodo.13755867)
[![release](https://img.shields.io/github/v/release/CCBR/ASPEN?color=blue&label=latest%20release)](https://github.com/CCBR/ASPEN/releases/latest)

## QuickStart guide

```bash
module load ccbrpipeliner/7
```

```bash
aspen --help
```

```bash
##########################################################################################

Welcome to
____ ____ ___  ____ _  _
|__| [__  |__] |___ |\ |
|  | ___] |    |___ | \|    v1.0.6

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
  bash /gpfs/gsfs10/users/CCBR_Pipeliner/Pipelines/ASPEN/.v1.0.6/aspen -w/--workdir=<WORKDIR> -m/--runmode=<RUNMODE>

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
  bash /gpfs/gsfs10/users/CCBR_Pipeliner/Pipelines/ASPEN/.v1.0.6/aspen -w=/my/output/folder -m=init
  bash /gpfs/gsfs10/users/CCBR_Pipeliner/Pipelines/ASPEN/.v1.0.6/aspen -w=/my/output/folder -m=dryrun
  bash /gpfs/gsfs10/users/CCBR_Pipeliner/Pipelines/ASPEN/.v1.0.6/aspen -w=/my/output/folder -m=run

##########################################################################################

VersionInfo:
  python          : python/3.10
  snakemake       : snakemake
  pipeline_home   : /gpfs/gsfs10/users/CCBR_Pipeliner/Pipelines/ASPEN/.v1.0.6
  git commit/tag  : f4366158ad972bc667422dcd4783bd69fa041556    v1.0.6
  aspen_version   : v1.0.6

##########################################################################################
```

Visit ASPEN [documentation](https://ccbr.github.io/ASPEN/) for details.

For comments/suggestions/advice please reach out to [Vishal Koparde](mailto:vishal.koparde@nih.gov) or [CCBR_Pipeliner](mailto:CCBR_Pipeliner@mail.nih.gov). You can also open a new issue [here](https://github.com/CCBR/ASPEN/issues).

<hr>
<p align="center">
	<a href="#aspen">Back to Top</a>
</p>

<hr>
