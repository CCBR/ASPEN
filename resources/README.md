## Resources

This folder, `resources/`, is meant to contain all resources (except larger genome indexes) necessary for running the workflow. The subfolders are:

- **blacklistFa**: Blacklist BED files are downloaded for human (v3) and mouse (v1). Using the coordinates from these BED files, fasta sequences are extracted for hg19/39 and mm10.
- **frip**: BED files for DHS/enhancer/promoter locations for hg19/39 and mm10 genomes.
- **motif**: HOCOMOCO v11 motifs in HOMER and MEME formats for human and mouse.
- **tssBed**: BED files pin-pointing the transcription start sites of annotated genes for hg19/38 and mm10.

`cluster.json` file can make specific resource requests to biowulf via slurm. ASPEN uses these values as the baseline per-rule resource settings, and the workflow now passes `resources.gres` through to Slurm so retry attempts can request more `lscratch` when a rule defines an attempt-aware `resources:` expression. In practice, this means `cluster.json` still controls the default resource profile, while the rule definitions can increase the `gres` request automatically on later Snakemake attempts.

`tools.yaml` file would typically contain the modules required to be loaded for rule execution on the Biowulf cluster. Since we are using dockers for all rules in this pipeline, `tools.yaml` will be empty.
