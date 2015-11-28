This is a process to make it reasonably efficient to create and typeset
a tok ples Roman Catholic lectionary based on the PNG Tok Pisin Lectionary.

It would be wise to discuss the project with the church hierarchy before
doing this. I believe you will need an Imprimatur (approval) before you
can distribute this to the churches.

Elizabeth Vahey Smith worked on creating the initial control files to allow this.
Marsha Relyea Miles did editing and refinement of these files.
Nathan Miles wrote the typesetting software based on existing SILE tool
by Simon Cozens.

Paratext assembles the pieces of the lectionary for a year into a single file.
The SILE program is used to do the typesetting.
SILE is described here: http://www.sile-typesetter.org/what-is/index.html

(I am assuming you are running Paratext on a Linux machine since the SILE tool
 only runs there)

{Info in curly braces gives current status of tasks that need more work}

* Install Sile on your machine
    $ cd ~
    $ git clone https://github.com/Nathan22Miles/sile.git
    $ cd sile
    $ sudo apt-get update
    $ sudo apt-get install libharfbuzz-dev
    $ sudo apt-get install libfreetype6-dev
    $ sudo apt-get install libfontconfig1-dev
    $ sudo apt-get install lua5.1
    $ sudo apt-get install luarocks
    $ sudo luarocks install lpeg
    $ sudo luarocks install luaexpat
    $ ./configure
    $ make
    $ make install
    $ ./sile examples/test.sil (should make test.pdf in examples directory)

* Get a copy of TPLCT (from Nathan or Marsha)
    -- The lectionary control files are in the "modules" directory.
       They are called yearA.SFM, yearB.SFM, yearC.SFM
       {yearC is pretty clean, yearB needs editing, yearA is barely started}

* Copy books from your vernacular project to TPLCT
    (all the remaining commands will be done in TPLCT)
    (copying your books to TPLCT allows making any small edits to the text necessary
     for the lectionary)

* If you only have a NT copy the OT/DC books from a language of wider communication to TPLCT
    -- WARNING You must get copyright permission from the publisher to do this

* If you intend to localize the headings in the lectionary
    -- Open up TPLCT XXA
    -- For each tok pisin heading, place the tok ples version following the verse number
       Do NOT edit the tok pisin heading even if you see a typo (otherwise the insert
       process will fail for that heading)
       -- You do not have to translate all headings, untranslated headings will be left
          in tok pisin
    -- Start a Linux shell in TPLCT/shared directory
    -- python TranslateHeadings.py
       (this will update the year(A,B,C).SFM files with the translated headings)
          {currently only does yearC and puts the result in yearC.SFM.new}

* [A] Create a Paratext module to hold one year of lectionary
    -- Tools > Open Bible Module
    -- Pick an empty XX? book (I will assume you are using XXD for these instructions)
    -- Pick "Open Existing Module", select yearA.SFM, yearB.SFM, or yearC.SFM
    -- Go to XXD
    -- View > Standard Output
    -- Hit F5 to gather all of the pieces of for one year of lectionary into XXD, if there are any error
       messages about missing references will need to addjust some of the \ref lines to match your 
       versification and verse bridges

* If you are using the {text in Bible|text in Lectionary} method of marking differences
    -- Open 096XXD.sfm in a text editor that supports regular expressions
    -- \{[^\|\}]*\|([^\}]*)\}   ==>  \1

* Tools > Advanced > Export Project to USX (remember what directory you put result in)
    -- copy 096XXD.usx to sile/lectionary
    -- Start a Linux shell in ~/sile/lectionary directory

* Start a Linux shell in ~/sile/lectionary directory
    -- python usxToSile.py
       (trasforms 096XXD.usx to lectionary.xml)
    -- cd ..
    -- ./sile lectionary/lectionary.xml
       (will create file lectionary.pdf, takes about 10 minutes, shows page number
        as each page is typesett, 300-ish pages)

Repeat steps starting at [A] for other two years of the lectionary

