/*

 Copyright (C) 1990-1996 Mark Adler, Richard B. Wales, Jean-loup Gailly,
 Kai Uwe Rommel, Onno van der Linden and Igor Mandrichenko.
 Permission is granted to any individual or institution to use, copy, or
 redistribute this software so long as all of the original files are included,
 that it is not sold for profit, and that this copyright notice is retained.

*/

/*
 *  zip.h by Mark Adler.
 */

#ifndef __zip_h
#define __zip_h 1

#define ZIP   /* for crypt.c:  include zip password functions, not unzip */

/* Set up portability */
#include "tailor.h"

#define MIN_MATCH  3
#define MAX_MATCH  258
/* The minimum and maximum match lengths */

#ifndef WSIZE
#  define WSIZE  (0x8000)
#endif
/* Maximum window size = 32K. If you are really short of memory, compile
 * with a smaller WSIZE but this reduces the compression ratio for files
 * of size > WSIZE. WSIZE must be a power of two in the current implementation.
 */

#define MIN_LOOKAHEAD (MAX_MATCH+MIN_MATCH+1)
/* Minimum amount of lookahead, except at the end of the input file.
 * See deflate.c for comments about the MIN_MATCH+1.
 */

#define MAX_DIST  (WSIZE-MIN_LOOKAHEAD)
/* In order to simplify the code, particularly on 16 bit machines, match
 * distances are limited to MAX_DIST instead of WSIZE.
 */

/* Forget FILENAME_MAX (incorrectly = 14 on some System V) */
#ifdef DOS
#  define FNMAX 256
#else
#  define FNMAX 1024
#endif

/* Types centralized here for easy modification */
#define local static            /* More meaningful outside functions */
typedef unsigned char uch;      /* unsigned 8-bit value */
typedef unsigned short ush;     /* unsigned 16-bit value */
typedef unsigned long ulg;      /* unsigned 32-bit value */


/* Lengths of headers after signatures in bytes */
#define LOCHEAD 26
#define CENHEAD 42
#define ENDHEAD 18

/* Structures for in-memory file information */
struct zlist {
  /* See central header in zipfile.c for what vem..off are */
  ush vem, ver, flg, how;
  ulg tim, crc, siz, len;
  extent nam, ext, cext, com;   /* offset of ext must be >= LOCHEAD */
  ush dsk, att, lflg;           /* offset of lflg must be >= LOCHEAD */
  ulg atx, off;
  char *name;                   /* File name in zip file */
  char *extra;                  /* Extra field (set only if ext != 0) */
  char *cextra;                 /* Extra in central (set only if cext != 0) */
  char *comment;                /* Comment (set only if com != 0) */
  char *zname;                  /* Name for new zip file header */
  int mark;                     /* Marker for files to operate on */
  int trash;                    /* Marker for files to delete */
  int dosflag;                  /* Set to force MSDOS file attributes */
  struct zlist far *nxt;        /* Pointer to next header in list */
};
struct flist {
  char *name;                   /* Pointer to zero-delimited name */
  char *zname;                  /* Name used for zip file headers */
  int dosflag;                  /* Set to force MSDOS file attributes */
  struct flist far * far *lst;  /* Pointer to link pointing here */
  struct flist far *nxt;        /* Link to next name */
};
struct plist {
  char *zname;                  /* Name used for zip file headers */
  int select;                   /* Selection flag ('i' or 'x') */
};

/* internal file attribute */
#define UNKNOWN (-1)
#define BINARY  0
#define ASCII   1
#define __EBCDIC 2

/* extra field definitions */
#define EF_VMCMS     0x4704   /* VM/CMS Extra Field ID ("G")*/
#define EF_MVS       0x470f   /* MVS Extra Field ID ("G")   */
#define EF_IZUNIX    0x5855   /* UNIX Extra Field ID ("UX") */
#define EF_OS2EA     0x0009   /* OS/2 Extra Field ID (extended attributes) */
#define EF_ACL       0x4C41   /* ACL Extra Field ID (access control list, "AL") */

/* Definitions for extra field handling: */
#define EB_HEADSIZE       4     /* length of a extra field block header */
#define EB_ID             0     /* offset of block ID in header */
#define EB_LEN            2     /* offset of data length field in header */

#define EB_UX_MINLEN      8     /* minimal "UX" field contains atime, mtime */
#define EB_UX_ATIME       0     /* offset of atime in "UX" extra field data */
#define EB_UX_MTIME       4     /* offset of mtime in "UX" extra field data */

#define EB_UX_FULLSIZE    12    /* full "UX" field (atime, mtime, uid, gid) */
#define EB_UX_UID         8     /* byte offset of UID in "UX" field data */
#define EB_UX_GID         10    /* byte offset of GID in "UX" field data */

/* ASCII definitions for line terminators in text files: */
#define LF     10        /* '\n' on ASCII machines; must be 10 due to EBCDIC */
#define CR     13        /* '\r' on ASCII machines; must be 13 due to EBCDIC */
#define CTRLZ  26        /* DOS & OS/2 EOF marker (used in fileio.c, vms.c) */
/* Error return codes and PERR macro */
#include "ziperr.h"


/* Public globals */
extern uch upper[256];          /* Country dependent case map table */
extern uch lower[256];
#ifdef EBCDIC
extern const uch ascii[256];    /* EBCDIC <--> ASCII translation tables */
extern const uch ebcdic[256];
#endif /* EBCDIC */
extern char errbuf[];           /* Handy place to build error messages */
extern int recurse;             /* Recurse into directories encountered */
extern int dispose;             /* Remove files after put in zip file */
extern int pathput;             /* Store path with name */

#ifdef RISCOS
extern int scanimage;           /* Scan through image files */
#endif

#define BEST -1                 /* Use best method (deflation or store) */
#define STORE 0                 /* Store method */
#define DEFLATE 8               /* Deflation method*/
extern int method;              /* Restriction on compression method */

extern int dosify;              /* Make new entries look like MSDOS */
extern char *special;           /* Don't compress special suffixes */
extern int verbose;             /* Report oddities in zip file structure */
extern int fix;                 /* Fix the zip file */
extern int adjust;              /* Adjust the unzipsfx'd zip file */
extern int level;               /* Compression level */
extern int translate_eol;       /* Translate end-of-line LF -> CR LF */
#ifdef VMS
   extern int vmsver;           /* Append VMS version number to file names */
   extern int vms_native;       /* Store in VMS format */
#endif /* VMS */
#if defined(OS2) || defined(WIN32)
   extern int use_longname_ea;   /* use the .LONGNAME EA as the file's name */
#endif
extern int hidden_files;        /* process hidden and system files */
extern int volume_label;        /* add volume label */
extern int dirnames;            /* include directory names */
extern int linkput;             /* Store symbolic links as such */
extern int noisy;               /* False for quiet operation */
extern int extra_fields;        /* do not create extra fields */
extern char *key;               /* Scramble password or NULL */
extern char *tempath;           /* Path for temporary files */
extern FILE *mesg;              /* Where informational output goes */
extern char *zipfile;           /* New or existing zip archive (zip file) */
extern ulg zipbeg;              /* Starting offset of zip structures */
extern ulg cenbeg;              /* Starting offset of central directory */
extern struct zlist far *zfiles;/* Pointer to list of files in zip file */
extern extent zcount;           /* Number of files in zip file */
extern extent zcomlen;          /* Length of zip file comment */
extern char *zcomment;          /* Zip file comment (not zero-terminated) */
extern struct zlist far **zsort;/* List of files sorted by name */
extern ulg tempzn;              /* Count of bytes written to output zip file */
extern struct flist far *found; /* List of names found */
extern struct flist far * far *fnxt;    /* Where to put next in found list */
extern extent fcount;           /* Count of names in found list */

extern struct plist *patterns;  /* List of patterns to be matched */
extern int pcount;              /* number of patterns */
extern int icount;              /* number of include only patterns */

/* Diagnostic functions */
#ifdef DEBUG
# ifdef MSDOS
#  undef  stderr
#  define stderr stdout
# endif
#  define diag(where) fprintf(stderr, "zip diagnostic: %s\n", where)
#  define Assert(cond,msg) {if(!(cond)) error(msg);}
#  define Trace(x) fprintf x
#  define Tracev(x) {if (verbose) fprintf x ;}
#  define Tracevv(x) {if (verbose>1) fprintf x ;}
#  define Tracec(c,x) {if (verbose && (c)) fprintf x ;}
#  define Tracecv(c,x) {if (verbose>1 && (c)) fprintf x ;}
#else
#  define diag(where)
#  define Assert(cond,msg)
#  define Trace(x)
#  define Tracev(x)
#  define Tracevv(x)
#  define Tracec(c,x)
#  define Tracecv(c,x)
#endif


/* Public function prototypes */

        /* in zip.c, zipcloak.c, or zipsplit.c */
#ifdef EBCDIC
extern int aflag;
#endif /* EBCDIC */
#ifdef CMS_MVS
extern int bflag;
#endif /* CMS_MVS */
void zipwarn  OF((char *, char *));
void ziperr   OF((int c, char *h));
#ifdef UTIL
#  define error(msg)    ziperr(ZE_LOGIC, msg)
#else
   void error OF((char *h));
#endif

        /* in zipup.c */
#ifndef UTIL
   int percent OF((ulg, ulg));
   int zipup OF((struct zlist far *, FILE *));
   int file_read OF((char *buf, unsigned size));
#endif /* !UTIL */

        /* in zipfile.c */
#ifndef UTIL
   struct zlist far *zsearch OF((char *));
#  ifdef USE_EF_UX_TIME
     int get_ef_ux_ztime OF((struct zlist far *, ztimbuf *));
#  endif /* USE_EF_UX_TIME */
   int trash OF((void));
#endif /* !UTIL */
char *ziptyp OF((char *));
int readzipfile OF((void));
int putlocal OF((struct zlist far *, FILE *));
int putextended OF((struct zlist far *, FILE *));
int putcentral OF((struct zlist far *, FILE *));
int putend OF((int, ulg, ulg, extent, char *, FILE *));
int zipcopy OF((struct zlist far *, FILE *, FILE *));

        /* in fileio.c */
#ifndef UTIL
   char *getnam OF((char *));
   struct flist far *fexpel OF((struct flist far *));
   char *last OF((char *, int));
   char *msname OF((char *));
   int check_dup OF((void));
   int filter OF((char *name));
   int newname OF((char *n, int isdir));
   time_t dos2unixtime OF((ulg dostime));
   ulg dostime OF((int, int, int, int, int, int));
   ulg unix2dostime OF((time_t *));
   int issymlnk OF((ulg a));
#  ifdef S_IFLNK
#    define rdsymlnk(p,b,n) readlink(p,b,n)
/*   extern int readlink OF((char *, char *, int)); */
#  else /* !S_IFLNK */
#    define rdsymlnk(p,b,n) (0)
#  endif /* !S_IFLNK */
#endif /* !UTIL */

int destroy OF((char *));
int replace OF((char *, char *));
int getfileattr OF((char *));
int setfileattr OF((char *, int));
char *tempname OF((char *));
int fcopy OF((FILE *, FILE *, ulg));

#ifdef ZMEM
   char *memset OF((char *, int, unsigned int));
   char *memcpy OF((char *, char *, unsigned int));
   int memcmp OF((char *, char *, unsigned int));
#endif /* ZMEM */

        /* in system dependent fileio code (<system>.c) */
#ifndef UTIL
#  if defined(MSVMS) || defined(AMIGA) || defined(RISCOS) || defined(ATARI)
     int wild OF((char *));
#  endif
   char *in2ex OF((char *));
   char *ex2in OF((char *, int, int *));
   int procname OF((char *));
   void stamp OF((char *, ulg));
   ulg filetime OF((char *, ulg *, long *, ztimbuf *));
#if !(defined(VMS) && defined(VMS_PK_EXTRA))
   int set_extra_field OF((struct zlist far *z, ztimbuf *z_utim));
#else /* VMS && VMS_PK_EXTRA */
   void vms_get_attributes (); /* (struct ioctx *ctx, struct zlist far *z,
                                   ztimbuf *z_utim) */
#endif /* ?(VMS && VMS_PK_EXTRA) */
   int deletedir OF((char *));
   void version_local OF((void));
#ifdef MY_ZCALLOC
     zvoid far *zcalloc OF((unsigned int, unsigned int));
     zvoid zcfree       OF((zvoid far *));
#endif /* MY_ZCALLOC */
#endif /* !UTIL */

        /* in util.c */
char *isshexp OF((char *));
int   shmatch OF((char *, char *));
#ifdef DOS
   int dosmatch OF((char *, char *));
#endif /* DOS */
void init_upper    OF((void));
int  namecmp       OF((char *string1, char *string2));

#ifdef EBCDIC
char *strtoasc(char *str1, char *str2);
char *strtoebc(char *str1, char *str2);
#endif /* EBCDIC */

zvoid far **search OF((zvoid *, zvoid far **, extent,
                       int (*)(const zvoid *, const zvoid far *)));
void envargs       OF((int *Pargc, char ***Pargv, char *envstr, char *envstr2));
void expand_args   OF((int *argcp, char ***argvp));

#ifndef USE_ZLIB
#ifndef UTIL
        /* in crc32.c */
ulg  crc32         OF((ulg, const uch *, extent));
#endif /* !UTIL */

        /* in crctab.c */
ulg near *get_crc_table OF((void));
#endif /* !USE_ZLIB */

#ifndef UTIL
        /* in deflate.c */
void lm_init OF((int pack_level, ush *flags));
void lm_free OF((void));
ulg  deflate OF((void));

        /* in trees.c */
void ct_init     OF((ush *attr, int *method));
int  ct_tally    OF((int dist, int lc));
ulg  flush_block OF((char far *buf, ulg stored_len, int eof));

        /* in bits.c */
void     bi_init     OF((FILE *zipfile));
void     send_bits   OF((int value, int length));
unsigned bi_reverse  OF((unsigned value, int length));
void     bi_windup   OF((void));
void     copy_block  OF((char *block, unsigned len, int header));
int      seekable    OF((void));
extern   int (*read_buf) OF((char *buf, unsigned size));
ulg      memcompress OF((char *tgt, ulg tgtsize, char *src, ulg srcsize));

#endif /* !UTIL */

/*---------------------------------------------------------------------------
    VMS-only functions:
  ---------------------------------------------------------------------------*/
#ifdef VMS
   int    vms_stat        OF((char *file, stat_t *s));              /* vms.c */
   void   vms_exit        OF((int e));                              /* vms.c */
#ifndef UTIL
#ifdef VMSCLI
   ulg    vms_zip_cmdline OF((int *, char ***));                /* cmdline.c */
   void   help            OF((void));                           /* cmdline.c */
#endif /* VMSCLI */
#endif /* !UTIL */
#endif /* VMS */

#endif /* !__zip_h */
/* end of zip.h */
