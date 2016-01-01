
from sed import sed
import re

ntref = r"ref (?:MAT|MRK|LUK|JHN|ACT|ROM|1CO|2CO|GAL|EPH|PHP|COL|1TH|2TH|1TI|2TI|TIT|PHM|HEB|JAS|1PE|2PE|1JN|2JN|3JN|JUD|REV)"

splitter = r"(\\ms1.*?\n|\\ms WELKAMIM GUTNIUS\s*\n(?:.*\n)*?(?=\\ms1))"

def change(text):
    parts = re.split(splitter, text)
    for i in range(0, len(parts), 2):
    	parts[i] = ""

    assert len(parts) > 1
      
    return "".join(parts)

sed(change, "Year_A.SFM", out="Year_A_NT.SFM")
sed(change, "Year_B.SFM", out="Year_B_NT.SFM")
sed(change, "Year_C.SFM", out="Year_C_NT.SFM")