from sed import sed
import re

def fix(text):
    if not text.startswith("SAM"):
        return text

    parts = re.split(r"(\\s1 Bekim.*\n)", text)
    for i in range(3, len(parts), 2):
        parts[i] = parts[1]

    return "".join(parts)

def change(text):
    parts = re.split(r"(\\ms )", text)
    for i in range(2, len(parts), 2):
        parts[i] = fix(parts[i])
      
    return "".join(parts)

sed(change, "b.sfm", out="b.new")
