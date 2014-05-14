import os
import re
import sys

class GenerateCase:
    def __init__(self,platform):
        self.fin_casefile = ""
        self.fout_enclistfile = ""
        self.fout_declistfile = ""

        self.pattern_resolution = "(\d+)x(\d+)"
        self.pattern_testsequence = "TestSequence"
        self.pattern_targetbitrate = "TargetBitrate"
        self.pattern_end = "#=+#"

        self.pattern_90p = "90p"
        self.pattern_180p = "180p"
        self.pattern_360p = "360p"
        self.pattern_720p = "720p"

        if platform == "ios":
            self.enccfgFilename = "welsenc_ios.cfg"
        elif platform == "android":
            self.enccfgFilename = "welsenc_android.cfg"
        else:
            self.enccfgFilename = "welsenc.cfg"
        self.layercfgFilename = "layer2.cfg"

    def OpenFile(self, CaseFilename, ListFilename):
        if os.path.exists(CaseFilename):
            self.fin_casefile = open(CaseFilename, "r")
        else:
            strErr = "No such file %s\n"%(CaseFilename)
            print strErr
            return 1

        self.fout_enclistfile = open(ListFilename[0], "w")
        if ListFilename[1] != "":
            self.fout_declistfile = open(ListFilename[1], "w")

        return 0

    def CloseFile(self):
        self.fin_casefile.close()
        self.fout_enclistfile.close()
        if self.fout_declistfile != "":
            self.fout_declistfile.close()

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
                elif line[0] == '#':
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
        bsFilename_Prefix = "PerfTest_"
        yuvFilename_Prefix = "PerfTest_"
        for i in range(0,len(sequence_info)):
            sequence = sequence_info[i]
            bitrate = bitrate_info[i]
            for seq_index in range(0,len(sequence)):
                matchResult_resolution = re.search(self.pattern_resolution, sequence[seq_index])
                width = int(matchResult_resolution.groups()[0])
                height = int(matchResult_resolution.groups()[1])
                bsFilename = bsFilename_Prefix + sequence[seq_index].replace(".yuv",".264")
                yuvFilename = yuvFilename_Prefix + sequence[seq_index]
                command_seq = "dummy %s -org %s -bf %s -numl 1 -lconfig 0 %s -sw %d -sh %d -dw 0 %d -dh 0 %d" \
                          %(self.enccfgFilename,sequence[seq_index],bsFilename, \
                            self.layercfgFilename,width,height,width,height)
                count = 0
                for bit_index in range(0,len(bitrate)):
                    command_bit = command_seq+" -ltarb 0 %s"%(bitrate[bit_index])
                    enc_command = command_bit+"\n"
                    enc_command = enc_command.replace(".264","_%d.264"%(count))
                    dec_command = "dummy %s %s\n"%(bsFilename,yuvFilename)
                    dec_command = dec_command.replace(".264","_%d.264"%(count))
                    count += 1
                    self.fout_enclistfile.write(enc_command)
                    if self.fout_declistfile != "":
                        self.fout_declistfile.write(dec_command)
        
def main():
    ListFilename = ["",""]
    if len(sys.argv)<2:
        print "please specfiy the platform: 'ios' or 'android'"
        sys.exit(1)
    elif len(sys.argv)<4:
        Platform = sys.argv[1]
        CaseFilename = "case.cfg"
        ListFilename[0] = "enc_caselist.cfg"
        ListFilename[1] = "dec_caselist.cfg"
    else:
        Platform = sys.argv[1]
        CaseFilename = sys.argv[2]
        ListFilename[0] = sys.argv[3]
        if len(sys.argv)>4:
            ListFilename[1] = sys.argv[4]

    generator = GenerateCase(Platform)
    if generator.OpenFile(CaseFilename, ListFilename):
        sys.exit(1)
    print "Load case cfg: %s"%(CaseFilename)
    generator.Do()
    print "Generate Test Case in %s"%(ListFilename)
    generator.CloseFile()


if __name__ == "__main__":
    main()
