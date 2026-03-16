#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("argparse"))
# suppressPackageStartupMessages(library("here"))
# scriptfolder=here()


# create parser object
parser <- ArgumentParser(description = "Wrapper for running DESeq2 with ATACseq counts matrix")


parser$add_argument("-m", "--countsmatrix",
  type = "character",
  help = "path to countsmatrix",
  required = TRUE
)
parser$add_argument("-g", "--genome",
  type = "character",
  help = "genome .. either hg38 or mm10",
  required = FALSE,
  default = "hg38"
)
parser$add_argument("-c", "--coldata",
  type = "character",
  help = "coldata or sampleinto TSV file",
  required = TRUE
)
parser$add_argument("-n", "--contrastnumerator",
  type = "character",
  help = "Group1 of the contrasts",
  required = TRUE
)
parser$add_argument("-d", "--contrastdenominator",
  type = "character",
  help = "Group2 of the contrasts",
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
parser$add_argument("-o", "--outdir",
  type = "character",
  help = "output dir",
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
if (!dir.exists(args$outdir)) {
  tryCatch(
    expr = {
      dir.create(args$outdir)
    },
    error = {
      outstr <- paste("ERROR: Dir: ", args$outdir, " Cannot be created!")
      message(outstr)
      quit(status = 1)
    }
  )
}

sampleinfo <- read.csv(file = args$coldata, header = FALSE, sep = "\t", comment.char = "#", strip.white = TRUE)
colnames(sampleinfo) <- c("replicateName", "sampleName")
freq_table <- as.data.frame(table(sampleinfo$sampleName))
for (condition in c(args$contrastnumerator, args$contrastdenominator)) {
  if (!condition %in% freq_table$Var1) {
    outstr <- paste("ERROR: Condition: ", condition, "absent in ", args$coldata)
    message(outstr)
    quit(status = 1)
  }
}

outprefix <- paste0(args$contrastnumerator, "_vs_", args$contrastdenominator)
outhtml <- paste0(outprefix, ".html")
outtsv <- paste0(outprefix, ".tsv")

myparams <- list(
  rawcountsmatrix = args$countsmatrix,
  genome = args$genome,
  coldata = args$coldata,
  contrast_numerator = args$contrastnumerator,
  contrast_denominator = args$contrastdenominator,
  FC_cutoff = args$foldchange,
  FDR_cutoff = args$fdr,
  indexcols = args$indexcols,
  excludecols = args$excludecols,
  diffatactsv = paste(args$outdir, outtsv, sep = "/")
)

rmarkdown::render(paste(args$scriptsdir, "DESeq2.Rmd", sep = "/"),
  params = myparams,
  output_file = paste(args$outdir, outhtml, sep = "/"),
  intermediates_dir = args$tmpdir
)
