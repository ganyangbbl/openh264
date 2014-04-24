import os
import re
import sys

class GenerateCase:
    def __init__(self, CaseFilename, ListFilename):
        if os.path.exists(CaseFilename):
            self.fin_casefile = open(CaseFilename, "r")
        else:
            strErr = "No such file %s\n"%(self.fin_casefile)
            print strErr
            return 1

        self.fout_listfile = open(ListFilename, "w")

        self.pattern_resolution = "(\d+)x(\d+)"
        self.pattern_testsequence = "TestSequence"
        self.pattern_targetbitrate = "TargetBitrate"
        self.pattern_end = "#=+#"

        self.pattern_90p = "90p"
        self.pattern_180p = "180p"
        self.pattern_360p = "360p"
        self.pattern_720p = "720p"

        self.enccfgFilename = "welsenc_ios.cfg"
        self.layercfgFilename = "layer2.cfg"
        self.bsFilename = "test.264"

    def CloseFile(self):
        self.fin_casefile.close()
        self.fout_listfile.close()

    def Do(self):
        sequence_info = []
        targetbitrate_info = []
        
        while True:
            line = self.fin_casefile.readline()
            if line:
                if line[0] == '\n':
                    continue
                if self.ParseCaseBlock(line,self.pattern_testsequence):
                    sequence_info = self.ParseTestSet()
                if self.ParseCaseBlock(line,self.pattern_targetbitrate):
                    targetbitrate_info = self.ParseTestSet()
            else:
                break

        self.WriteCase(sequence_info,targetbitrate_info)
        self.CloseFile()

    def ParseCaseBlock(self,line,keyword):
        pattern_caseblock = "#+%s#+"%(keyword)
        if re.search(pattern_caseblock,line):
            return 1
        else:
            return 0

    def ParseTestSet(self):
        set_info = [[],[],[],[]]
        while True:
            line = self.fin_casefile.readline()
            if line:
                if line[0] == '\n':
                    continue
                elif re.search(self.pattern_end,line):
                    break
                elif line[0] == '\n':
                    continue
                else:
                    info = line.split()
                    if info[0] == self.pattern_90p:
                        info.remove(self.pattern_90p)
                        set_info[0] = info
                    if info[0] == self.pattern_180p:
                        info.remove(self.pattern_180p)
                        set_info[1] = info
                    if info[0] == self.pattern_360p:
                        info.remove(self.pattern_360p)
                        set_info[2] = info
                    if info[0] == self.pattern_720p:
                        info.remove(self.pattern_720p)
                        set_info[3] = info
            else:
                break
        return set_info

    def WriteCase(self,sequence_info,bitrate_info):
        if len(sequence_info) == 0:
            strErr = "No test sequence!\n"
            print strErr
            return
        for i in range(0,len(sequence_info)):
            sequence = sequence_info[i]
            bitrate = bitrate_info[i]
            for seq_index in range(0,len(sequence)):
                matchResult_resolution = re.search(self.pattern_resolution, sequence[seq_index])
                width = int(matchResult_resolution.groups()[0])
                height = int(matchResult_resolution.groups()[1])
                command_seq = "dummy %s -org %s -bf %s -numl 1 %s -sw %d -sh %d" \
                          %(self.enccfgFilename,sequence[seq_index],self.bsFilename, \
                            self.layercfgFilename,width,height)
                for bit_index in range(0,len(bitrate)):
                    command_bit = command_seq+" ltarb 0 %s"%(bitrate[bit_index])
                    command = command_bit+"\n"
                    self.fout_listfile.write(command)
        
def main():
    if len(sys.argv)<3:
        CaseFilename = "case.cfg";
        ListFilename = "caselist.cfg"
    else:
        CaseFilename = sys.argv[1]
        ListFilename = sys.argv[2]

    generator = GenerateCase(CaseFilename, ListFilename)
    print "Load case cfg: %s"%(CaseFilename)
    generator.Do()
    print "Generate Test Case in %s"%(ListFilename)

if __name__ == "__main__":
    main()
