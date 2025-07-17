## Config files

- `config.yaml`: sets all the runtime configurations for the pipeline like output folder, resources folder, genome, tool-parameters etc.
- `samples.tsv`: tab delimited sample manifest. Defaults to the samples in the .test folder of the pipeline
- `multiqc_atacseq_config.yaml`: custom-multiqc config file for report generation
- `create_test_config_sample_manifest_files.bash`: replicates variables `PIPELINE_HOME` and `WORKDIR` etc. to create sample manifest for testing purposes
