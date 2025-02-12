## ASPEN development version

## ASPEN development version

- ASPEN is now archived on Zenodo, you can cite it with the DOI [10.5281/zenodo.13755867](https://doi.org/10.5281/zenodo.13755867). (#42, @kelly-sovacool)

## ASPEN 1.0.2

- Set the singularity cache dir if `--singcache` is not provided. (#37, @kelly-sovacool)
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
