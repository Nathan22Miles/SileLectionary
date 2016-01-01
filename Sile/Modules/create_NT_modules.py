
from sed import sed
import re

ntref = r"ref (?:MAT|MRK|LUK|JHN|ACT|ROM|1CO|2CO|GAL|EPH|PHP|COL|1TH|2TH|1TI|2TI|TIT|PHM|HEB|JAS|1PE|2PE|1JN|2JN|3JN|JUD|REV)"

splitter = r"(?s)((?:\\ms1.*?\n)|(?:\\ms WELKAMIM GUTNIUS.*?\\dend\n))"

def change(text):
    parts = re.split(splitter, text)
    for i in range(0, len(parts), 2):
    	parts[i] = ""
      
    return "".join(parts)

sed(change, "YearA.sfm", out="YearA_NT.sfm")
sed(change, "YearB.sfm", out="YearB_NT.sfm")
sed(change, "YearC.sfm", out="YearC_NT.sfm")