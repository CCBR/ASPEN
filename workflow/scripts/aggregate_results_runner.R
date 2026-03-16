#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("argparse"))


# create parser object
parser <- ArgumentParser(description = "Wrapper for running aggregate_results.Rmd")


parser$add_argument("-m", "--countsmatrix",
  type = "character",
  help = "path to countsmatrix",
  required = TRUE
)
parser$add_argument("-a", "--diffatacdir",
  type = "character",
  help = "diff atac dir",
  required = TRUE
)
parser$add_argument("-c", "--coldata",
  type = "character",
  help = "coldata or sampleinto TSV file",
  required = TRUE
)
parser$add_argument("-f", "--foldchange",
  type = "double",
  help = "log2FC threshold",
  required = FALSE,
  default = 2.0
)
parser$add_argument("-p", "--fdr",
  type = "double",
  help = "adj. p-value threshold",
  required = FALSE,
  default = 0.05
)
parser$add_argument("-i", "--indexcols",
  type = "character",
  help = "comma-separated list of index columns",
  required = TRUE
)
parser$add_argument("-e", "--excludecols",
  type = "character",
  help = "comma-separated list of columns to exclude",
  required = TRUE
)
parser$add_argument("-t", "--tmpdir",
  type = "character",
  help = "temp dir",
  required = FALSE,
  default = "/tmp"
)
parser$add_argument("-s", "--scriptsdir",
  type = "character",
  help = "scripts dir",
  required = TRUE
)

args <- parser$parse_args()

# check inputs
for (f in c(args$countmatrix, args$coldata)) {
  if (!file.exists(f)) {
    outstr <- paste("ERROR: File: ", f, "Does not exists!")
    message(outstr)
    quit(status = 1)
  }
  if (file.access(f, mode = 4) != 0) {
    outstr <- paste("ERROR: File: ", f, "is not readable!")
    message(outstr)
    quit(status = 1)
  }
}
setwd(args$diffatacdir)


outprefix <- "all_diff_atacs"
outhtml <- paste0(args$diffatacdir, "/", outprefix, ".html")
outtsv <- paste0(args$diffatacdir, "/", outprefix, ".tsv")

myparams <- list(
  rawcountsmatrix = args$countsmatrix,
  coldata = args$coldata,
  FC_cutoff = args$foldchange,
  FDR_cutoff = args$fdr,
  diffatacdir = args$diffatacdir,
  indexcols = args$indexcols,
  excludecols = args$excludecols,
  outtsv = outtsv
)

rmarkdown::render(paste(args$scriptsdir, "aggregate_results.Rmd", sep = "/"),
  params = myparams,
  output_file = outhtml,
  intermediates_dir = args$tmpdir
)
