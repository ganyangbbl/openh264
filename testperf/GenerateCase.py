import os
import re
import sys

def GenerateCase(CaseFilename, ListFilename):
    fin_casefile = open(CaseFilename, "r")
    fout_listfile = open(ListFilename, "w")

    pattern_resolution = "(\d+)x(\d+)"
    pattern_testsequence = "TestSequence"

    enccfgFilename = "welsenc_ios.cfg"
    layercfgFilename = "layer2.cfg"
    bsFilename = "test.cfg"
    
    for line in fin_casefile:
        if line[0] == '#':
            continue
        
        if re.search(pattern_testsequence,line):
            sequence_info = line.split()
            sequence_info.remove(pattern_testsequence)
            print sequence_info

    for i in range(0,len(sequence_info)):
        matchResult_resolution = re.search(pattern_resolution, sequence_info[i])
        width = int(matchResult_resolution.groups()[0])
        height = int(matchResult_resolution.groups()[1])
        fout_listfile.write("dummy %s -org %s -bf %s -numl 1 %s -dw %d -dh %d\n"%(enccfgFilename,sequence_info[i],bsFilename,layercfgFilename,width,height))
    
    fin_casefile.close()
    fout_listfile.close()
    
def main():
    if len(sys.argv)<3:
        CaseFilename = "case.cfg";
        ListFilename = "cfglist.cfg"
    else:
        CaseFilename = sys.argv[1]
        ListFilename = sys.argv[2]

    print CaseFilename, ListFilename
    GenerateCase(CaseFilename, ListFilename)

if __name__ == "__main__":
    main()
