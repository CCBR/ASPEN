import os, sys

i = 0
for l in sys.stdin:
    i += 1
    if i == 1:
        continue
    if i == 2:
        outlist = []
        l = l.strip().split("\t")
        for s in l:
            if s.startswith("/"):
                x = os.path.basename(s)
                x = x.replace(".genrich.tn5nicks.bam", "")
                x = x.replace(".macs2.tn5nicks.bam", "")
                x = x.replace(".tn5sites.bam", "")
                x = x.replace(".reads.bam", "")
                outlist.append(x)
            else:
                outlist.append(s)
        print("\t".join(outlist))
    else:
        print(l.strip())
