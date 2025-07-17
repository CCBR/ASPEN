import sys


def get_scaling_factor(sample_name):
    for line in sys.stdin:
        parts = line.strip().split("\t")
        if len(parts) < 3:
            continue  # Skip malformed lines
        if parts[0] == sample_name:
            print(parts[2])  # Print only the scaling factor
            return

    print(f"Sample {sample_name} not found.", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(
            "Usage: cat scaling_factors.tsv | python _print_replicate_scaling_factor.py <sample_name>",
            file=sys.stderr,
        )
        sys.exit(1)

    sample_name = sys.argv[1]
    get_scaling_factor(sample_name)
