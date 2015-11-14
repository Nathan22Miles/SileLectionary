freetype 2.4.6
- get the source from here: http://download.savannah.gnu.org/releases/freetype/freetype-2.4.6.tar.gz
- replace "#define ft_fopen    fopen" in ftsdtlib.h by
#ifdef _WIN32
extern FILE *fopen_utf8(const char *_Filename, const char *_Mode);
#define ft_fopen    fopen_utf8
#else
#define ft_fopen    fopen
#endif
- apply patch from commit 864c426eff559dbcceb64bc42590007d6900ff23 (http://git.savannah.gnu.org/cgit/freetype/freetype2.git/commit/?id=864c426eff559dbcceb64bc42590007d6900ff23)
- compile it using vs2k10 with "release Multithreaded" configuration