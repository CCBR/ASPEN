## ASPEN development version

- Fix broken data path for biowulf. (#104, @kelly-sovacool)
- Remove deprecated `ccr` partition. (#106, @kelly-sovacool)

## ASPEN 1.1.1

- Fix Diffatac error (#101, @kopardev)
  - Adds a defensive check to prevent invalid 'row.names' length error when up_roi or down_roi are empty (due to strict FC/FDR thresholds in DiffATAC)
- Minor refactoring to accommodate moving to ccbr_tools >= v0.4 (#101, @kopardev)

## ASPEN 1.1.0

This version features a major overhaul of the pipeline with changes in the following areas:

### Spike-in alignment (#94, @kopardev)

- Added support for spike-in alignment and scaling factor computation. (#94, @kopardev)
- This new feature is controlled by two new parameters in the config file: `spikein` and `spikein_genome`. (#69)

### Peak-calling (#94, @kopardev)

- Peak-called narrowPeak files are now q-value filtered by default, with a default q-value threshold of 0.1. Unfiltered files are still available for users who want to apply their own filters. (#90)
- Streamlined the output directory structure.
- Added the name of the peak-caller to ROI filenames (#86)
- Added missing annotations (#79)

### Differential accessibility (#94, @kopardev)

- Add new rules for scaling counts and annotating regions of interest. (#68)
- DiffATAC analysis is now run for both MACS2 and Genrich peak calls, with results stored in separate directories.
- DiffATAC analysis now includes spike-in scaling factors when `spikein` is `TRUE`.
- Removed redundant steps in the differential accessibility analysis to streamline the process.
- create Tn5-based and reads-based counts matrices (#67)
- create spike-in scaled counts matrices (#62)
- Quality control
  - Updated FRiP calculation to use `tagAlign.gz` files instead of deduplicated BAM files.
  - Removed unnecessary QC metrics and simplified the QC workflow.
  - Updated TSS enrichment and fragment length distribution rules to align with the simplified pipeline structure.

### Output directory (#94, @kopardev)

- Consolidated peak calling outputs into a single directory for each peak caller. (#91)
- Simplified the output directory structure. (#92)
- Decreased output digital footprint by removing unwanted intermediate files, gzipping annotated files, etc. (#87)
- Improved slurm job logging with jobby (now depends on ccbr_tools v0.4). (#98, @kelly-sovacool)

### Documentation (#94, @kopardev)

- Simplified the documentation to focus on the core functionalities of the pipeline, as well as reflect all of the changes in this version.

## ASPEN 1.0.6

- fix: dockername typo ([#57](https://github.com/CCBR/ASPEN/issues/57), @kopardev)
- docs: update documentation, change theme ([#77](https://github.com/CCBR/ASPEN/issues/77), [#78](https://github.com/CCBR/ASPEN/issues/78), @kopardev)

## ASPEN 1.0.5

- fix: ucsc tool version changed requiring newer version of GLIBC ([#54](https://github.com/CCBR/ASPEN/issues/54), @kopardev)
- using new masterdocker v11

## ASPEN 1.0.4

- fix: DiffATAC failure ([#46](https://github.com/CCBR/ASPEN/issues/46), @kopardev)
- fix: last line of `contrasts.tsv` read in correctly; black lines ignored ([#48](https://github.com/CCBR/ASPEN/issues/48), @kopardev)
- fix: ROI calculation from fixed-width consensus peaks no longer tried to fix the peak width again ([#50](https://github.com/CCBR/ASPEN/issues/50), @kopardev)
- feature: create diffatac results from MACS2 peaks ([#51](https://github.com/CCBR/ASPEN/issues/51), @kopardev)
- fix: `BUYINPARTITIONS` fixed in wrapper for BIOWULF-only ([#52](https://github.com/CCBR/ASPEN/issues/52), @kopardev)

## ASPEN 1.0.3

- fix: No module named 'numpy.\_core.\_multiarray_umath' error with`unset PYTHONPATH` ([#43](https://github.com/CCBR/ASPEN/issues/43), @kopardev)
- fix: jobby command points to the correct location of snakemake.log file
- ASPEN is now archived on Zenodo, you can cite it with the DOI [10.5281/zenodo.13755867](https://doi.org/10.5281/zenodo.13755867). ([#42](https://github.com/CCBR/ASPEN/issues/42), @kelly-sovacool)

## ASPEN 1.0.2

- Set the singularity cache dir if `--singcache` is not provided. ([#37](https://github.com/CCBR/ASPEN/pull/37), @kelly-sovacool)
- ASPEN now has a documentation website: <https://ccbr.github.io/ASPEN>

## ASPEN 1.0.1

- differential ATAC updated
- documentation updated

## ASPEN 1.0.0

- completely dockerized
- differential ATAC

## ASPEN 0.6.1

- correction to fqscreen cattle path

## ASPEN 0.6

- support for mmul10 (Macaca) and bosTau9 (cattle) genomes
  - created resource files: indexes, promoter files, tss files etc.
- Added Macaca and Cattle to fastqscreen indexes
- support increased from 4 replicate to 6 replicates
- macs and genrich fixed width peaks generation rule added
- docker updated to v10 (genome support and tidyverse added)

## ASPEN 0.5.3

- Includes reference files for mmul10

## ASPEN 0.5.2

- atac_assign_multimappers.py now getting query sorted input
- dryrun log saved in workdir
- local (workdir) scriptsdir used

## ASPEN 0.5.1

- typo fix in main wrapper script

## ASPEN 0.5

- fastqscreen added
- minor bug fixes

## ASPEN 0.4.1

- Bug fixes
- minor updates

## ASPEN 0.4

- Multiqc edits
- README updates

## ASPEN 0.3

- FRiP calculations added

## ASPEN 0.2

- Peak motif enrichment with homer/meme
- Peak replicate/sample/peakcaller PCA comparisons after bedtools jaccard pairwise calculations

## ASPEN 0.1

- first working version
- calls peaks with macs2/genrich
- annotates peaks with chipseeker (human and mouse support)
