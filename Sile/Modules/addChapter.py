from sed import sed
import re

def change(text):
    parts = re.split(r"(\\c\s*\n)", text)
    chap = 1
    for i in range(1, len(parts), 2):
    	parts[i] = "\\c " + str(chap) + "\n"
    	chap = chap + 1
      
    return "".join(parts)

sed(change, "YearA.sfm")
