import os
import re
import sys

class ExtractTestResult:
    def __init__(self, LogFilename, ResultFilename):
        if os.path.exists(LogFilename):
            self.fin_logfile = open(LogFilename, "r")
        else:
            strErr = "No such file %s\n"%(self.fin_logfile)
            print strErr
            return 1

        self.fout_resultfile = open(ResultFilename, "w")

        self.pattern_testfile = "Test file:"
        self.pattern_cfgfile = "cfg file:"
        self.pattern_width = "Width:"
        self.pattern_height = "Height:"
        self.pattern_frames = "Frames:"
        self.pattern_FPS = "FPS:"
        self.pattern_CpuUsage = "CPU Usage:"

        self.test_info = ["","","","","",""]

    def CloseFile(self):
        self.fin_logfile.close()
        self.fout_resultfile.close()

    def Do(self):
        while True:
            line = self.fin_logfile.readline()
            if line:
                if self.ParseTestCase(line):
                    self.ParseTestResult()
                    self.WriteResult()
            else:
                break

        self.CloseFile()

    def ParseTestCase(self,line):
        pattern_endcase = "#+Encoder Test (\d+) Start#+"
        if re.search(pattern_endcase,line):
            return 1
        else:
            return 0

    def ParseTestResult(self):
        pattern_endcase = "#+Encoder Test (\d+) Completed#+"
        while True:
            line = self.fin_logfile.readline()
            if line:
                if re.search(pattern_endcase,line):
                    break
                if re.search(self.pattern_testfile,line):
                    info = line.partition(self.pattern_testfile)
                    self.test_info[0] = info[2].split()[0]
                if re.search(self.pattern_width,line):
                    info = line.partition(self.pattern_width)
                    self.test_info[1] = info[2].split()[0]
                if re.search(self.pattern_height,line):
                    info = line.partition(self.pattern_height)
                    self.test_info[2] = info[2].split()[0]
                if re.search(self.pattern_frames,line):
                    info = line.partition(self.pattern_frames)
                    self.test_info[3] = info[2].split()[0]
                if re.search(self.pattern_FPS,line):
                    info = line.partition(self.pattern_FPS)
                    self.test_info[4] = info[2].split()[0]
                if re.search(self.pattern_CpuUsage,line):
                    info = line.partition(self.pattern_CpuUsage)
                    self.test_info[5] = info[2].split()[0]
            else:
                break

    def WriteResult(self):
        for i in range(0,len(self.test_info)):
            self.fout_resultfile.write('%s,'%(self.test_info[i]))
        self.fout_resultfile.write('\n')
        
def main():
    if len(sys.argv)<3:
        LogFilename = "PerfTest.log";
        ResultFilename = "Performance.csv"
    else:
        LogFilename = sys.argv[1]
        ResultFilename = sys.argv[2]

    generator = ExtractTestResult(LogFilename, ResultFilename)
    print "Load log file: %s"%(LogFilename)
    generator.Do()
    print "Generate Result in %s"%(ResultFilename)

if __name__ == "__main__":
    main()
