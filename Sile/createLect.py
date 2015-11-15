
import re
import codecs
import sys
import subprocess

#! get file names from command line args

# If "ProjectName" file does not exist prompt the user for the project name and write file.
def getProjectName():
    try:
        with open("ProjectName") as fd:
            return fd.read().strip()
    except:
        pass

    proj = raw_input("Lectionary Project Name> ")
    with open("ProjectName", "w") as fd:
        fd.write(proj)

    return proj

project = getProjectName()

book = sys.argv[1]

##########################################
# Initialize .net and Paratext code
##########################################

# remove " (86)" from following line if you have 32 bit system
sys.path.append("c:\\Program Files (x86)\\Paratext 7")
import clr
clr.AddReference('System.IO')
clr.AddReference('System.Xml')
from System.Xml import XmlWriterSettings, XmlWriter

clr.AddReference('ParatextShared')
from Paratext import *

ScrTextCollection.Initialize()
scrText = ScrTextCollection.Get(project)

vref = VerseRef(book + " 1:1")
bookNum = vref.BookNum

##########################################

def readUSFM():
    getSingleChapter = False # False means 'read entire book'
    runMapinCctIfPresent = True
    text = scrText.GetText(vref, getSingleChapter, runMapinCctIfPresent)

    return text

# Write USFM text of book
def writeUSFM(text):
    scrText.PutText(book, None, False, text, None)

# Use Paratext to write the usx for project/book to path
def writeUSX(path):
    text = readUSFM()

    settings = XmlWriterSettings(Indent=True, NewLineChars="\r\n")

    xw = XmlWriter.Create(path, settings) 
    UsfmToUsx.ConvertToXmlWriter(scrText, bookNum, UsfmToken.NormalizeUsfm(scrText, bookNum, scrText.GetText(bookNum)), xw)
    xw.Close()

# Sometimes we need different text in the lectionary than the Bible.
# Currently we are encoding this like {Bible text|lectionary text}, Example
#     {He|Jesus} said, ...
# Change text to have only the lectionary text.
# Checking would work better and it would be less confusing if we encoded this like
#     \p He said ...
#     \rem Lectionary "He said" => "Jesus said"

def selectLectionaryText():
    text = readUSFM()

    text = re.sub(r"\{[^\|\}]*\|([^\}]*)\}", "\1", text)
    
    writeUSFM(text)

# Add some extra space and breaks after <s1>
def processSAM(text):
    parts = text.split("\n")
    firstS1 = True
    
    for i in range(len(parts)-1):
        if re.match(r"\s*<s1>", parts[i]):
            if firstS1: 
                firstS1 = False
                continue
            parts[i] = parts[i] + "\n<par/><goodbreak/>"
    
    return "\n".join(parts)

def adjustText(text):
    # remove book lines
    text = re.sub(r'<book.*\n', r'', text)

    text = re.sub(r'<para style="dbeg" />', r'<twocol>', text)
    text = re.sub(r'<para style="dend" />', r'</twocol>', text)

    text = re.sub(r'<para style="b" />', r'<b/>', text)

    # remove empty char styles, e.g.
    # <char style="rq" closed="false" />
    text = re.sub(r'<char[^>]*/>', r"", text)

    # from: <char style="rq" closed="false">Mt 1:1-25</char>
    # to:   <rq>Mt 1:1-25</rq>
    text = re.sub(r'<char style="(\w+)"[^>]*>(.*?)</char>', r"<\1>\2</\1>", text)

    text = re.sub(r'<para style="(\w+)"[^>]*>(.*?)</para>', r"<\1>\2</\1>", text)

    text = re.sub(r'<para style="(\w+)"[^>]*/>\s*', r"", text)

    # replace carets with typographic quotes
    text = re.sub(r'&lt;&lt;', ur'\u201c', text)
    text = re.sub(r'&gt;&gt;', ur'\u201d', text)
    text = re.sub(r'&lt;', ur'\u2018', text)
    text = re.sub(r'&gt;', ur'\u2019', text)

    # insert thin space between single and double quotes
    text = re.sub(r'\u201c *\u2018', ur'\u201c<glue width="0.2em" />\u2018', text)
    text = re.sub(r'\u2019 *\u201d', ur'\u2019<glue width="0.2em" />\u201d', text)

    text = re.sub(ur'\u00e7', ur'\u0268', text)
    text = re.sub(ur'\u00c7', ur'\u0197', text)

    # remove
    # <book code="XXD" style="id" />
    # <chapter number="1" style="c" />
    # <rem>...</rem>
    text = re.sub(r'<chapter.*?/>\s*', r'', text)
    text = re.sub(r'<rem>.*?</rem>\s*', r'', text)

    # add <eject/><h>
    text = re.sub(r'<ms1>(.*?)</ms1>', r'  <eject/>\n  <h>\1</h>\n  <ms1>\1</ms1>', text)

    text = re.sub(r'\n +', r'\n', text)

    # tag speaker in plays
    text = re.sub(r'<sp>(\w:)', r'<sp><who>\1</who>', text)
    text = re.sub(r'<sp>([^<])', ur'<sp><nowho>\u00a0\u00a0</nowho><glue width="0.2em" />\1', text)

    # usx -> sile
    text = re.sub(r'<usx .*?>',  r'<sile class="lectionary" papersize="a4">\n<include src="lectionary/styles.sil" />', text)
    text = re.sub(r'</usx>', r'</sile>', text)

    # remove fig's
    text = re.sub(r'<figure.*?</figure>', r'', text)

    text = re.sub(r'<para style="" status="unknown" />\s*', '', text)

    # change running headers to info nodes
    text = re.sub(r'<h>(.*)</h>', r'<info category="h" value="\1" />', text)

    # gather \mt's onto their own page
    mt = r'(?:<mt.*\n)'
    mtorb = r'(?:<(?:mt|b).*\n)'
    text = re.sub(r'(' + mt + mtorb + r'*)', r'<eject/>\n<vfill/>\n\1<vfill/>\n', text)

    # remove first eject (so we don't start with a blank page)
    text = re.sub(r'<eject/>\s*', '', text, 1)

    # Add an <info> to the title pages dividing major sections.
    # Remove the first one because we don't want it to have a page number.
    text = re.sub(r'(<vfill/>\n)(<mt)', 
        ur'\1<info category="h" value="\u00a0" />\n\2', text)
    text = re.sub(r'<info .*?/>\n', r'', text, 1)

    # make mt divider be bigskip`
    text = re.sub(r"(<mt.*\n)<b/>", r"\1<bigskip/>", text)

    parts = re.split(r'(<ms>.*)', text)
    for i in range(1,len(parts),2):
        if i+1<len(parts) and parts[i].startswith("<ms>SAM"):
            parts[i+1] = processSAM(parts[i+1])

    text = "".join(parts)

    return text
        
# Use when debugging to create small files for testing
def writeAsInvidualSundays(text):
    header = """<?xml version="1.0" encoding="utf-8"?>
<sile class="lectionary" papersize="a4">
<include src="lectionary/styles.sil" />
"""
    parts = re.split(r"(<ms1)", text)

    for i in range(1,len(parts)-2,2):
        parts[i+1] = parts[i+1] + "\n</sile>"
        with codecs.open("pages/page" + str(i/2) + ".xml", "w", "utf-8") as fd:
            fd.write(header + parts[i] + parts[i+1])

def runSile(outPath):
    subprocess.call(["lua", "lect.lua", outPath])

selectLectionaryText()
writeUSX("raw.usx")

with codecs.open("raw.usx", "r", "utf-8") as fd:
    text = fd.read()

text = processSAM(text)
text = adjustText(text)

outPath = "lectionary/" + book + ".xml"

with codecs.open(outPath, "w", "utf-8") as fd:
    fd.write(text)

print "%s written" % (outPath)

runSile(outPath)