import sys

# Read input from stdin
data = [line.strip().split("\t") for line in sys.stdin]

# Convert second column to integers
for row in data:
    row[1] = int(row[1])

# Fail loudly and clearly if any replicate has 0 spike-in reads, rather than
# letting the division below raise an opaque ZeroDivisionError.
zero_count_replicates = [row[0] for row in data if row[1] == 0]
if zero_count_replicates:
    sys.exit(
        "ERROR: the following replicate(s) have 0 reads aligned to the "
        f"spike-in genome: {', '.join(zero_count_replicates)}.\n"
        "Spike-in scaling factors cannot be computed. This usually means "
        "either (a) the spike-in material was not actually present in this "
        "library, (b) the spike-in genome/index is misconfigured, or (c) "
        "this sample should not use spike-in normalization at all.\n"
        "Fix by verifying the spike-in genome/index path in config.yaml, "
        "confirming spike-in was added during library prep, or excluding "
        "this replicate / setting `spikein: false` if none of your samples "
        "have spike-in material."
    )

# Find the smallest value in column 2
min_value = min(row[1] for row in data)

# Compute scaling factors and print results
for row in data:
    scaling_factor = min_value / row[1]
    print(f"{row[0]}\t{row[1]}\t{scaling_factor:.6f}")
