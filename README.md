# Build Procedure

I am sorry that this is a complicated mess. That is a result of gathering components from a wide variety of sources and not having the time or expertise to put them into a common framework.

1. Open Expat-win32bin\Source\expat.sln in VS2012, change to "Release", build solution. 
  * Output is in Expat-win32bin\Source\win32\bin\Release
2. Download and unzip http://xmlsoft.org/sources/win32/iconv-1.9.2.win32.zip into your build directory
3. Download and install Lua for Windows () into c:\Lua (warning, not the default install directory)
4. Open SileLectionary.sln
  1. change to "Release"
  2. build
  3. build (have to do it twice)
5. Build justenoughlibtexpdf.dll
  1. Go to libtexpdf using mingw shell
  2. make
    1. This will cause .o files to be built and then libtool will fail mysteriously
  3. ./link_win32
6. Copy dlls to ..\Sile
  1. justenoughlibtexpdf.dll
  2. jehbvc.dll (rename as justenoughharfbuzz.dll)
  3. FontConfig.dll
  4. libexpat.dll


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
