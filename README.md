# Build Procedure

I am sorry that this is a complicated mess. That is a result of gathering components from a wide variety of sources and not having the time or expertise to put them into a common framework.

1. Open Expat-win32bin\Source\expat.sln in VS2012 and build solution. 
  * Output is in Expat-win32bin\Source\win32\bin\Release
2. Download and unzip http://xmlsoft.org/sources/win32/iconv-1.9.2.win32.zip into your build directory
3. Download and install Lua for Windows () into c:\Lua (warning, not the default install directory)
4. Open SileLectionary.sln and build


Appendix - Build Dependencies

freetype\builds\windows\visualc\freetype.sln
	out: freetype\objs\vc2010\Win32\freetype261.lib

harfbuzz
	freetype\include
	freetype\objs\vc2010\Win32
	out: harfbuzz\win32\libs\Release\harfbuzz.lib

Expat-win32bin
	out: \Expat-win32bin\Source\win32\bin\Release\libexpat.dll

FontConfig
	expat
	iconv
	out: FontConfig\Release\fontconfig.dll

justenoughharfbuzz
	FontConfig       (include)
	C:\MinGW\msys\1.0\home\Miles\freetype\objs\vc2010\Win32\freetype261.lib
	C:\MinGW\msys\1.0\home\Miles\harfbuzz\win32\libs\Release\harfbuzz.lib
	C:\MinGW\msys\1.0\home\Miles\fontconfig\debug\fontconfig.lib
	C:\Program Files\lua\5.1\lib\lua5.1.lib
	Usp10.lib
