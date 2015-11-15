#ifndef _LIBTEXPDF_H
#define _LIBTEXPDF_H
#define XETEX 1 /* We are all xetex now */

#include "config.h"

#include <string.h>

#include <stdint.h>

extern int compat_mode;

/* Stolen from kpathsea, to avoid depending on it */
#define FOPEN_A_MODE "ab"

#define FOPEN_R_MODE "r"

#define FOPEN_W_MODE "wb"

/* How to open a binary file for reading:  */
#define FOPEN_RBIN_MODE "rb"

/* How to open a binary file for writing:  */
#define FOPEN_WBIN_MODE "wb"

#include "agl.h"
#include "bmpimage.h"
#include "cff.h"
#include "cff_dict.h"
#include "cff_limits.h"
#include "cff_types.h"
#include "cid.h"
#include "cid_p.h"
#include "cidtype0.h"
#include "cidtype2.h"
#include "cmap.h"
#include "cmap_p.h"
#include "cmap_read.h"
#include "cmap_write.h"
#include "cs_type2.h"
#include "dpxcrypt.h"
#include "dpxfile.h"
#include "dpxutil.h"
#include "epdf.h"
#include "error.h"
#include "fontmap.h"
#include "jp2image.h"
#include "jpegimage.h"
#include "mem.h"
#include "mfileio.h"
#include "numbers.h"
#include "otl_conf.h"
#include "otl_opt.h"
#include "pdfcolor.h"
#include "pdfdev.h"
#include "pdfdoc.h"
#include "pdfdraw.h"
#include "pdfencoding.h"
#include "pdfencrypt.h"
#include "pdffont.h"
#include "pdflimits.h"
#include "pdfnames.h"
#include "pdfobj.h"
#include "pdfparse.h"
#include "pdfresource.h"
#include "pdfximage.h"
#include "pkfont.h"
#include "pngimage.h"
#include "pst.h"
#include "pst_obj.h"
#include "sfnt.h"
#include "subfont.h"
#include "t1_char.h"
#include "t1_load.h"
#include "tfm.h"
#include "truetype.h"
#include "tt_aux.h"
#include "tt_cmap.h"
#include "tt_glyf.h"
#include "tt_gsub.h"
#include "tt_post.h"
#include "tt_table.h"
#include "type0.h"
#include "type1.h"
#include "type1c.h"
#include "unicode.h"
#ifdef __MINGW32__
#define off_tNLM off64_t
#define ftello ftello64
#define fseeko fseeko64
#endif

#endif
