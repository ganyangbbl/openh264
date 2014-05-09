import os
import re
import sys
import string

class ExtractDecTestResult:
    def __init__(self,platform):
        self.fin_logfile = ""
        self.fout_resultfile = ""

        self.pattern_testfile = "Test file:"
        self.pattern_width = "Width:"
        self.pattern_height = "Height:"
        self.pattern_frames = "Frames:"
        self.pattern_FPS = "FPS:"
        self.pattern_CpuUsage = "CPU Usage:"

        self.test_info = ["","",""]
        self.platform = platform

    def OpenFile(self, LogFilename, ResultFilename):
        if os.path.exists(LogFilename):
            self.fin_logfile = open(LogFilename, "r")
        else:
            strErr = "No such file %s\n"%(LogFilename)
            print strErr
            return 1

        self.fout_resultfile = open(ResultFilename, "w")

        return 0

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

    def ParseTestCase(self,line):
        pattern_endcase = "#+Decoder Test (\d+) Start#+"
        if re.search(pattern_endcase,line):
            return 1
        else:
            return 0

    def ParseTestResult(self):
        pattern_endcase = "#+Decoder Test (\d+) Completed#+"
        cpu_usage_array = []
        while True:
            line = self.fin_logfile.readline()
            if line:
                if self.platform == "android":
                    line_sub = re.split("/welsdec \(\s*\d+\): ",line,1)
                    line = line_sub[1]
                if re.search(pattern_endcase,line):
                    break
                if re.search(self.pattern_testfile,line):
                    info = line.partition(self.pattern_testfile)
                    self.test_info[0] = info[2].split()[0]
                if re.search(self.pattern_FPS,line):
                    info = line.partition(self.pattern_FPS)
                    self.test_info[1] = info[2].split()[0]
                if re.search(self.pattern_CpuUsage,line):
                    info = line.partition(self.pattern_CpuUsage)
                    cpu_usage_array.append(string.atof(info[2].split()[0]))
            else:
                break
        self.CalculateCpuUsage(cpu_usage_array)

    def CalculateCpuUsage(self,cpu_usage_array):
        if len(cpu_usage_array)==0:
            self.test_info[2] = "0"
            return
        if len(cpu_usage_array)>1:
            cpu_usage_array.remove(min(cpu_usage_array))
            while min(cpu_usage_array) == 0:
                cpu_usage_array.remove(0)
        self.test_info[2] = sum(cpu_usage_array)/len(cpu_usage_array)

    def WriteResult(self):
        for i in range(0,len(self.test_info)):
            self.fout_resultfile.write('%s,'%(self.test_info[i]))
        self.fout_resultfile.write('\n')
        
def main():
    if len(sys.argv)<2:
        print "please specify the platform: 'ios' or 'android'"
        sys.exit(1)
    elif len(sys.argv)<4:
        Platform = sys.argv[1]
        LogFilename = "DecPerfTest.log";
        ResultFilename = "DecPerformance.csv"
    else:
        Platform = sys.argv[1]
        LogFilename = sys.argv[2]
        ResultFilename = sys.argv[3]

    extractor = ExtractDecTestResult()
    if extractor.OpenFile(LogFilename, ResultFilename):
        sys.exit(1)
    print "Load log file: %s"%(LogFilename)
    extractor.Do()
    print "Generate Result in %s"%(ResultFilename)
    extractor.CloseFile()

if __name__ == "__main__":
    main()
