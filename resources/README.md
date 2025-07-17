## Resources

This folder, `resources/`, is meant to contain all resources (except larger genome indexes) necessary for running the workflow. The subfolders are:

- **blacklistFa**: Blacklist BED files are downloaded for human (v3) and mouse (v1). Using the coordinates from these BED files, fasta sequences are extracted for hg19/39 and mm10.
- **frip**: BED files for DHS/enhancer/promoter locations for hg19/39 and mm10 genomes.
- **motif**: HOCOMOCO v11 motifs in HOMER and MEME formats for human and mouse.
- **tssBed**: BED files pin-pointing the transcription start sites of annotated genes for hg19/38 and mm10.

`cluster.json` file can make specific resource requests to biowulf via slurm. Each Snakemake rule can make a unique hardware request for slurm execution.

`tools.yaml` file would typically contain the modules required to be loaded for rule execution on the Biowulf cluster. Since we are using dockers for all rules in this pipeline, `tools.yaml` will be empty.
