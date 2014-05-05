import os
import re
import sys

class GenerateReport:
    def __init__(self):
        self.fin_encfile = ""
        self.fin_decfile = ""
        self.fout_resultfile = ""

    def OpenFile(self, EncFilename, DecFilename, ReportFilename):
        if os.path.exists(EncFilename):
            self.fin_encfile = open(EncFilename, "r")
        else:
            strErr = "No such file %s\n"%(EncFilename)
            print strErr
            return 1
        if os.path.exists(DecFilename):
            self.fin_decfile = open(DecFilename, "r")
        else:
            strErr = "No such file %s\n"%(DecFilename)
            print strErr
            return 1

        self.fout_reportfile = open(ReportFilename, "w")

        return 0

    def CloseFile(self):
        self.fin_encfile.close()
        self.fin_decfile.close()
        self.fout_reportfile.close()

    def Do(self):
        self.fout_reportfile.write("Sequence,Width,Height,Frame Num,Enc FPS,Enc CPU,Dec FPS,Dec CPU\n")
        while True:
            enc_line = self.fin_encfile.readline()
            dec_line = self.fin_decfile.readline()
            if enc_line and dec_line:
                enc_info = enc_line.rstrip()
                self.fout_reportfile.write("%s"%(enc_info))

                dec_info = dec_line.rstrip()
                dec_info = dec_info.split(',')
                for i in range(1,len(dec_info)):
                    self.fout_reportfile.write("%s,"%(dec_info[i]))
                self.fout_reportfile.write("\n")
            else:
                break

def main():
    ListFilename = ["",""]
    if len(sys.argv)<4:
        EncFilename = "EncPerformance.csv";
        DecFilename = "DecPerformance.csv"
        ReportFilename = "Report.csv"
    else:
        EncFilename = sys.argv[1]
        DecFilename = sys.argv[2]
        ReportFilename = sys.argv[3]

    generator = GenerateReport()
    if generator.OpenFile(EncFilename, DecFilename, ReportFilename):
        sys.exit(1)
    print "Load Results: %s %s"%(EncFilename,DecFilename)
    generator.Do()
    print "Generate Report in %s"%(ReportFilename)
    generator.CloseFile()


if __name__ == "__main__":
    main()
