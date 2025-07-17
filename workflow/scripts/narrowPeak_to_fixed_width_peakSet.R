#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("argparse"))

# create parser object
parser <- ArgumentParser(description="Convert narrowPeak output to fixedwidth peakset as per the pan-cancer genome paper (https://doi.org/10.1126/science.aav1898). This involves ... First, the most significant peak is kept and any peak that directly overlaps with that significant peak is removed. Then, this process iterates to the next most significant peak and so on until all peaks have either been kept or removed due to direct overlap with a more significant peak. This prevents the removal of peaks due to daisy chaining or indirect overlap and simultaneously maintains a compendium of fixed-width peaks. The significance of each peak is determined by normalized p-values.  To normalize, the peak scores (-log10(p-value)) for each sample were converted to a score per million by dividing each individual peak score by the sum of all of the peak scores in the given sample divided by 1 million. NOTE: this script requires bedtools to be in the PATH")

# specify our desired options
# by default ArgumentParser will add an help option

parser$add_argument("-i", "--inputNarrowPeak",
          type="character",
          help="narrowPeak input file absolute full path",
          required=TRUE)
parser$add_argument("-o", "--outputNarrowPeak",
          type="character",
          help="narrowPeak output file absolute full path",
          required=FALSE,
          default=NULL)
parser$add_argument("-t", "--tmpdir",
          type="character",
          help="tmp dir",
          required=FALSE,
          default=NULL)
parser$add_argument("-w", "--peakWidth",
          type="integer",
          help="desired peak width",
          required=FALSE,
          default=500)

# parse arguments
args <- parser$parse_args()
offset <- round(args$peakWidth/2)

suppressPackageStartupMessages(library("tidyverse"))

debug=0

narrowPeak=args$inputNarrowPeak

# Debug mode settings
if (debug==1){
  narrowPeak="/Volumes/Ambs_ATACseq/analysis/project1/CCBR_ATACseq_102621/results/peaks/genrich/uniform_width_peaks/HCC2157_1.genrich.narrowPeak"
  out_narrowPeak=gsub("narrowPeak$","fixed_width.narrowPeak",narrowPeak)
  setwd(dirname(narrowPeak))
} else {
  # Set output file and temporary directory
  if(is.null(args$outputNarrowPeak)){
  out_narrowPeak=gsub("narrowPeak$","fixed_width.narrowPeak",narrowPeak)
  } else {
  out_narrowPeak=args$outputNarrowPeak
  }
  if(is.null(args$tmpdir)){
  tmpdir=setwd(dirname(narrowPeak))
  } else {
  tmpdir=args$tmpdir
  }
  setwd(tmpdir)
}
bn=basename(narrowPeak)

# Read narrowPeak file
x=read.csv(narrowPeak,
       header=FALSE,
       sep = "\t",
       check.names = FALSE,
       strip.white = TRUE
      )
# Set column names
colnames(x)=c("chrom",
        "start",
        "end",
        "peakname",
        "score",
        "strand",
        "signalValue",
        "pvalue",
        "qvalue",
        "summitdist")

# Normalize p-values
x$normalized_pvalue=x$pvalue/sum(x$pvalue)*1e6
hist(x$normalized_pvalue)

# Sort peaks by normalized p-value and signal value
x=arrange(x,desc(normalized_pvalue),desc(signalValue))

# Calculate new start and end positions
x$newstart=x$start+x$summitdist-offset
x$newend=x$start+x$summitdist+offset
x$newstart<-replace(x$newstart,x$newstart<1,1)
x %>% mutate(rank=row_number()) -> x

# Create a dataframe with selected columns
x[,c("chrom","newstart","newend","peakname","rank","strand")] %>%
  mutate_at(vars("newstart","newend","rank"),as.integer) -> xdf

# Write temporary bed file
tmp1bed=paste(bn,"tmp1.bed",sep=".")
tmp=paste(bn,"tmp",sep=".")
write.table(xdf,file=tmp1bed,
      sep="\t",
      row.names = FALSE,
      col.names = FALSE,
      quote = FALSE)

# Run bedtools intersect command
cmd=paste("bedtools intersect -wa -wb -a",tmp1bed,"-b",tmp1bed,">",tmp)
system(cmd)

# Read the intersected file
x2=read.csv(tmp,
       header=FALSE,
       sep = "\t",
       check.names = FALSE,
       strip.white = TRUE
)
colnames(x2)=c("chrom","newstart","newend","peakname","rank","strand",
         "chromb","newstartb","newendb","peaknameb","rankb","strandb")

# Determine which peaks to keep
keep1_ranks=x2[x2$rank==x2$rankb,]$rank
remove_ranks=x2[x2$rank<x2$rankb,]$rankb
keep_ranks=setdiff(keep1_ranks,remove_ranks)

# Filter peaks
xdf_filtered=xdf[xdf$rank %in% keep_ranks,]
x_filtered=x[x$peakname %in% xdf_filtered$peakname,]

# Remove temporary files
system(paste("rm -f",tmp1bed,tmp))

# Prepare final dataframe
xdf=x_filtered[c("chrom",
         "newstart",
         "newend",
         "peakname",
         "score",
         "strand",
         "signalValue",
         "normalized_pvalue",
         "qvalue")]
xdf$summitdist=offset
mutate_at(xdf,vars("newstart","newend","summitdist"),as.integer) -> xdf

# Write final output file
write.table(xdf,file=out_narrowPeak,
      sep="\t",
      row.names = FALSE,
      col.names = FALSE,
      quote = FALSE)
