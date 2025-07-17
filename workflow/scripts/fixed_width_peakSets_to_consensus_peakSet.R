#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("argparse"))

# create parser object
parser <- ArgumentParser(description="Convert narrowPeak output to fixedwidth peakset as per the pan-cancer genome paper (https://doi.org/10.1126/science.aav1898) using the script narrowPeak_to_fixed_width_peakSet.R. This involves ...First, all replicate peak sets are combined into a cumulative peak set and trimmed for overlap using the same iterative procedure as narrowPeak_to_fixed_width_peakSet, i.e, keep the most significant (based of score per million or normalized p-value) peak and discards any peak that overlaps directly with the most significant peak. To identify reproducible peaks from this merged peak set, the individual replicate peak sets were overlapped with the merged peak set. Peaks from the merged peak set that were observed in at least 2(minReps) samples with a score per million value >=5(cutoffSPM) were labeled as reproducible and reported in the output narrowPeak file. NOTE: this script requires bedtools to be in the PATH")

# specify our desired options
# by default ArgumentParser will add a help option
parser$add_argument("-i", "--inputNarrowPeaks",
          type="character",
          help="absolute fullpaths to fixed width narrowPeak input files from narrowPeak_to_fixed_width_peakSet.R",
          required=TRUE)
parser$add_argument("-p", "--inputPrefixes",
          type="character",
          help="prefixes to be added to the peaknames from the inputNarrowPeaks to avoid name clashes",
          required=TRUE)
parser$add_argument("-o", "--outputNarrowPeak",
          type="character",
          help="absolute fullpath to narrowPeak output file",
          required=TRUE)
parser$add_argument("-t", "--tmpdir",
          type="character",
          help="tmp dir",
          required=FALSE,
          default=NULL)
parser$add_argument("-m", "--minReps",
          type="integer",
          help="minimum replicates that need to overlap for any peak to be considered a consensus peak",
          required=FALSE,
          default=2)
parser$add_argument("-c", "--cutoffSPM",
          type="integer",
          help="cutoff score per million or normalized p-value. All minimum number of replicate peaks that need to overlap with a consensus peak should also be greater than this cutoff score per million or SPM",
          required=FALSE,
          default=5)

# parse arguments
args <- parser$parse_args()

# set thresholds from arguments
norm_pvalue_threshold=args$cutoffSPM
min_replicates=args$minReps

suppressPackageStartupMessages(library("tidyverse"))

debug=0

# split input arguments into lists
narrowPeaks=unlist(strsplit(args$inputNarrowPeak,","))
prefixes=unlist(strsplit(args$inputPrefixes,","))
out_narrowPeak=args$outputNarrowPeak

# debug mode settings
if (debug==1){
  narrowPeaks=unlist(strsplit("/Volumes/Ambs_ATACseq/analysis/project1/CCBR_ATACseq_102621/results/peaks/genrich/fixed_width_peaks/HCC2157_1.genrich.samplePeakSet.narrowPeak,/Volumes/Ambs_ATACseq/analysis/project1/CCBR_ATACseq_102621/results/peaks/genrich/fixed_width_peaks/HCC2157_2.genrich.samplePeakSet.narrowPeak",","))
  prefixes=unlist(strsplit("HCC2157_1,HCC2157_2",","))
  out_narrowPeak="HCC2157.genrich.consensus.narrowPeak"
  setwd(dirname(out_narrowPeak))
  norm_pvalue_threshold=5
  min_replicates=2
} else {
  if(is.null(args$tmpdir)){
  tmpdir=setwd(dirname(out_narrowPeak))
  } else {
  tmpdir=args$tmpdir
  }
  setwd(tmpdir)
}

bn=basename(out_narrowPeak)

# function to read narrowPeak files
readnarrowpeak<-function(narrowPeak,prefix){
  x=read.csv(narrowPeak,
       header=FALSE,
       sep = "\t",
       check.names = FALSE,
       strip.white = TRUE
  )

  colnames(x)=c("chrom",
        "start",
        "end",
        "peakname",
        "score",
        "strand",
        "signalValue",
        "normalizedpvalue",
        "qvalue",
        "summitdist")
  x$peakname=paste(prefix,x$peakname,sep="_")
  return(x)
}

# read the first narrowPeak file
xdf <- readnarrowpeak(narrowPeaks[1],prefixes[1])

# read and combine the rest of the narrowPeak files
for (i in 2:length(narrowPeaks)) {
  xdf2=readnarrowpeak(narrowPeaks[i],prefixes[i])
  xdf=rbind(xdf,xdf2)
}

# create temporary file names
tmp1bed=paste(bn,"tmp1.bed",sep=".")
tmp=paste(bn,"tmp",sep=".")

# convert columns to integer and sort by normalized p-value
mutate_at(xdf,vars("start","end","summitdist"),as.integer) -> xdf
arrange(xdf,desc(normalizedpvalue)) -> xdf
xdf %>% mutate(rank=row_number()) -> xdf

# write the combined peaks to a temporary file
write.table(xdf,file=tmp1bed,
      sep="\t",
      row.names = FALSE,
      col.names = FALSE,
      quote = FALSE)

# run bedtools intersect to find overlapping peaks
cmd=paste("bedtools intersect -wa -wb -a",tmp1bed,"-b",tmp1bed,">",tmp)
print(cmd)
system(cmd)

# read the intersected peaks
x2=read.csv(tmp,
       header=FALSE,
       sep = "\t",
       check.names = FALSE,
       strip.white = TRUE
)
colnames(x2)=c("chrom",
        "start",
        "end",
        "peakname",
        "score",
        "strand",
        "signalValue",
        "normalizedpvalue",
        "qvalue",
        "summitdist",
        "rank",
        "chrom2",
        "start2",
        "end2",
        "peakname2",
        "score2",
        "strand2",
        "signalValue2",
        "normalizedpvalue2",
        "qvalue2",
        "summitdist2",
        "rankb")

# determine which peaks to keep and which to remove
keep1_ranks=x2[x2$rank==x2$rankb,]$rank
remove_ranks=x2[x2$rank<x2$rankb,]$rankb
keep_ranks=setdiff(keep1_ranks,remove_ranks)

# filter the peaks to keep
xdf2=xdf[xdf$rank %in% keep_ranks,]

xdf2=xdf2[,c("chrom",
          "start",
          "end",
          "peakname",
          "score",
          "strand",
          "signalValue",
          "normalizedpvalue",
          "qvalue",
          "summitdist")]

# create another temporary file name
tmp2bed=paste(bn,"tmp2.bed",sep=".")
mutate_at(xdf2,vars("start","end","summitdist"),as.integer) -> xdf2

# write the filtered peaks to a temporary file
write.table(xdf2,file=tmp2bed,
      sep="\t",
      row.names = FALSE,
      col.names = FALSE,
      quote = FALSE)

# initialize a data frame to count overlaps
peaksoverlapcount=data.frame(peakname=xdf2$peakname,count=0)

# count overlaps for each narrowPeak file
for (i in 1:length(narrowPeaks)) {
  cmd=paste("bedtools intersect -wa -wb -a",tmp2bed,"-b",narrowPeaks[i],">",tmp)
  print(cmd)
  system(cmd)
  x2=read.csv(tmp,
        header=FALSE,
        sep = "\t",
        check.names = FALSE,
        strip.white = TRUE
  )
  colnames(x2)=c("chrom",
         "start",
         "end",
         "peakname",
         "score",
         "strand",
         "signalValue",
         "normalizedpvalue",
         "qvalue",
         "summitdist",
         "chrom2",
         "start2",
         "end2",
         "peakname2",
         "score2",
         "strand2",
         "signalValue2",
         "normalizedpvalue2",
         "qvalue2",
         "summitdist2")
  x2[x2$normalizedpvalue2>norm_pvalue_threshold,]->x2
  update_peaks=peaksoverlapcount$peakname %in% x2$peakname
  peaksoverlapcount[update_peaks, "count"] <- 1 + peaksoverlapcount[update_peaks, "count"]

  system(paste("rm -f",tmp))
}

# filter peaks based on overlap count
keep_peaks=peaksoverlapcount[peaksoverlapcount$count >= min_replicates,]$peakname
xdf3=xdf2[xdf2$peakname %in% keep_peaks,]
xdf3$score=peaksoverlapcount[peaksoverlapcount$peakname %in% keep_peaks,]$count
mutate_at(xdf3,vars("start","end","summitdist"),as.integer) -> xdf3

# write the final consensus peaks to the output file
write.table(xdf3,file=out_narrowPeak,
      sep="\t",
      row.names = FALSE,
      col.names = FALSE,
      quote = FALSE)

# clean up temporary files
system(paste("rm -f",tmp1bed,tmp2bed))
