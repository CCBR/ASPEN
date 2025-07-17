import pysam
import argparse


def extract_fragments(input_bam, output_tn5, output_reads, threads):
    # Open the input BAM file with multiple threads
    bamfile = pysam.AlignmentFile(input_bam, "rb", threads=threads)

    with open(output_tn5, "w") as tn5bedoutfile, open(
        output_reads, "w"
    ) as readsoutfile:
        prev_read = None  # Store Read1

        for read in bamfile.fetch(until_eof=True):  # Iterate without index lookup
            if not read.is_proper_pair:
                continue  # Skip unpaired reads

            if prev_read and prev_read.query_name == read.query_name:
                # Assign Read1 and Read2 correctly
                read1, read2 = (
                    (prev_read, read) if prev_read.is_read1 else (read, prev_read)
                )

                # Ensure both reads are on the same chromosome
                if read1.reference_id != read2.reference_id:
                    prev_read = None
                    continue

                # Compute fragment boundaries
                start = min(read1.reference_start, read2.reference_start)
                end = max(read1.reference_end, read2.reference_end)

                # Adjust Tn5 insertion sites
                start += 4 if not read1.is_reverse else -5
                end += 4 if not read2.is_reverse else -5

                # Determine strand information
                read1_strand = "+" if not read1.is_reverse else "-"
                read2_strand = "+" if not read2.is_reverse else "-"

                read_name = read1.query_name
                tn5bedoutfile.write(
                    f"{read1.reference_name}\t{start}\t{start+1}\t{read_name}_+\t.\t+\n"
                )
                tn5bedoutfile.write(
                    f"{read1.reference_name}\t{end}\t{end+1}\t{read_name}_-\t.\t-\n"
                )

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

                # Write Read1 and Read2 positions to file
                readsoutfile.write(
                    f"{read1.reference_name}\t{read1_start}\t{read1_end}\t{read_name}_{read1_strand}\t.\t{read1_strand}\n"
                )
                readsoutfile.write(
                    f"{read2.reference_name}\t{read2_start}\t{read2_end}\t{read_name}_{read2_strand}\t.\t{read2_strand}\n"
                )

                prev_read = None  # Reset for next read pair
            else:
                prev_read = read  # Store Read1 for next iteration

    bamfile.close()


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
        "-n", "--ncpus", required=False, default=2, help="Number of CPUs to use"
    )
    args = parser.parse_args()
    extract_fragments(args.bam, args.tn5bed, args.readsbed, args.ncpus)
