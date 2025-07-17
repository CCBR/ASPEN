import pandas as pd
import argparse


def main(scaling_factors_file, counts_file, output_file):
    # Read scaling factors
    scaling_factors_df = pd.read_csv(
        scaling_factors_file,
        sep="\t",
        header=None,
        names=["replicateName", "replicateReads", "scalingFactor"],
    )
    scaling_factors = dict(
        zip(scaling_factors_df["replicateName"], scaling_factors_df["scalingFactor"])
    )

    # Read counts file
    counts_df = pd.read_csv(counts_file, sep="\t")

    # List of columns to keep as-is
    fixed_columns = ["Geneid", "Chr", "Start", "End", "Strand", "Length"]

    # Apply scaling factors to replicate columns
    for col in counts_df.columns:
        if col not in fixed_columns and col in scaling_factors:
            counts_df[col] = (counts_df[col] * scaling_factors[col]).round().astype(int)

    # Write the output to a tab-delimited file
    counts_df.to_csv(output_file, sep="\t", index=False)
    print("Scaled counts written to {}".format(output_file))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Scale counts using scaling factors.")
    parser.add_argument(
        "--scaling_factors", required=True, help="Path to the scaling factors TSV file"
    )
    parser.add_argument(
        "--counts_file", required=True, help="Path to the counts TSV file"
    )
    parser.add_argument(
        "--output_file",
        required=True,
        help="Path to save the scaled counts output TSV file",
    )

    args = parser.parse_args()
    main(args.scaling_factors, args.counts_file, args.output_file)
