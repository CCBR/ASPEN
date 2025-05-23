#########################################################
# IMPORT PYTHON LIBRARIES HERE
#########################################################
import sys
import os
import pandas as pd
import yaml
import json
import math
# import glob
# import shutil
#########################################################

print("#"*100)
print("""
THANK YOU for using:
____ ____ ___  ____ _  _
|__| [__  |__] |___ |\ |
|  | ___] |    |___ | \|
""")
print("#"*100)

#########################################################
# FILE-ACTION FUNCTIONS
#########################################################
def check_existence(filename):
  if not os.path.exists(filename):
    exit("# File: %s does not exists!"%(filename))

def check_readaccess(filename):
  check_existence(filename)
  if not os.access(filename,os.R_OK):
    exit("# File: %s exists, but cannot be read!"%(filename))

def check_writeaccess(filename):
  check_existence(filename)
  if not os.access(filename,os.W_OK):
    exit("# File: %s exists, but cannot be read!"%(filename))

def get_file_size(filename):
    filename=filename.strip()
    if check_readaccess(filename):
        return os.stat(filename).st_size
#########################################################

#########################################################
# DEFINE CONFIG FILE AND READ IT
#########################################################
CONFIGFILE = str(workflow.overwrite_configfiles[0])

# set memory limit
# used for sambamba sort, etc
MEMORYG="100G"

# read in various dirs from config file
WORKDIR=config['workdir']
RESULTSDIR=join(WORKDIR,"results")

# get scripts folder
try:
    SCRIPTSDIR = config["scriptsdir"]
except KeyError:
    SCRIPTSDIR = join(WORKDIR,"scripts")
check_existence(SCRIPTSDIR)

# get resources folder
try:
    RESOURCESDIR = config["resourcesdir"]
except KeyError:
    RESOURCESDIR = join(WORKDIR,"resources")
check_existence(RESOURCESDIR)

if not os.path.exists(join(WORKDIR,"fastqs")):
    os.mkdir(join(WORKDIR,"fastqs"))
if not os.path.exists(join(WORKDIR,"results")):
    os.mkdir(join(WORKDIR,"results"))
for f in ["samplemanifest"]:
    check_readaccess(config[f])
#########################################################


#########################################################
# CREATE SAMPLE DATAFRAME
#########################################################
# each line in the samplemanifest is a replicate
# multiple replicates belong to a sample
# currently only 1,2,3 or 4 replicates per sample is supported
manifestfile = config["samplemanifest"]
REPLICATESDF = pd.read_csv(manifestfile,sep="\t",header=0)
if len(REPLICATESDF['replicateName'].unique()) != REPLICATESDF.shape[0]:
    exit("# File: %s replicate names need to be unique"%(manifestfile))
REPLICATESDF = REPLICATESDF.set_index('replicateName')
REPLICATES = list(REPLICATESDF.index)
SAMPLES = list(REPLICATESDF.sampleName.unique())

SAMPLE2REPLICATES=dict()
for g in SAMPLES:
    SAMPLE2REPLICATES[g]=list(REPLICATESDF[REPLICATESDF['sampleName']==g].index)

print("#"*100)
print("# Checking Sample Manifest...")
print("# \tTotal Replicates in manifest : "+str(len(REPLICATES)))
print("# \tTotal Samples in manifest : "+str(len(SAMPLES)))
print("# Checking read access to raw fastqs...")

REPLICATESDF["R1"]=join(RESOURCESDIR,"dummy")
REPLICATESDF["R2"]=join(RESOURCESDIR,"dummy")
REPLICATESDF["PEorSE"]="PE"

for replicate in REPLICATES:
    R1file=REPLICATESDF["path_to_R1_fastq"][replicate]
    R2file=REPLICATESDF["path_to_R2_fastq"][replicate]
    # print(replicate,R1file,R2file)
    check_readaccess(R1file)
    R1filenewname=join(WORKDIR,"fastqs",replicate+".R1.fastq.gz")
    if not os.path.exists(R1filenewname):
        os.symlink(R1file,R1filenewname)
    REPLICATESDF.loc[[replicate],"R1"]=R1filenewname
    if str(R2file)!='nan':
        check_readaccess(R2file)
        R2filenewname=join(WORKDIR,"fastqs",replicate+".R2.fastq.gz")
        if not os.path.exists(R2filenewname):
            os.symlink(R2file,R2filenewname)
        REPLICATESDF.loc[[replicate],"R2"]=R2filenewname
    else:
# only PE samples are supported by the ATACseq pipeline at the moment
        print("# Only Paired-end samples are supported by this pipeline!")
        print("# "+config["samplemanifest"]+" is missing second fastq file for "+replicate)
        exit()
        REPLICATESDF.loc[[replicate],"PEorSE"]="SE"

print("# Read access to all raw fastqs is confirmed!")
print("#"*100)

# create a sampleinfo file
SAMPLEINFO = join(WORKDIR,"sampleinfo.txt")
cmd="cut -f1,2 "+ config["samplemanifest"] + " | tail -n +2 | sort > " + SAMPLEINFO
os.system(cmd)

# read in contrasts
print("# Checking contrasts to be run")
contrastsfileexists = False
try:
    contrastsfile=config["contrasts"]
    print("# contrasts exist in config file!")
    try:
        contrastsfileexists = os.path.exists(contrastsfile)
        print("# contrastsfileexists = ",contrastsfileexists)
        if not contrastsfileexists:
            print("# %s file does not exist. No contrasts will be run!"%(contrastsfile))
    except:
        exit("# %s file may not exist"%(contrastsfile))
except KeyError:
    print("# No contrast file provided in config. No contrasts will be run!")

PEAKCALLERS = ["genrich", "macs2"]
COUNTING_METHODS = ["tn5sites", "reads"]
if contrastsfileexists:
    check_readaccess(config["contrasts"])
    try:
        if os.stat(contrastsfile).st_size > 0:
            CONTRASTS = pd.read_csv(contrastsfile,sep="\t",header=None)

            if CONTRASTS.shape[1] != 2:
                print(contrastsfile + " is expected to have 2 tab-delimited columns: Group1 and Group2")
                exit()

            CONTRASTS.columns = ['Group1','Group2']

            # get groups in contrasts
            GROUPSINCONTRASTS = list(CONTRASTS.Group1.unique())
            GROUPSINCONTRASTS.extend(list(CONTRASTS.Group2.unique()))
            GROUPSINCONTRASTS = set(GROUPSINCONTRASTS)

            # groups should exist in the sample manifest
            for g in GROUPSINCONTRASTS:
                if not g in SAMPLES:
                    print("Group: " + g + "does not have any samples in the sample manifest: " + config["samplemanifest"])
                    exit()
                nreplicates = len(SAMPLE2REPLICATES[g])
                if nreplicates < 2:
                    print("Group: " + g + " has " + str(nreplicates) + " replicates. Only 2 or more replicates per group is supported as we are using DESeq2 for differential analysis. If you only have 1 replicate, please use MANorm outside of ASPEN.")
                    exit()

            ncontrasts = CONTRASTS.shape[0]
            print("# Number of contrasts to run: ",str(ncontrasts))
        else:
            CONTRASTS = pd.DataFrame()
            print(contrastsfile + " is empty. No contrasts will be run.")
    except OSError: # contrast file is empty!
        CONTRASTS = pd.DataFrame()
        print(contrastsfile + " is empty. No contrasts will be run.")
else:
    CONTRASTS = pd.DataFrame()
    print(contrastsfile + " is absent. No contrasts will be run.")

# print(REPLICATESDF.columns)
# print(REPLICATESDF.sampleName)
# print(SAMPLES[0])
# print(REPLICATESDF[REPLICATESDF['sampleName']==SAMPLES[0]].index)
# print(SAMPLE2REPLICATES)
# exit()

#########################################################
# READ IN TOOLS REQUIRED BY PIPELINE
# THESE INCLUDE LIST OF BIOWULF MODULES (AND THEIR VERSIONS)
# MAY BE EMPTY IF ALL TOOLS ARE DOCKERIZED
#########################################################
## Load tools from YAML file
try:
    TOOLSYAML = config["tools"]
except KeyError:
    TOOLSYAML = join(WORKDIR,"tools.yaml")
check_readaccess(TOOLSYAML)
with open(TOOLSYAML) as f:
    TOOLS = yaml.safe_load(f)
#########################################################


#########################################################
# READ CLUSTER PER-RULE REQUIREMENTS
#########################################################

## Load cluster.json
try:
    CLUSTERJSON = config["clusterjson"]
except KeyError:
    CLUSTERJSON = join(WORKDIR,"cluster.json")
check_readaccess(CLUSTERJSON)
with open(CLUSTERJSON) as json_file:
    CLUSTER = json.load(json_file)

## Create lambda functions to allow a way to insert read-in values
## as rule directives
getthreads=lambda rname:int(CLUSTER[rname]["threads"]) if rname in CLUSTER and "threads" in CLUSTER[rname] else int(CLUSTER["__default__"]["threads"])
getmemg=lambda rname:CLUSTER[rname]["mem"] if rname in CLUSTER else CLUSTER["__default__"]["mem"]
getmemG=lambda rname:getmemg(rname).replace("g","G")
#########################################################

#########################################################
# SET OTHER PIPELINE GLOBAL VARIABLES
#########################################################

print("# Pipeline Parameters:")
print("#"*100)
print("# Working dir :",WORKDIR)
print("# Results dir :",RESULTSDIR)
print("# Scripts dir :",SCRIPTSDIR)
print("# Resources dir :",RESOURCESDIR)
print("# Cluster JSON :",CLUSTERJSON)

GENOME=config["genome"]
INDEXDIR=config[GENOME]["indexdir"]
print("# Bowtie index dir:",INDEXDIR)
CHROMSFILE=config[GENOME]["chroms"]
check_readaccess(CHROMSFILE)
with open(CHROMSFILE) as f:
    CHROMS = f.readline().strip()

GENOMEFILE=join(INDEXDIR,GENOME+".genome") # genome file is required by macs2 peak calling
check_readaccess(GENOMEFILE)
print("# Genome :",GENOME)
print("# .genome :",GENOMEFILE)

GENOMEFA=join(INDEXDIR,GENOME+".fa") # genome file is required by motif enrichment rule
check_readaccess(GENOMEFA)
print("# Genome fasta:",GENOMEFA)

SPIKEINDEXDIR=""
SPIKEINGENOME=""
# check if spikein is set
if config["spikein"] == True:
    SPIKEIN=True
    try:
        SPIKEINGENOME=config["spikein_genome"]
        print("# Spike-in Genome :",SPIKEINGENOME)
    except KeyError:
        print("# spikein_genome not provided in config file!")
        exit()
    try:
        SPIKEINDEXDIR=config[SPIKEINGENOME]["indexdir"]
        print("# Spike-in indexdir :",SPIKEINDEXDIR)
    except KeyError:
        print(f"# indexdir not provided for spikein_genome ({SPIKEINGENOME}) in config file!")
        exit()
    pacfile=join(SPIKEINDEXDIR,SPIKEINGENOME+".pac")
    check_readaccess(pacfile)
else:
    SPIKEIN=False
print("# Spike-in :",SPIKEIN)
print("# Spike-in Genome :",SPIKEINGENOME) if SPIKEIN else None

# get the Genrich -E parameter
NsBed = join(INDEXDIR,GENOME+".Ns.bed.gz")
excludeBed = join(INDEXDIR,GENOME+".blacklist.bed.gz")
if os.path.exists(NsBed) and os.path.exists(excludeBed):
    GENRICH_E = "-E " + NsBed + "," + excludeBed
elif os.path.exists(excludeBed):
    GENRICH_E = "-E " + excludeBed
elif os.path.exists(NsBed):
    GENRICH_E = "-E " + NsBed
else:
    GENRICH_E = ""

genrich_qfilter = -math.log10(float(config["genrich"]["qfilter"]))
GENRICH_QFILTER = f"{genrich_qfilter:.5f}"
macs2_qfilter = -math.log10(float(config["macs2"]["qfilter"]))
MACS2_QFILTER = f"{macs2_qfilter:.5f}"

BLACKLISTFA=config[GENOME]['blacklistFa']
check_readaccess(BLACKLISTFA)
print("# Blacklist fasta:",BLACKLISTFA)

QCDIR=join(RESULTSDIR,"QC")
ALIGNDIR=join(RESULTSDIR,"alignment")
PEAKSDIR=join(RESULTSDIR,"peaks")

TSSBED=config[GENOME]["tssBed"]
check_readaccess(TSSBED)
print("# TSS BEDs :",TSSBED)

HOMERMOTIF=config[GENOME]["homermotif"]
check_readaccess(HOMERMOTIF)
print("# HOMER motifs :",HOMERMOTIF)

MEMEMOTIF=config[GENOME]["mememotif"]
check_readaccess(MEMEMOTIF)
print("# MEME motifs :",MEMEMOTIF)

FASTQ_SCREEN_CONFIG=config["fastqscreen_config"]
check_readaccess(FASTQ_SCREEN_CONFIG)
print("# FQscreen config  :",FASTQ_SCREEN_CONFIG)

try:
    JACCARD_MIN_PEAKS=int(config["jaccard_min_peaks"])
except KeyError:
    JACCARD_MIN_PEAKS=100


# FRIPEXTRA ... do you calculate extra Fraction of reads in blahblahblah
FRIPEXTRA=False

try:
    DHSBED=config[GENOME]["fripextra"]["dhsbed"]
    check_readaccess(DHSBED)
    print("# DHS motifs :",DHSBED)
    FRIPEXTRA=True
except KeyError:
    DHSBED=""

try:
    PROMOTERBED=config[GENOME]["fripextra"]["promoterbed"]
    check_readaccess(PROMOTERBED)
    print("# Promoter Bed:",PROMOTERBED)
    FRIPEXTRA=True
except KeyError:
    PROMOTERBED=""

try:
    ENHANCERBED=config[GENOME]["fripextra"]["enhancerbed"]
    check_readaccess(ENHANCERBED)
    print("# Enhancer Bed:",ENHANCERBED)
    FRIPEXTRA=True
except KeyError:
    ENHANCERBED=""

try:
    MULTIQCCONFIG=config['multiqc']['configfile']
    check_readaccess(MULTIQCCONFIG)
    print("# MultiQC configfile:",MULTIQCCONFIG)
    MULTIQCEXTRAPARAMS=config['multiqc']['extraparams']
except KeyError:
    MULTIQCCONFIG=""
    MULTIQCEXTRAPARAMS=""
print("#"*100)

#########################################################
