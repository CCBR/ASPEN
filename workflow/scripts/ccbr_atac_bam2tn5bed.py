import pysam
import argparse
import sys


def parse_genome_sizes(genome_file):
    """Parse a UCSC-style genome sizes file into a chromosome length dictionary."""
    chrom_sizes = {}
    with open(genome_file, "r") as handle:
        for line_no, line in enumerate(handle, start=1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            fields = line.split()
            if len(fields) < 2:
                raise ValueError(
                    f"Malformed genome sizes line {line_no} in {genome_file}: {line}"
                )

            chrom = fields[0]
            try:
                chrom_len = int(fields[1])
            except ValueError as err:
                raise ValueError(
                    f"Invalid chromosome length at line {line_no} in {genome_file}: {fields[1]}"
                ) from err

            if chrom_len <= 0:
                raise ValueError(
                    f"Chromosome length must be > 0 at line {line_no} in {genome_file}"
                )

            if chrom in chrom_sizes and chrom_sizes[chrom] != chrom_len:
                raise ValueError(
                    f"Conflicting sizes for {chrom} in {genome_file}: "
                    f"{chrom_sizes[chrom]} vs {chrom_len}"
                )

            chrom_sizes[chrom] = chrom_len

    if not chrom_sizes:
        raise ValueError(f"No chromosome sizes parsed from {genome_file}")

    return chrom_sizes


def clamp_interval(start, end, chrom_len):
    """Clamp an interval to [0, chrom_len] and report if clipping happened."""
    original_start = start
    original_end = end
    start = max(0, min(start, chrom_len))
    end = max(0, min(end, chrom_len))
    clipped = (start != original_start) or (end != original_end)
    return start, end, clipped


def tn5_cutsite(read):
    """Return strand-aware Tn5 cutsite using ATAC shift convention (+4/-5)."""
    if read.is_reverse:
        return read.reference_end - 5
    return read.reference_start + 4


def extract_fragments(input_bam, output_tn5, output_reads, threads, chrom_sizes):
    # Open the input BAM file with multiple threads
    bamfile = pysam.AlignmentFile(input_bam, "rb", threads=threads)

    counters = {
        "pairs_seen": 0,
        "pairs_written": 0,
        "pairs_skipped": 0,
        "unknown_chrom": 0,
        "tn5_clipped": 0,
        "tn5_skipped": 0,
        "reads_clipped": 0,
        "reads_skipped": 0,
    }

    with open(output_tn5, "w") as tn5bedoutfile, open(
        output_reads, "w"
    ) as readsoutfile:
        prev_read = None  # Store Read1

        for read in bamfile.fetch(until_eof=True):  # Iterate without index lookup
            if not read.is_proper_pair:
                continue  # Skip unpaired reads

            if prev_read and prev_read.query_name == read.query_name:
                counters["pairs_seen"] += 1

                # Assign Read1 and Read2 correctly
                read1, read2 = (
                    (prev_read, read) if prev_read.is_read1 else (read, prev_read)
                )

                # Skip unmapped, secondary, or supplementary alignments
                if (
                    read1.is_unmapped
                    or read2.is_unmapped
                    or read1.is_secondary
                    or read2.is_secondary
                    or read1.is_supplementary
                    or read2.is_supplementary
                ):
                    counters["pairs_skipped"] += 1
                    prev_read = None
                    continue

                # Ensure both reads are on the same chromosome
                if read1.reference_id != read2.reference_id:
                    counters["pairs_skipped"] += 1
                    prev_read = None
                    continue

                chrom = read1.reference_name
                chrom_len = chrom_sizes.get(chrom)
                if chrom_len is None:
                    counters["unknown_chrom"] += 1
                    counters["pairs_skipped"] += 1
                    prev_read = None
                    continue

                # Determine strand information
                read1_strand = "+" if not read1.is_reverse else "-"
                read2_strand = "+" if not read2.is_reverse else "-"

                read_name = read1.query_name
                tn5_entries = [
                    (tn5_cutsite(read1), read1_strand, f"{read_name}_r1"),
                    (tn5_cutsite(read2), read2_strand, f"{read_name}_r2"),
                ]

                tn5_valid = True
                for cutsite, strand, entry_name in tn5_entries:
                    original_cutsite = cutsite
                    cutsite = max(0, min(cutsite, chrom_len - 1))
                    if cutsite != original_cutsite:
                        counters["tn5_clipped"] += 1
                    start = cutsite
                    end = cutsite + 1
                    if end <= start:
                        counters["tn5_skipped"] += 1
                        tn5_valid = False
                        break
                    tn5bedoutfile.write(
                        f"{chrom}\t{start}\t{end}\t{entry_name}\t.\t{strand}\n"
                    )

                if not tn5_valid:
                    counters["pairs_skipped"] += 1
                    prev_read = None
                    continue

                # Adjust Read1 and Read2 positions for output
                read1_start, read1_end = read1.reference_start, read1.reference_end
                read2_start, read2_end = read2.reference_start, read2.reference_end

                if not read1.is_reverse:
                    read1_start += 4
                else:
                    read1_end -= 5

                if not read2.is_reverse:
                    read2_start += 4
                else:
                    read2_end -= 5

                read1_start, read1_end, clipped1 = clamp_interval(
                    read1_start, read1_end, chrom_len
                )
                read2_start, read2_end, clipped2 = clamp_interval(
                    read2_start, read2_end, chrom_len
                )
                if clipped1:
                    counters["reads_clipped"] += 1
                if clipped2:
                    counters["reads_clipped"] += 1

                if read1_end <= read1_start or read2_end <= read2_start:
                    counters["reads_skipped"] += 1
                    counters["pairs_skipped"] += 1
                    prev_read = None
                    continue

                # Write Read1 and Read2 positions to file
                readsoutfile.write(
                    f"{read1.reference_name}\t{read1_start}\t{read1_end}\t{read_name}_{read1_strand}\t.\t{read1_strand}\n"
                )
                readsoutfile.write(
                    f"{read2.reference_name}\t{read2_start}\t{read2_end}\t{read_name}_{read2_strand}\t.\t{read2_strand}\n"
                )
                counters["pairs_written"] += 1

                prev_read = None  # Reset for next read pair
            else:
                prev_read = read  # Store Read1 for next iteration

    bamfile.close()
    print(
        "[ccbr_atac_bam2tn5bed] "
        f"pairs_seen={counters['pairs_seen']} "
        f"pairs_written={counters['pairs_written']} "
        f"pairs_skipped={counters['pairs_skipped']} "
        f"unknown_chrom={counters['unknown_chrom']} "
        f"tn5_clipped={counters['tn5_clipped']} "
        f"tn5_skipped={counters['tn5_skipped']} "
        f"reads_clipped={counters['reads_clipped']} "
        f"reads_skipped={counters['reads_skipped']}",
        file=sys.stderr,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Extract Tn5 fragment sites and reads from a BAM file."
    )
    parser.add_argument(
        "-i", "--bam", required=True, help="Input BAM file (query-name sorted)"
    )
    parser.add_argument(
        "-t", "--tn5bed", required=True, help="Output Tn5 insertion sites BED file"
    )
    parser.add_argument("-b", "--readsbed", required=True, help="Output reads BED file")
    parser.add_argument(
        "-g",
        "--genomefile",
        required=True,
        help="Genome sizes file with chromosome lengths",
    )
    parser.add_argument(
        "-n",
        "--ncpus",
        required=False,
        type=int,
        default=2,
        help="Number of CPUs to use",
    )
    args = parser.parse_args()
    genome_sizes = parse_genome_sizes(args.genomefile)
    extract_fragments(args.bam, args.tn5bed, args.readsbed, args.ncpus, genome_sizes)
