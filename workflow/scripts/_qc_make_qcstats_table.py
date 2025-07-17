#!/usr/bin/env python
# coding: utf-8

import pandas
from functools import reduce

dfs_to_join = []

try:
    x = pandas.read_csv("Nreads_mqc.csv", sep="\t")
    nreads = x.set_index("replicateName")
    cols = list(nreads)
    nreads["Nreads"] = nreads.loc[:, cols].sum(axis=1)
    for i in cols:
        j = i + "_perc"
        nreads[j] = nreads[i] * 100.0 / nreads["Nreads"]
    # nreads.head()
    cols2 = ["Nreads"]
    for i in cols:
        cols2.append(i)
        cols2.append(i + "_perc")
    nreads = nreads.loc[:, cols2]
    # nreads.head()
    dfs_to_join.append(nreads)
except FileNotFoundError:
    print("Nreads_mqc.csv not found!")

try:
    x = pandas.read_csv(
        "data.tss_nicking_sites.txt",
        header=None,
        sep="\t",
        names=["replicateName", "N_TSS_gt20knicks", "TSSscore"],
    )
    tss_stats = x.set_index("replicateName")
    dfs_to_join.append(tss_stats)
except FileNotFoundError:
    print("data.tss_nicking_sites.txt not found!")

try:
    x = pandas.read_csv("NRF_stats.tsv", sep="\t")
    nrf = x.set_index("replicateName")
    dfs_to_join.append(nrf)
except FileNotFoundError:
    print("NRF_stats.tsv not found!")

try:
    x = pandas.read_csv("FRiP_stats.tsv", sep="\t")
    frip = x.set_index("replicateName")
    dfs_to_join.append(frip)
except FileNotFoundError:
    print("FRiP_stats.tsv not found!")

try:
    x = pandas.read_csv("FLD_stats_peaks.tsv", sep="\t")
    fld1 = x.set_index("replicateName")
    dfs_to_join.append(fld1)
except FileNotFoundError:
    print("FLD_stats_peaks.tsv not found!")

try:
    x = pandas.read_csv("FLD_stats_fractions_ratios.tsv", sep="\t")
    fld2 = x.set_index("replicateName")
    dfs_to_join.append(fld2)
except FileNotFoundError:
    print("FLD_stats_fractions_ratios.tsv not found!")

# frip=pandas.read_csv("FRiP_stats.tsv",sep="\t")
# fld1=pandas.read_csv("FLD_stats_peaks.tsv",sep="\t")
# fld2=pandas.read_csv("FLD_stats_fractions_ratios.tsv",sep="\t")

# allstats=x.join(tss_stats.set_index("replicateName"))
# allstats=allstats.join(nrf.set_index("replicateName"))
# allstats=allstats.join(frip.set_index("replicateName"))
# allstats=allstats.join(fld1.set_index("replicateName"))
# allstats=allstats.join(fld2.set_index("replicateName"))

try:
    x = pandas.read_csv("MACS2_Peak_Annotations_mqc.csv", sep="\t")
    macs = x.set_index("replicateName")
    macs.columns = list(map(lambda z: "macs2_" + z, list(macs)))
    cols = list(macs)
    macs["macs2_Npeaks"] = macs.loc[:, cols].sum(axis=1)
    for i in cols:
        j = i + "_perc"
        macs[j] = macs[i] * 100.0 / macs["macs2_Npeaks"]
    cols2 = ["macs2_Npeaks"]
    for i in cols:
        cols2.append(i)
        cols2.append(i + "_perc")
    macs = macs.loc[:, cols2]
    dfs_to_join.append(macs)
except FileNotFoundError:
    print("MACS2_Peak_Annotations_mqc.csv not found!")


# allstats=allstats.join(x)

try:
    x = pandas.read_csv("Genrich_Peak_Annotations_mqc.csv", sep="\t")
    genrich = x.set_index("replicateName")
    genrich.columns = list(map(lambda z: "genrich_" + z, list(genrich)))
    cols = list(genrich)
    genrich["genrich_Npeaks"] = genrich.loc[:, cols].sum(axis=1)
    for i in cols:
        j = i + "_perc"
        genrich[j] = genrich[i] * 100.0 / genrich["genrich_Npeaks"]
    cols2 = ["genrich_Npeaks"]
    for i in cols:
        cols2.append(i)
        cols2.append(i + "_perc")
    genrich = genrich.loc[:, cols2]
    dfs_to_join.append(genrich)
except FileNotFoundError:
    print("Genrich_Peak_Annotations_mqc.csv not found!")

# allstats=allstats.join(x)

if len(dfs_to_join) > 0:
    allstats = reduce(
        lambda a, b: pandas.merge(a, b, how="outer", on="replicateName"), dfs_to_join
    )
    allstats = allstats.round(3)
    allstats.to_csv("QCStats.tsv", sep="\t")
else:
    print("Nothing to add to QCStats.tsv!!")
