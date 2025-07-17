#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("argparse"))

# create parser object
parser <- ArgumentParser(description="This script can be used to normalize p-values of individual peaks so that replicates and sample with different read-depths and number of peaks can be directly compared with each other as per the pan-cancer genome paper (https://doi.org/10.1126/science.aav1898). To normalize, the peak scores (-log10(p-value)) for each sample were converted to a score per million by dividing each individual peak score by the sum of all of the peak scores in the given sample divided by 1 million.")

# specify our desired options
# by default ArgumentParser will add an help option

parser$add_argument("-i", "--inputNarrowPeak",
                    type="character",
                    help="narrowPeak input file",
                    required=TRUE)
parser$add_argument("-o", "--outputNarrowPeak",
                    type="character",
                    help="narrowPeak output file",
                    required=FALSE,
                    default=NULL)


args <- parser$parse_args()
suppressPackageStartupMessages(library("tidyverse"))

debug=0

narrowPeak=args$inputNarrowPeak

if (debug==1){
narrowPeak="/Volumes/Ambs_ATACseq/analysis/project1/CCBR_ATACseq_102621/results/peaks/genrich/uniform_width_peaks/HCC2157_1.genrich.narrowPeak"
out_narrowPeak=gsub("narrowPeak$","pvalue_normalized.narrowPeak",narrowPeak)
setwd(dirname(narrowPeak))
} else {
  if(is.null(args$outputNarrowPeak)){
    out_narrowPeak=gsub("narrowPeak$","pvalue_normalized.narrowPeak",narrowPeak)
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


x=read.csv(narrowPeak,
           header=FALSE,
           sep = "\t",
           check.names = FALSE,
           strip.white = TRUE
          )
# head(x)
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
x$normalized_pvalue=x$pvalue/sum(x$pvalue)*1e6
hist(x$normalized_pvalue)
summary(x$normalized_pvalue)
x=arrange(x,desc(normalized_pvalue),desc(signalValue))
# head(x)
x[,c("chrom","start","end","peakname","score","strand","signalValue","normalized_pvalue","qvalue","summitdist")] -> xdf
mutate_at(xdf,vars("start","end","summitdist"),as.integer) -> xdf
write.table(xdf,file=out_narrowPeak,
            sep="\t",
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)
