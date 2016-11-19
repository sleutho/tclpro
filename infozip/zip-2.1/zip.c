/*

 Copyright (C) 1990-1996 Mark Adler, Richard B. Wales, Jean-loup Gailly,
 Kai Uwe Rommel, Onno van der Linden and Igor Mandrichenko.
 Permission is granted to any individual or institution to use, copy, or
 redistribute this software so long as all of the original files are included,
 that it is not sold for profit, and that this copyright notice is retained.

*/

/*
 *  zip.c by Mark Adler.
 */

#include "zip.h"
#include "revision.h"
#include "crypt.h"
#include "ttyio.h"
#ifdef VMS
#  include "vms/vmsmunch.h"
#endif

#if (defined(MSDOS) && !defined(__GO32__)) || defined(__human68k)
#  include <process.h>
#endif

#include <signal.h>

#define MAXCOM 256      /* Maximum one-line comment size */


/* Local option flags */
#define DELETE  0
#define ADD     1
#define UPDATE  2
#define FRESHEN 3
local int action = ADD; /* one of ADD, UPDATE, FRESHEN, or DELETE */
local int comadd = 0;   /* 1=add comments for new files */
local int zipedit = 0;  /* 1=edit zip comment and all file comments */
local int latest = 0;   /* 1=set zip file time to time of latest file */
local ulg before = 0;   /* 0=ignore, else exclude files before this time */
local int test = 0;     /* 1=test zip file with unzip -t */
local int tempdir = 0;  /* 1=use temp directory (-b) */
local int junk_sfx = 0; /* 1=junk the sfx prefix */
#ifdef AMIGA
local int filenotes = 0; /* 1=take comments from AmigaDOS filenotes */
#endif

#ifdef EBCDIC
int aflag = __EBCDIC;   /* Convert EBCDIC to ASCII or stay EBCDIC ? */
#endif
#ifdef CMS_MVS
int bflag = 0;          /* Use text mode as default */
#endif

/* Temporary zip file name and file pointer */
local char *tempzip;
local FILE *tempzf;

#ifdef CRYPT
/* Pointer to crc_table, needed in crypt.c */
ulg near *crc_32_tab;
#endif

/* Local functions */

local void freeup  OF((void));
local void finish  OF((int));
#ifndef WIZZIPDLL
local void handler OF((int));
#endif
local void license OF((void));
#ifndef VMSCLI
local void help    OF((void));
#endif /* !VMSCLI */
local void version_info OF((void));
local void zipstdout OF((void));
local void check_zipfile OF((char *zipname, char *zippath));
local void get_filters OF((int argc, char **argv));
#ifndef WIZZIPDLL
      int  main     OF((int, char **));
#else
      int  zipmain  OF((int, char **));
#endif

local void freeup()
/* Free all allocations in the found list and the zfiles list */
{
  struct flist far *f;  /* steps through found list */
  struct zlist far *z;  /* pointer to next entry in zfiles list */

  for (f = found; f != NULL; f = fexpel(f))
    ;
  while (zfiles != NULL)
  {
    z = zfiles->nxt;
    free((zvoid *)(zfiles->name));
    if (zfiles->zname != zfiles->name)
      free((zvoid *)(zfiles->zname));
    if (zfiles->ext)
      free((zvoid *)(zfiles->extra));
    if (zfiles->cext && zfiles->cextra != zfiles->extra)
      free((zvoid *)(zfiles->cextra));
    if (zfiles->com)
      free((zvoid *)(zfiles->comment));
    farfree((zvoid far *)zfiles);
    zfiles = z;
    zcount--;
  }
}


local void finish(e)
int e;                  /* exit code */
/* Process -o and -m options (if specified), free up malloc'ed stuff, and
   exit with the code e. */
{
  int r;                /* return value from trash() */
  ulg t;                /* latest time in zip file */
  struct zlist far *z;  /* pointer into zfile list */

  /* If latest, set time to zip file to latest file in zip file */
  if (latest && zipfile && strcmp(zipfile, "-"))
  {
    diag("changing time of zip file to time of latest file in it");
    /* find latest time in zip file */
    if (zfiles == NULL)
       zipwarn("zip file is empty, can't make it as old as latest entry", "");
    else {
      t = 0;
      for (z = zfiles; z != NULL; z = z->nxt)
        /* Ignore directories in time comparisons */
#ifdef USE_EF_UX_TIME
        if (z->zname[z->nam-1] != '/')
        {
          ztimbuf z_utim;
          ulg z_tim;

          z_tim = (get_ef_ux_ztime(z, &z_utim) ?
                   unix2dostime(&z_utim.modtime) : z->tim);
          if (t < z_tim)
            t = z_tim;
        }
#else /* !USE_EF_UX_TIME */
        if (z->zname[z->nam-1] != '/' && t < z->tim)
          t = z->tim;
#endif /* ?USE_EF_UX_TIME */
      /* set modified time of zip file to that time */
      if (t != 0)
        stamp(zipfile, t);
      else
        zipwarn(
         "zip file has only directories, can't make it as old as latest entry",
         "");
    }
  }
  if (tempath != NULL)
  {
    free((zvoid *)tempath);
    tempath = NULL;
  }
  if (zipfile != NULL)
  {
    free((zvoid *)zipfile);
    zipfile = NULL;
  }


  /* If dispose, delete all files in the zfiles list that are marked */
  if (dispose)
  {
    diag("deleting files that were added to zip file");
    if ((r = trash()) != ZE_OK)
      ziperr(r, "was deleting moved files and directories");
#ifdef WIZZIPDLL
      return;
#endif
  }


  /* Done! */
  freeup();
#ifndef WIZZIPDLL
  EXIT(e);
#endif
}


void ziperr(c, h)
int c;                  /* error code from the ZE_ class */
char *h;                /* message about how it happened */
/* Issue a message for the error, clean up files and memory, and exit. */
{
  static int error_level = 0;

  if (error_level++ > 0)
#ifndef WIZZIPDLL
     EXIT(0);  /* avoid recursive ziperr() */
#else
     return;
#endif

  if (h != NULL) {
    if (PERR(c))
      perror("zip error");
    fflush(mesg);
    fprintf(stderr, "\nzip error: %s (%s)\n", errors[c-1], h);
  }
  if (tempzip != NULL)
  {
    if (tempzip != zipfile) {
      if (tempzf != NULL)
        fclose(tempzf);
#ifndef DEBUG
      destroy(tempzip);
#endif
      free((zvoid *)tempzip);
    } else {
      /* -g option, attempt to restore the old file */
      int k = 0;                        /* keep count for end header */
      ulg cb = cenbeg;                  /* get start of central */
      struct zlist far *z;  /* steps through zfiles linked list */

      fprintf(stderr, "attempting to restore %s to its previous state\n",
         zipfile);
      fseek(tempzf, cenbeg, SEEK_SET);
      tempzn = cenbeg;
      for (z = zfiles; z != NULL; z = z->nxt)
      {
        putcentral(z, tempzf);
        tempzn += 4 + CENHEAD + z->nam + z->cext + z->com;
        k++;
      }
      putend(k, tempzn - cb, cb, zcomlen, zcomment, tempzf);
      tempzf = NULL;
      fclose(tempzf);
    }
  }
  if (key != NULL)
    free((zvoid *)key);
  if (tempath != NULL)
    free((zvoid *)tempath);
  if (zipfile != NULL)
    free((zvoid *)zipfile);
  freeup();
#ifndef WIZZIPDLL
  EXIT(c);
#else
  return;
#endif
}


void error(h)
  char *h;
/* Internal error, should never happen */
{
  ziperr(ZE_LOGIC, h);
}

#ifndef WIZZIPDLL
local void handler(s)
int s;                  /* signal number (ignored) */
/* Upon getting a user interrupt, turn echo back on for tty and abort
   cleanly using ziperr(). */
{
#if !defined(MSDOS) && !defined(__human68k__) && !defined(RISCOS)
  echon();
  putc('\n', stderr);
#endif /* !MSDOS */
  ziperr(ZE_ABORT, "aborting");
  s++;                                  /* keep some compilers happy */
}
#endif /* !WIZZIPDLL */

void zipwarn(a, b)
char *a, *b;            /* message strings juxtaposed in output */
/* Print a warning message to stderr and return. */
{
  if (noisy) fprintf(stderr, "zip warning: %s%s\n", a, b);
}


local void license()
/* Print license information to stdout. */
{
  extent i;             /* counter for copyright array */

  for (i = 0; i < sizeof(copyright)/sizeof(char *); i++) {
    printf(copyright[i], "zip");
    putchar('\n');
  }
  for (i = 0; i < sizeof(disclaimer)/sizeof(char *); i++)
    puts(disclaimer[i]);
}


#ifndef VMSCLI
local void help()
/* Print help (along with license info) to stdout. */
{
  extent i;             /* counter for help array */

  /* help array */
  static const char *text[] = {
#ifdef VMS
"Zip %s (%s). Usage: zip==\"$disk:[dir]zip.exe\"",
#else
"Zip %s (%s). Usage:",
#endif
"zip [-options] [-b path] [-t mmddyy] [-n suffixes] [zipfile list] [-xi list]",
"  The default action is to add or replace zipfile entries from list, which",
"  can include the special name - to compress standard input.",
"  If zipfile and list are omitted, zip compresses stdin to stdout.",
"  -f   freshen: only changed files  -u   update: only changed or new files",
"  -d   delete entries in zipfile    -m   move into zipfile (delete files)",
"  -k   force MSDOS (8+3) file names -g   allow growing existing zipfile",
"  -r   recurse into directories     -j   junk (don't record) directory names",
"  -0   store only                   -l   convert LF to CR LF (-ll CR LF to LF)",
"  -1   compress faster              -9   compress better",
"  -q   quiet operation              -v   verbose operation/print version info",
"  -c   add one-line comments        -z   add zipfile comment",
"  -b   use \"path\" for temp file     -t   only do files after \"mmddyy\"",
"  -@   read names from stdin        -o   make zipfile as old as latest entry",
"  -x   exclude the following names  -i   include only the following names",
#ifdef EBCDIC
#ifdef CMS_MVS
"  -a   translate to ASCII           -B   force binary read (text is default)",
#else  /* !CMS_MVS */
"  -a   translate to ASCII",
#endif /* ?CMS_MVS */
#endif /* EBCDIC */
#ifdef VMS
" \"-F\"  fix zipfile(-FF try harder) \"-D\"  do not add directory entries",
" \"-A\"  adjust self-extracting exe  \"-J\"  junk zip file prefix (unzipsfx)",
" \"-T\"  test zipfile integrity      \"-X\"  eXclude eXtra file attributes",
" \"-V\"  save VMS file attributes     -w   append version number to stored name",
#else
"  -F   fix zipfile (-FF try harder) -D   do not add directory entries",
"  -A   adjust self-extracting exe   -J   junk zip file prefix (unzipsfx)",
"  -T   test zipfile integrity       -X   eXclude eXtra file attributes",
#endif /* VMS */
#ifdef OS2
"  -E   use the .LONGNAME Extended attribute (if found) as filename",
#endif /* OS2 */
#ifdef S_IFLNK
"  -y   store symbolic links as the link instead of the referenced file",
#endif /* !S_IFLNK */
#if defined(MSDOS) || defined(OS2)
"  -$   include volume label         -S   include system and hidden files",
#endif
#ifdef AMIGA
#  ifdef CRYPT
"  -N   store filenotes as comments  -e   encrypt",
"  -h   show this help               -n   don't compress these suffixes"
#  else
"  -N   store filenotes as comments  -n   don't compress these suffixes"
#  endif
#else /* !AMIGA */
#  ifdef CRYPT
"  -e   encrypt                      -n   don't compress these suffixes"
#  else
"  -h   show this help               -n   don't compress these suffixes"
#  endif
#endif /* ?AMIGA */
#ifdef RISCOS
,"  -I   don't scan through Image files"
#endif
  };

  for (i = 0; i < sizeof(copyright)/sizeof(char *); i++)
  {
    printf(copyright[i], "zip");
    putchar('\n');
  }
  for (i = 0; i < sizeof(text)/sizeof(char *); i++)
  {
    printf(text[i], VERSION, REVDATE);
    putchar('\n');
  }
}
#endif /* !VMSCLI */


local void version_info()
/* Print verbose info about program version and compile time options
   to stdout. */
{
  extent i;             /* counter in text arrays */
  char *envptr;

  /* Options info array */
  static const char *comp_opts[] = {
#ifdef ASM_CRC
    "ASM_CRC",
#endif
#ifdef ASMV
    "ASMV",
#endif
#ifdef DYN_ALLOC
    "DYN_ALLOC",
#endif
#ifdef MMAP
    "MMAP",
#endif
#ifdef BIG_MEM
    "BIG_MEM",
#endif
#ifdef MEDIUM_MEM
    "MEDIUM_MEM",
#endif
#ifdef SMALL_MEM
    "SMALL_MEM",
#endif
#ifdef DEBUG
    "DEBUG",
#endif
#ifdef USE_EF_UX_TIME
    "USE_EF_UX_TIME",
#endif
#ifdef VMS
#ifdef VMSCLI
    "VMSCLI",
#endif
#ifdef VMS_IM_EXTRA
    "VMS_IM_EXTRA",
#endif
#ifdef VMS_PK_EXTRA
    "VMS_PK_EXTRA",
#endif
#endif /* VMS */
#if defined(CRYPT) && defined(PASSWD_FROM_STDIN)
    "PASSWD_FROM_STDIN",
#endif /* CRYPT & PASSWD_FROM_STDIN */
    NULL
  };

  static const char *zipenv_names[] = {
#ifndef VMS
#  ifndef RISCOS
    "ZIP"
#  else /* RISCOS */
    "Zip$Options"
#  endif /* ? RISCOS */
#else /* VMS */
    "ZIP_OPTS"
#endif /* ?VMS */
    ,"ZIPOPT"
#ifdef __EMX__
    ,"EMX"
    ,"EMXOPT"
#endif
#ifdef __GO32__
    ,"GO32"
    ,"GO32TMP"
#endif
  };

  for (i = 0; i < sizeof(copyright)/sizeof(char *); i++)
  {
    printf(copyright[i], "zip");
    putchar('\n');
  }

  for (i = 0; i < sizeof(versinfolines)/sizeof(char *); i++)
  {
    printf(versinfolines[i], "Zip", VERSION, REVDATE);
    putchar('\n');
  }

  version_local();

  puts("Zip special compilation options:");
#if WSIZE != 0x8000
  printf("\tWSIZE=%u\n", WSIZE);
#endif
  for (i = 0; (int)i < (int)(sizeof(comp_opts)/sizeof(char *) - 1); i++)
  {
    printf("\t%s\n",comp_opts[i]);
  }
#ifdef CRYPT
  printf("\t[encryption, version %d.%d%s of %s]\n",
            CR_MAJORVER, CR_MINORVER, CR_BETA_VER, CR_VERSION_DATE);
  ++i;
#endif /* CRYPT */
  if (i == 0)
      puts("\t[none]");

  puts("\nZip environment options:");
  for (i = 0; i < sizeof(zipenv_names)/sizeof(char *); i++)
  {
    envptr = getenv(zipenv_names[i]);
    printf("%16s:  %s\n", zipenv_names[i],
           ((envptr == (char *)NULL || *envptr == 0) ? "[none]" : envptr));
  }
}


/* Do command line expansion for MSDOS, OS/2, WIN32, VMS, ATARI, AMIGA
   Human68k and RISCOS */
#if defined(MSVMS) || defined(AMIGA) || defined(RISCOS) || defined(ATARI)
#  define PROCNAME(n) (action==ADD||action==UPDATE?wild(n):procname(n))
#else /* !(MSVMS || AMIGA || RISCOS) */
#  define PROCNAME(n) procname(n)
#endif /* ?(MSVMS || AMIGA || RISCOS || ATARI) */

local void zipstdout()
/* setup for writing zip file on stdout */
{
  int r;
  mesg = stderr;
  if (isatty(1))
    ziperr(ZE_PARMS, "cannot write zip file to terminal");
  if ((zipfile = malloc(4)) == NULL)
    ziperr(ZE_MEM, "was processing arguments");
  strcpy(zipfile, "-");
  if ((r = readzipfile()) != ZE_OK)
    ziperr(r, zipfile);
}


local void check_zipfile(zipname, zippath)
  char *zipname;
  char *zippath;
  /* Invoke unzip -t on the given zip file */
{
#ifndef WIZZIPDLL
#if (defined(MSDOS) && !defined(__GO32__)) || defined(__human68k__)
   int status, len;
   char *path, *p;

   status = spawnlp(P_WAIT, "unzip", "unzip", verbose ? "-t" : "-tqq",
                    zipname, NULL);
/*
 * unzip isn't in PATH range, assume an absolute path to zip in argv[0]
 * and hope that unzip is in the same directory.
 */
   if (status == -1) {
     p = strrchr(zippath, '\\');
     path = strrchr((p == NULL ? zippath : p), '/');
     if (path != NULL)
       p = path;
     if (p != NULL) {
       len = (int)(p - zippath) + 1;
       if ((path = malloc(len + sizeof("unzip.exe"))) == NULL)
         ziperr(ZE_MEM, "was creating unzip path");
       memcpy(path, zippath, len);
       strcpy(&path[len], "unzip.exe");
       status = spawnlp(P_WAIT, path, "unzip", verbose ? "-t" : "-tqq",
                        zipname, NULL);
       free(path);
     }
     if (status == -1)
       perror("unzip");
   }
   if (status != 0) {
#else /* (MSDOS && !__GO32__) || __human68k__ */
   char cmd[FNMAX+16];
   strcpy(cmd, "unzip -t ");
   if (!verbose) strcat(cmd, "-qq ");
   if ((int)strlen(zipname) > FNMAX) {
     error("zip filename too long");
   }
# ifdef UNIX
   strcat(cmd, "'");    /* accept space or $ in name */
   strcat(cmd, zipname);
   strcat(cmd, "'");
# else
   strcat(cmd, zipname);
# endif
# ifdef VMS
   if (!system(cmd)) {
# else
   if (system(cmd)) {
# endif
#endif /* ?((MSDOS && !__GO32__) || __human68k__) */
     fprintf(mesg, "test of %s FAILED\n", zipfile);
     ziperr(ZE_TEST, "original files unmodified");
   }
   if (noisy)
     fprintf(mesg, "test of %s OK\n", zipfile);
#endif /* !WIZZIPDLL */
}

local void get_filters(argc, argv)
  int argc;               /* number of tokens in command line */
  char **argv;            /* command line tokens */
/* Counts number of -i or -x patterns, sets patterns and pcount */
{
  int i;
  int flag = 0;

  pcount = 0;
  for (i = 1; i < argc; i++) {
    if (argv[i][0] == '-') {
      if (strrchr(argv[i], 'i') != NULL) {
        flag = 'i';
      } else if (strrchr(argv[i], 'x') != NULL) {
        flag = 'x';
      } else {
        flag = 0;
      }
    } else if (flag) {
      if (patterns != NULL) {
        patterns[pcount].zname = ex2in(argv[i], 0, (int *)NULL);
        patterns[pcount].select = flag;
        if (flag == 'i') icount++;
      }
      pcount++;
    }
  }
  if (pcount == 0 || patterns != NULL) return;
  patterns = (struct plist*) malloc(pcount * sizeof(struct plist));
  if (patterns == NULL) {
    ziperr(ZE_MEM, "was creating pattern list");
#ifdef WIZZIPDLL
    return;
#endif
    }
  get_filters(argc, argv);
}

#ifndef WIZZIPDLL
int main(argc, argv)
#else
extern int zipstate;
int zipmain(argc, argv)
#endif
int argc;               /* number of tokens in command line */
char **argv;            /* command line tokens */
/* Add, update, freshen, or delete zip entries in a zip file.  See the
   command help in help() above. */
{
  int a;                /* attributes of zip file */
  ulg c;                /* start of central directory */
  int d;                /* true if just adding to a zip file */
  char *e;              /* malloc'd comment buffer */
  struct flist far *f;  /* steps through found linked list */
  int i;                /* arg counter, root directory flag */
  int k;                /* next argument type, marked counter,
                           comment size, entry count */
  ulg n;                /* total of entry len's */
  int o;                /* true if there were any ZE_OPEN errors */
  char *p;              /* steps through option arguments */
  char *pp;             /* temporary pointer */
  int r;                /* temporary variable */
  int s;                /* flag to read names from stdin */
  ulg t;                /* file time, length of central directory */
  int first_listarg = 0;/* index of first arg of "process these files" list */
  struct zlist far *v;  /* temporary variable */
  struct zlist far * far *w;    /* pointer to last link in zfiles list */
  FILE *x, *y;          /* input and output zip files */
  struct zlist far *z;  /* steps through zfiles linked list */
  char *zipbuf;         /* stdio buffer for the zip file */
  FILE *comment_stream; /* set to stderr if anything is read from stdin */

#ifdef EBCDIC
#define fprintebc(stream, str) \
{ \
  uch *asctemp;       /* temp pointer to print ascii string as ebcdic */
  asctemp = (uch *)(str); \
  while (*asctemp) { \
     putc((char)ebcdic[*asctemp], (stream)); \
     asctemp++; \
  } \
}

#endif /* EBCDIC */

#if defined(__IBMC__) && defined(__DEBUG_ALLOC__)
  {
    extern void DebugMalloc(void);
    atexit(DebugMalloc);
  }
#endif

#ifdef RISCOS
  set_prefix();
#endif

/* Re-initialize global variables to make the zip dll re-entrant. It is
 * possible that we could get away with not re-initializing all of these
 * but better safe than sorry.
 */
#ifdef WIZZIPDLL
  action = ADD; /* one of ADD, UPDATE, FRESHEN, or DELETE */
  comadd = 0;   /* 1=add comments for new files */
  zipedit = 0;  /* 1=edit zip comment and all file comments */
  latest = 0;   /* 1=set zip file time to time of latest file */
  before = 0;   /* 0=ignore, else exclude files before this time */
  test = 0;     /* 1=test zip file with unzip -t */
  tempdir = 0;  /* 1=use temp directory (-b) */
  junk_sfx = 0; /* 1=junk the sfx prefix */
  zipstate = -1;
  tempzip = NULL;
  fcount = 0;
  recurse = 0;         /* 1=recurse into directories encountered */
  dispose = 0;         /* 1=remove files after put in zip file */
  pathput = 1;         /* 1=store path with name */
  method = BEST;       /* one of BEST, DEFLATE (only), or STORE (only) */
  dosify = 0;          /* 1=make new entries look like MSDOS */
  verbose = 0;         /* 1=report oddities in zip file structure */
  fix = 0;             /* 1=fix the zip file */
  adjust = 0;          /* 1=adjust offsets for sfx'd file (keep preamble) */
  level = 6;           /* 0=fastest compression, 9=best compression */
  translate_eol = 0;   /* Translate end-of-line LF -> CR LF */
#ifdef WIN32
  use_longname_ea = 0; /* 1=use the .LONGNAME EA as the file's name */
#endif
  hidden_files = 0;    /* process hidden and system files */
  volume_label = 0;    /* add volume label */
  dirnames = 1;        /* include directory entries by default */
  linkput = 0;         /* 1=store symbolic links as such */
  noisy = 1;           /* 0=quiet operation */
  extra_fields = 1;    /* 0=do not create extra fields */
  special = ".Z:.zip:.zoo:.arc:.lzh:.arj"; /* List of special suffixes */
  key = NULL;          /* Scramble password if scrambling */
  tempath = NULL;      /* Path for temporary files */
  found = NULL;        /* where in found, or new found entry */
  fnxt = &found;
  patterns = NULL;     /* List of patterns to be matched */
  pcount = 0;          /* number of patterns */
  icount = 0;          /* number of include only patterns */
#endif /* !WIZZIPDLL */

  mesg = (FILE *) stdout; /* cannot be made at link time for VMS */
  comment_stream = (FILE *)stdin;

  init_upper();           /* build case map table */

#if (defined(AMIGA) || defined(DOS) || defined(WIN32))
  if ((p = getenv("TZ")) == NULL || *p == '\0')
    extra_fields = 0;     /* disable storing "UX" time stamps */
#endif /* AMIGA || DOS || WIN32 */

#ifdef VMSCLI
    {
        ulg status = vms_zip_cmdline(&argc, &argv);
        if (!(status & 1))
            return status;
    }
#endif /* VMSCLI */

   /* extract extended argument list from environment */
#ifndef WIZZIPDLL
   expand_args(&argc, &argv);
#endif

  /* Process arguments */
  diag("processing arguments");
  /* First, check if just the help or version screen should be displayed */
  if (isatty(1)) {              /* output screen is available */
    if (argc == 1)
    {                           /* show help screen */
      help();
#ifndef WIZZIPDLL
      EXIT(0);
#else
      return 0;
#endif
    }
    else if (argc == 2 && strcmp(argv[1], "-v") == 0)
    {                           /* show diagnostic version info */
      version_info();
#ifndef WIZZIPDLL
      EXIT(0);
#else
      return 0;
#endif
    }
  }
#ifndef WIZZIPDLL
#ifndef VMS
#  ifndef RISCOS
  envargs(&argc, &argv, "ZIPOPT", "ZIP");  /* get options from environment */
#  else /* RISCOS */
  envargs(&argc, &argv, "ZIPOPT", "Zip$Options");  /* get options from environment */
  getRISCOSexts("Zip$Exts");        /* get the extensions to swap from environment */
#  endif /* ? RISCOS */
#else /* VMS */
  envargs(&argc, &argv, "ZIPOPT", "ZIP_OPTS");  /* 4th arg for unzip compat. */
#endif /* ?VMS */
#endif /* !WIZZIPDLL */

  zipfile = tempzip = NULL;
  tempzf = NULL;
  d = 0;                        /* disallow adding to a zip file */
#ifndef WIZZIPDLL
  signal(SIGINT, handler);
#ifdef SIGTERM                  /* AMIGADOS and others have no SIGTERM */
  signal(SIGTERM, handler);
#endif
#endif /* !WIZZIPDLL */
  k = 0;                        /* Next non-option argument type */
  s = 0;                        /* set by -@ if -@ is early */

#ifndef WIZZIPDLL
  get_filters(argc, argv);      /* scan first the -x and -i patterns */
#endif /* !WIZZIPDLL */

  for (i = 1; i < argc; i++)
  {
    if (argv[i][0] == '-')
      if (argv[i][1])
        for (p = argv[i]+1; *p; p++)
          switch(*p)
          {
#ifdef EBCDIC
            case 'a':
              aflag = ASCII;
              printf("Translating to ASCII...\n");
              break;
#endif /* EBCDIC */
#ifdef CMS_MVS
            case 'B':
              bflag = 1;
              printf("Using binary mode...\n");
              break;
#endif /* CMS_MVS */
            case '0':
              method = STORE; level = 0; break;
            case '1':  case '2':  case '3':  case '4':
            case '5':  case '6':  case '7':  case '8':  case '9':
                        /* Set the compression efficacy */
              level = *p - '0';  break;
            case 'A':   /* Adjust unzipsfx'd zipfile:  adjust offsets only */
              adjust = 1; break;
            case 'b':   /* Specify path for temporary file */
              tempdir = 1;
              if (k != 0) {
                ziperr(ZE_PARMS, "use -b before zip file name");
#ifdef WIZZIPDLL
                return 0;
#endif
              }
              else
                k = 1;          /* Next non-option is path */
              break;
            case 'c':   /* Add comments for new files in zip file */
              comadd = 1;  break;
            case 'd':   /* Delete files from zip file */
              if (action != ADD) {
                ziperr(ZE_PARMS, "specify just one action");
#ifdef WIZZIPDLL
                return 0;
#endif
              }
              action = DELETE;
              break;
            case 'D':   /* Do not add directory entries */
              dirnames = 0; break;
            case 'e':   /* Encrypt */
#ifndef CRYPT
              ziperr(ZE_PARMS, "encryption not supported");
#ifdef WIZZIPDLL
              return 0;
#endif
#else /* CRYPT */
              if (key == NULL) {
                if ((key = malloc(PWLEN+1)) == NULL) {
                  ziperr(ZE_MEM, "was getting encryption password");
#ifdef WIZZIPDLL
                  return 0;
#endif
                }
                if (getp("Enter password: ", key, PWLEN+1) == NULL) {
                  ziperr(ZE_PARMS, "stderr is not a tty");
#ifdef WIZZIPDLL
                  return 0;
#endif
                }
                if ((e = malloc(PWLEN+1)) == NULL) {
                  ziperr(ZE_MEM, "was verifying encryption password");
#ifdef WIZZIPDLL
                  return 0;
#endif
                }
                if (getp("Verify password: ", e, PWLEN+1) == NULL) {
                  ziperr(ZE_PARMS, "stderr is not a tty");
#ifdef WIZZIPDLL
                  return 0;
#endif
                }
                r = strcmp(key, e);
                free((zvoid *)e);
                if (r) {
                  ziperr(ZE_PARMS, "password verification failed");
#ifdef WIZZIPDLL
                  return 0;
#endif
                }
                if (*key == '\0') {
                  ziperr(ZE_PARMS, "zero length password not allowed");
#ifdef WIZZIPDLL
                  return 0;
#endif
                }
              }
#endif /* ?CRYPT */
              break;
            case 'F':   /* fix the zip file */
              fix++; break;
            case 'f':   /* Freshen zip file--overwrite only */
              if (action != ADD) {
                ziperr(ZE_PARMS, "specify just one action");
#ifdef WIZZIPDLL
                return 0;
#endif
              }
              action = FRESHEN;
              break;
            case 'g':   /* Allow appending to a zip file */
              d = 1;  break;
            case 'h': case 'H': case '?':  /* Help */
              help();
              finish(ZE_OK);
#ifdef WIZZIPDLL
              return 0;
#endif
#ifdef RISCOS
            case 'I':   /* Don't scan through Image files */
              scanimage = 0;
              break;
#endif
            case 'j':   /* Junk directory names */
              pathput = 0;  break;
            case 'J':   /* Junk sfx prefix */
              junk_sfx = 1;  break;
            case 'k':   /* Make entries using DOS names (k for Katz) */
              dosify = 1;  break;
            case 'l':   /* Translate end-of-line */
              translate_eol++; break;
            case 'L':   /* Show license */
              license();
              finish(ZE_OK);
#ifdef WIZZIPDLL
              return 0;
#endif
            case 'm':   /* Delete files added or updated in zip file */
              dispose = 1;  break;
            case 'n':   /* Don't compress files with a special suffix */
              special = NULL; /* will be set at next argument */
              break;
#ifdef AMIGA
            case 'N':   /* Get zipfile comments from AmigaDOS filenotes */
              filenotes = 1; break;
#endif
            case 'o':   /* Set zip file time to time of latest file in it */
              latest = 1;  break;
            case 'p':   /* Store path with name */
              break;            /* (do nothing as annoyance avoidance) */
            case 'q':   /* Quiet operation */
              noisy = 0;
              if (verbose) verbose--;
              break;
            case 'r':   /* Recurse into subdirectories */
              recurse = 1;  break;
#if defined(MSDOS) || defined(OS2) || defined(WIN32) || defined (ATARI)
            case 'S':
              hidden_files = 1; break;
#endif /* MSDOS || OS2 || WIN32 || ATARI */
            case 't':   /* Exclude files earlier than specified date */
              if (before) {
                ziperr(ZE_PARMS, "can only have one -t");
#ifdef WIZZIPDLL
                return 0;
#endif
              }
              k = 2;  break;
            case 'T':   /* test zip file */
              test = 1; break;
            case 'u':   /* Update zip file--overwrite only if newer */
              if (action != ADD) {
                ziperr(ZE_PARMS, "specify just one action");
#ifdef WIZZIPDLL
                return 0;
#endif
              }
              action = UPDATE;
              break;
            case 'v':   /* Mention oddities in zip file structure */
              noisy = 1;
              verbose++;
              break;
#ifdef VMS
            case 'V':   /* Store in VMS format */
              vms_native = 1; break;
            case 'w':   /* Append the VMS version number */
              vmsver = 1;  break;
#endif /* VMS */
            case 'i':   /* Include only the following files */
            case 'x':   /* Exclude following files */
              if (k != 4 &&
                  (k != 3 || (action != UPDATE && action != FRESHEN))) {
                ziperr(ZE_PARMS, "nothing to select from");
#ifdef WIZZIPDLL
                return 0;
#endif
              }
              k = 5;
              break;
#ifdef S_IFLNK
            case 'y':   /* Store symbolic links as such */
              linkput = 1;  break;
#endif /* S_IFLNK */
            case 'z':   /* Edit zip file comment */
              zipedit = 1;  break;
#if defined(MSDOS) || defined(OS2)
            case '$':   /* Include volume label */
              volume_label = 1; break;
#endif
            case '@':   /* read file names from stdin */
              comment_stream = NULL;
              if (k < 3)        /* zip file not read yet */
                s = 1;          /* defer -@ until after zipfile read */
              else if (strcmp(zipfile, "-") == 0) {
                ziperr(ZE_PARMS, "can't use - and -@ together");
#ifdef WIZZIPDLL
                return 0;
#endif
              }
              else              /* zip file read--do it now */
                while ((pp = getnam(errbuf)) != NULL)
                {
                  k = 4;
                  if ((r = PROCNAME(pp)) != ZE_OK)
                    if (r == ZE_MISS)
                      zipwarn("name not matched: ", pp);
                    else {
                      ziperr(r, pp);
#ifdef WIZZIPDLL
                      return 0;
#endif
                    }
              }
              break;
            case 'X':
              extra_fields = 0;
              break;
#ifdef OS2
            case 'E':
              /* use the .LONGNAME EA (if any) as the file's name. */
              use_longname_ea = 1;
              break;
#endif
            default:
            {
              sprintf(errbuf, "no such option: %c", *p);
              ziperr(ZE_PARMS, errbuf);
#ifdef WIZZIPDLL
              return 0;
#endif
            }
          }
      else              /* just a dash */
        switch (k)
        {
        case 0:
          zipstdout();
          k = 3;
          if (s) {
            ziperr(ZE_PARMS, "can't use - and -@ together");
#ifdef WIZZIPDLL
            return 0;
#endif
          }
          break;
        case 1:
          ziperr(ZE_PARMS, "invalid path");
#ifdef WIZZIPDLL
          return 0;
#else
          break;
#endif
        case 2:
          ziperr(ZE_PARMS, "invalid time");
#ifdef WIZZIPDLL
          return 0;
#else
          break;
#endif
        case 3:  case 4:
          comment_stream = NULL;
          if ((r = PROCNAME(argv[i])) != ZE_OK)
            if (r == ZE_MISS)
              zipwarn("name not matched: ", argv[i]);
            else {
              ziperr(r, argv[i]);
#ifdef WIZZIPDLL
              return 0;
#endif
            }
          if (k == 3) {
            first_listarg = i;
            k = 4;
          }
        }
    else                /* not an option */
    {
      if (special == NULL)
        special = argv[i];
      else if (k == 5)
        break; /* -i and -x arguments already scanned */
      else switch (k)
      {
        case 0:
          if ((zipfile = ziptyp(argv[i])) == NULL) {
            ziperr(ZE_MEM, "was processing arguments");
#ifdef WIZZIPDLL
            return 0;
#endif
          }
          if ((r = readzipfile()) != ZE_OK) {
            ziperr(r, zipfile);
#ifdef WIZZIPDLL
            return 0;
#endif
          }
          k = 3;
          if (s)
          {
            while ((pp = getnam(errbuf)) != NULL)
            {
              k = 4;
              if ((r = PROCNAME(pp)) != ZE_OK)
                if (r == ZE_MISS)
                  zipwarn("name not matched: ", pp);
                else {
                  ziperr(r, pp);
#ifdef WIZZIPDLL
                  return 0;
#endif
                }
            }
            s = 0;
          }
          break;
        case 1:
          if ((tempath = malloc(strlen(argv[i]) + 1)) == NULL) {
            ziperr(ZE_MEM, "was processing arguments");
#ifdef WIZZIPDLL
            return 0;
#endif
          }
          strcpy(tempath, argv[i]);
          k = 0;
          break;
        case 2:
        {
          int yy, mm, dd;       /* results of sscanf() */

          if (sscanf(argv[i], "%2d%2d%2d", &mm, &dd, &yy) != 3 ||
              mm < 1 || mm > 12 || dd < 1 || dd > 31) {
            ziperr(ZE_PARMS, "invalid date entered for -t option");
#ifdef WIZZIPDLL
            return 0;
#endif
          }
          before = dostime(yy + (yy < 80 ? 2000 : 1900), mm, dd, 0, 0, 0);
          k = 0;
          break;
        }
        case 3:  case 4:
          if ((r = PROCNAME(argv[i])) != ZE_OK)
            if (r == ZE_MISS)
              zipwarn("name not matched: ", argv[i]);
            else {
              ziperr(r, argv[i]);
#ifdef WIZZIPDLL
              return 0;
#endif
            }
          if (k == 3) {
            first_listarg = i;
            k = 4;
          }
      }
    }
  }
#if (defined(MSDOS) || defined(OS2)) && !defined(WIN32)
  if ((k == 3 || k == 4) && volume_label == 1) {
    PROCNAME(NULL);
    k = 4;
  }
#endif
  if (k < 3) {               /* zip used as filter */
    zipstdout();
    comment_stream = NULL;
    if ((r = procname("-")) != ZE_OK)
      if (r == ZE_MISS)
        zipwarn("name not matched: ", "-");
      else {
        ziperr(r, "-");
#ifdef WIZZIPDLL
        return 0;
#endif
      }
    k = 4;
    if (s) {
      ziperr(ZE_PARMS, "can't use - and -@ together");
#ifdef WIZZIPDLL
      return 0;
#endif
    }
  }

  /* Clean up selections ("3 <= k <= 5" now) */
  if (k != 4 && first_listarg == 0 &&
      (action == UPDATE || action == FRESHEN)) {
    /* if -u or -f with no args, do all, but, when present, apply filters */
    for (z = zfiles; z != NULL; z = z->nxt) {
      z->mark = pcount ? filter(z->zname) : 1;
    }
  }
  if ((r = check_dup()) != ZE_OK)     /* remove duplicates in found list */
    if (r == ZE_PARMS) {
      ziperr(r, "cannot repeat names in zip file");
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    else {
      ziperr(r, "was processing list of files");
#ifdef WIZZIPDLL
      return 0;
#endif
    }

  if (zcount)
    free((zvoid *)zsort);

  /* Check option combinations */
  if (special == NULL) {
    ziperr(ZE_PARMS, "missing suffix list");
#ifdef WIZZIPDLL
    return 0;
#endif
  }
  if (level == 9 || !strcmp(special, ";") || !strcmp(special, ":"))
    special = NULL; /* compress everything */

  if (action == DELETE && (method != BEST || dispose || recurse ||
      key != NULL || comadd || zipedit)) {
    ziperr(ZE_PARMS, "invalid option(s) used with -d");
#ifdef WIZZIPDLL
    return 0;
#endif
  }
  if (linkput && dosify)
    {
      zipwarn("can't use -y with -k, -y ignored", "");
      linkput = 0;
    }
  if (fix && adjust)
    {
      zipwarn("can't use -F with -A, -F ignored", "");
    }
  if (test && !strcmp(zipfile, "-")) {
    test = 0;
    zipwarn("can't use -T on stdout, -T ignored", "");
  }
  if ((action != ADD || d) && !strcmp(zipfile, "-")) {
    ziperr(ZE_PARMS, "can't use -d,-f,-u or -g on stdout\n");
#ifdef WIZZIPDLL
    return 0;
#endif
  }
#ifdef EBCDIC
  if (aflag && !translate_eol) {
    /* Translation to ASCII implies EOL translation!
     * The default translation mode is "UNIX" mode (single LF terminators).
     */
    translate_eol = 1;
  }
#endif
#ifdef CMS_MVS
  if (aflag && bflag)
    ziperr(ZE_PARMS, "can't use -a with -B");
#endif
#ifdef VMS
  if (!extra_fields && vms_native)
    {
      zipwarn("can't use -V with -X, -V ignored", "");
      vms_native = 0;
    }
  if (vms_native && translate_eol)
    ziperr(ZE_PARMS, "can't use -V with -l");
#endif
  if (zcount == 0 && (action != ADD || d)) {
    zipwarn(zipfile, " not found or empty");
#ifdef WIZZIPDLL
    return 0;
#endif
  }


  /* If -b not specified, make temporary path the same as the zip file */
#if defined(MSDOS) || defined(__human68k__) || defined(AMIGA)
  if (tempath == NULL && ((p = strrchr(zipfile, '/')) != NULL ||
#  ifdef MSDOS
                          (p = strrchr(zipfile, '\\')) != NULL ||
#  endif
                          (p = strrchr(zipfile, ':')) != NULL))
  {
    if (*p == ':')
      p++;
#else
#  ifdef RISCOS
  if (tempath == NULL && (p = strrchr(zipfile, '.')) != NULL)
  {
#  else
  if (tempath == NULL && (p = strrchr(zipfile, '/')) != NULL)
  {
#  endif
#endif
    if ((tempath = malloc((int)(p - zipfile) + 1)) == NULL) {
      ziperr(ZE_MEM, "was processing arguments");
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    r = *p;  *p = 0;
    strcpy(tempath, zipfile);
    *p = (char)r;
  }

  /* For each marked entry, if not deleting, check if it exists, and if
     updating or freshening, compare date with entry in old zip file.
     Unmark if it doesn't exist or is too old, else update marked count. */
  diag("stating marked entries");
  k = 0;                        /* Initialize marked count */
  for (z = zfiles; z != NULL; z = z->nxt)
    if (z->mark) {
#ifdef USE_EF_UX_TIME
      ztimbuf f_utim, z_utim;
#endif /* USE_EF_UX_TIME */

      if (action != DELETE &&
#ifdef USE_EF_UX_TIME
          ((t = filetime(z->name, (ulg *)NULL, (long *)NULL, &f_utim))
#else /* !USE_EF_UX_TIME */
          ((t = filetime(z->name, (ulg *)NULL, (long *)NULL, (ztimbuf *)NULL))
#endif /* ?USE_EF_UX_TIME */
              == 0 ||
           t < before ||
           ((action == UPDATE || action == FRESHEN) &&
#ifdef USE_EF_UX_TIME
            (get_ef_ux_ztime(z, &z_utim) ?
             f_utim.modtime <= z_utim.modtime : t <= z->tim)
#else /* !USE_EF_UX_TIME */
            t <= z->tim
#endif /* ?USE_EF_UX_TIME */
           )))
      {
        z->mark = comadd ? 2 : 0;
        z->trash = t && t >= before;    /* delete if -um or -fm */
        if (verbose) {
          fprintf(mesg, "zip diagnostic: %s %s\n", z->name,
                 z->trash ? "up to date" : "missing or early");
        }
      }
      else
        k++;
    }

  /* Remove entries from found list that do not exist or are too old */
  diag("stating new entries");
  for (f = found; f != NULL;)
    if (action == DELETE || action == FRESHEN ||
        (t = filetime(f->name, (ulg *)NULL, (long *)NULL, (ztimbuf *)NULL))
           == 0 ||
        t < before || (namecmp(f->name, zipfile) == 0 && strcmp(zipfile, "-")))
      f = fexpel(f);
    else
      f = f->nxt;

  /* Make sure there's something left to do */
  if (k == 0 && found == NULL &&
      !(zfiles != NULL &&
        (latest || fix || adjust || junk_sfx || comadd || zipedit))) {
    if (test && (zfiles != NULL || zipbeg != 0)) {
      check_zipfile(zipfile, argv[0]);
      finish(ZE_OK);
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    if (action == UPDATE || action == FRESHEN) {
      finish(ZE_OK);
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    else if (zfiles == NULL && (latest || fix || adjust || junk_sfx)) {
      ziperr(ZE_NAME, zipfile);
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    else if (recurse && (pcount == 0) && (first_listarg > 0)) {
#ifdef VMS
      strcpy(errbuf, "try: zip \"");
      for (i = 1; i < (first_listarg - 1); i++)
        strcat(strcat(errbuf, argv[i]), "\" ");
      strcat(strcat(errbuf, argv[i]), " *.* -i");
#else /* !VMS */
      strcpy(errbuf, "try: zip");
      for (i = 1; i < first_listarg; i++)
        strcat(strcat(errbuf, " "), argv[i]);
#  ifdef AMIGA
      strcat(errbuf, " \"\" -i");
#  else
      strcat(errbuf, " . -i");
#  endif
#endif /* ?VMS */
      for (i = first_listarg; i < argc; i++)
        strcat(strcat(errbuf, " "), argv[i]);
      ziperr(ZE_NONE, errbuf);
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    else {
      ziperr(ZE_NONE, zipfile);
#ifdef WIZZIPDLL
      return 0;
#endif
    }
  }
  d = (d && k == 0 && (zipbeg || zfiles != NULL)); /* d true if appending */

#ifdef CRYPT
  /* Initialize the crc_32_tab pointer, when encryption was requested. */
  if (key != NULL)
    crc_32_tab = (ulg near *)get_crc_table();
#endif /* CRYPT */

  /* Before we get carried away, make sure zip file is writeable. This
   * has the undesired side effect of leaving one empty junk file on a WORM,
   * so when the zipfile does not exist already and when -b is specified,
   * the writability check is made in replace().
   */
  if (strcmp(zipfile, "-"))
  {
    if (tempdir && zfiles == NULL && zipbeg == 0) {
      a = 0;
    } else {
       x = zfiles == NULL && zipbeg == 0 ? fopen(zipfile, FOPW) :
                                           fopen(zipfile, FOPM);
      /* Note: FOPW and FOPM expand to several parameters for VMS */
      if (x == NULL) {
        ziperr(ZE_CREAT, zipfile);
#ifdef WIZZIPDLL
        return 0;
#endif
      }
      fclose(x);
      a = getfileattr(zipfile);
      if (zfiles == NULL && zipbeg == 0)
        destroy(zipfile);
    }
  }
  else
    a = 0;

  /* Throw away the garbage in front of the zip file for -J */
  if (junk_sfx) zipbeg = 0;

  /* Open zip file and temporary output file */
  diag("opening zip file and creating temporary zip file");
  x = NULL;
  tempzn = 0;
  if (strcmp(zipfile, "-") == 0)
  {
#if defined(MSDOS) || defined(__human68k__)
    /* Set stdout mode to binary for MSDOS systems */
#  ifdef __HIGHC__
    setmode(stdout, _BINARY);
#  else
    setmode(fileno(stdout), O_BINARY);
#  endif
    tempzf = y = fdopen(fileno(stdout), FOPW);
#else
    tempzf = y = stdout;
#endif
    /* tempzip must be malloced so a later free won't barf */
    tempzip = malloc(4);
    if (tempzip == NULL) {
      ziperr(ZE_MEM, "allocating temp filename");
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    strcpy(tempzip, "-");
  }
  else if (d) /* d true if just appending (-g) */
  {
    if ((y = fopen(zipfile, FOPM)) == NULL) {
      ziperr(ZE_NAME, zipfile);
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    tempzip = zipfile;
    tempzf = y;
    if (fseek(y, cenbeg, SEEK_SET)) {
      ziperr(ferror(y) ? ZE_READ : ZE_EOF, zipfile);
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    tempzn = cenbeg;
  }
  else
  {
    if ((zfiles != NULL || zipbeg) && (x = fopen(zipfile, FOPR_EX)) == NULL) {
      ziperr(ZE_NAME, zipfile);
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    if ((tempzip = tempname(zipfile)) == NULL) {
      ziperr(ZE_MEM, "allocating temp filename");
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    if ((tempzf = y = fopen(tempzip, FOPW)) == NULL) {
      ziperr(ZE_TEMP, tempzip);
#ifdef WIZZIPDLL
      return 0;
#endif
    }
  }

#if !defined(VMS) && !defined(CMS_MVS)
  /* Use large buffer to speed up stdio: */
  zipbuf = (char *)malloc(ZBSZ);
  if (zipbuf == NULL) {
    ziperr(ZE_MEM, tempzip);
#ifdef WIZZIPDLL
    return 0;
#endif
  }
# ifdef _IOFBF
  setvbuf(y, zipbuf, _IOFBF, ZBSZ);
# else
  setbuf(y, zipbuf);
# endif /* _IOBUF */
#endif /* !VMS  && !CMS_MVS */

  if (strcmp(zipfile, "-") != 0 && !d)  /* this must go *after* set[v]buf */
  {
    if (zipbeg && (r = fcopy(x, y, zipbeg)) != ZE_OK) {
      ziperr(r, r == ZE_TEMP ? tempzip : zipfile);
#ifdef WIZZIPDLL
      return 0;
#endif
      }
    tempzn = zipbeg;
  }

  o = 0;                                /* no ZE_OPEN errors yet */


  /* Process zip file, updating marked files */
#ifdef DEBUG
  if (zfiles != NULL)
    diag("going through old zip file");
#endif
  w = &zfiles;
  while ((z = *w) != NULL)
    if (z->mark == 1)
    {
      /* if not deleting, zip it up */
      if (action != DELETE)
      {
        if (noisy)
        {
#ifdef EBCDIC
          fprintf(mesg, "updating: "); fprintebc(mesg, z->zname);
#else /* !EBCDIC */
          fprintf(mesg, "updating: %s", z->zname);
#endif /* ?EBCDIC */
          fflush(mesg);
        }
        if ((r = zipup(z, y)) != ZE_OK && r != ZE_OPEN && r != ZE_MISS)
        {
          if (noisy)
          {
            putc('\n', mesg);
            fflush(mesg);
          }
          sprintf(errbuf, "was zipping %s", z->name);
          ziperr(r, errbuf);
#ifdef WIZZIPDLL
          return 0;
#endif
        }
        if (r == ZE_OPEN || r == ZE_MISS)
        {
          o = 1;
          if (noisy)
          {
            putc('\n', mesg);
            fflush(mesg);
          }
          if (r == ZE_OPEN) {
            perror("zip warning");
            zipwarn("could not open for reading: ", z->name);
          } else {
            zipwarn("file and directory with the same name: ", z->name);
          }
          zipwarn("will just copy entry over: ", z->zname);
          if ((r = zipcopy(z, x, y)) != ZE_OK)
          {
            sprintf(errbuf, "was copying %s", z->zname);
            ziperr(r, errbuf);
#ifdef WIZZIPDLL
            return 0;
#endif
          }
          z->mark = 0;
        }
        w = &z->nxt;
      }
      else
      {
        if (noisy)
        {
#ifdef EBCDIC
          fprintf(mesg, "deleting: ");
          fprintebc(mesg, z->zname);
          fprintf(mesg, "\n");
#else /* !EBCDIC */
          fprintf(mesg, "deleting: %s\n", z->zname);
#endif /* ?EBCDIC */
          fflush(mesg);
        }
        v = z->nxt;                     /* delete entry from list */
        free((zvoid *)(z->name));
        free((zvoid *)(z->zname));
        if (z->ext)
          free((zvoid *)(z->extra));
        if (z->cext && z->cextra != z->extra)
          free((zvoid *)(z->cextra));
        if (z->com)
          free((zvoid *)(z->comment));
        farfree((zvoid far *)z);
        *w = v;
        zcount--;
      }
    }
    else
    {
      /* copy the original entry verbatim */
      if (!d && (r = zipcopy(z, x, y)) != ZE_OK)
      {
        sprintf(errbuf, "was copying %s", z->zname);
        ziperr(r, errbuf);
#ifdef WIZZIPDLL
        return 0;
#endif
      }
      w = &z->nxt;
    }


  /* Process the edited found list, adding them to the zip file */
  diag("zipping up new entries, if any");
  for (f = found; f != NULL; f = fexpel(f))
  {
    /* add a new zfiles entry and set the name */
    if ((z = (struct zlist far *)farmalloc(sizeof(struct zlist))) == NULL) {
      ziperr(ZE_MEM, "was adding files to zip file");
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    z->nxt = NULL;
    z->name = f->name;
    f->name = NULL;
    z->zname = f->zname;
    f->zname = NULL;
    z->ext = z->cext = z->com = 0;
    z->extra = z->cextra = NULL;
    z->mark = 1;
    z->dosflag = f->dosflag;
    /* zip it up */
    if (noisy)
    {
#ifdef EBCDIC
      fprintf(mesg, "  adding: "); fprintebc(mesg, z->zname);
#else /* !EBCDIC */
      fprintf(mesg, "  adding: %s", z->zname);
#endif /* ?EBCDIC */
      fflush(mesg);
    }
    if ((r = zipup(z, y)) != ZE_OK  && r != ZE_OPEN && r != ZE_MISS)
    {
      if (noisy)
      {
        putc('\n', mesg);
        fflush(mesg);
      }
      sprintf(errbuf, "was zipping %s", z->name);
      ziperr(r, errbuf);
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    if (r == ZE_OPEN || r == ZE_MISS)
    {
      o = 1;
      if (noisy)
      {
        putc('\n', mesg);
        fflush(mesg);
      }
      if (r == ZE_OPEN) {
        perror("zip warning");
        zipwarn("could not open for reading: ", z->name);
      } else {
        zipwarn("file and directory with the same name: ", z->name);
      }
      free((zvoid *)(z->name));
      free((zvoid *)(z->zname));
      farfree((zvoid far *)z);
    }
    else
    {
      *w = z;
      w = &z->nxt;
      zcount++;
    }
  }
  if (key != NULL)
  {
    free((zvoid *)key);
    key = NULL;
  }


  /* Get one line comment for each new entry */
#ifdef AMIGA
  if (comadd || filenotes)
  {
    if (comadd)
#else
  if (comadd)
  {
#endif
    {
      if (comment_stream == NULL) {
#ifndef RISCOS
        comment_stream = (FILE*)fdopen(fileno(stderr), "r");
#else
        comment_stream = stderr;
#endif
      }
      if ((e = malloc(MAXCOM + 1)) == NULL) {
        ziperr(ZE_MEM, "was reading comment lines");
#ifdef WIZZIPDLL
        return 0;
#endif
      }
    }
    for (z = zfiles; z != NULL; z = z->nxt)
      if (z->mark)
#ifdef AMIGA
        if (filenotes && (p = GetComment(z->name)))
        {
          if (z->comment = malloc(k = strlen(p)+1))
          {
            z->com = k;
            strcpy(z->comment, p);
          }
          else
          {
            free((zvoid *)e);
            ziperr(ZE_MEM, "was reading filenotes");
#ifdef WIZZIPDLL
            return 0;
#endif
          }
        }
        else if (comadd)
#endif
        {
          if (noisy)
            fprintf(mesg, "Enter comment for %s:\n", z->name);
          if (fgets(e, MAXCOM+1, comment_stream) != NULL)
          {
            if ((p = malloc((k = strlen(e))+1)) == NULL)
            {
              free((zvoid *)e);
              ziperr(ZE_MEM, "was reading comment lines");
#ifdef WIZZIPDLL
              return 0;
#endif
          }
            strcpy(p, e);
            if (p[k-1] == '\n')
              p[--k] = 0;
            z->comment = p;
            z->com = k;
          }
        }
#ifdef AMIGA
    if (comadd)
      free((zvoid *)e);
    GetComment(NULL);           /* makes it free its internal storage */
#else
    free((zvoid *)e);
#endif
  }

  /* Get multi-line comment for the zip file */
  if (zipedit)
  {
    if (comment_stream == NULL) {
#ifndef RISCOS
      comment_stream = (FILE*)fdopen(fileno(stderr), "r");
#else
      comment_stream = stderr;
#endif
    }
    if ((e = malloc(MAXCOM + 1)) == NULL) {
      ziperr(ZE_MEM, "was reading comment lines");
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    if (noisy && zcomlen)
    {
      fputs("current zip file comment is:\n", mesg);
#ifdef EBCDIC
      strtoebc(zcomment,zcomment);
#endif
      fwrite(zcomment, 1, zcomlen, mesg);
      if (zcomment[zcomlen-1] != '\n')
        putc('\n', mesg);
      free((zvoid *)zcomment);
    }
    zcomment = malloc(1);
    *zcomment = 0;
    if (noisy)
      fputs("enter new zip file comment (end with .):\n", mesg);
#if (defined(AMIGA) && (defined(LATTICE)||defined(__SASC)))
    flushall();  /* tty input/output is out of sync here */
#endif
    while (fgets(e, MAXCOM+1, comment_stream) != NULL && strcmp(e, ".\n"))
    {
      if (e[(r = strlen(e)) - 1] == '\n')
        e[--r] = 0;
      if ((p = malloc((*zcomment ? strlen(zcomment) + 3 : 1) + r)) == NULL)
      {
        free((zvoid *)e);
        ziperr(ZE_MEM, "was reading comment lines");
#ifdef WIZZIPDLL
        return 0;
#endif
      }
      if (*zcomment)
        strcat(strcat(strcpy(p, zcomment), "\r\n"), e);
      else
        strcpy(p, *e ? e : "\r\n");
      free((zvoid *)zcomment);
      zcomment = p;
    }
#ifdef EBCDIC
    strtoasc(zcomment,zcomment);
#endif
    zcomlen = strlen(zcomment);
    free((zvoid *)e);
  }


  /* Write central directory and end header to temporary zip */
  diag("writing central directory");
  k = 0;                        /* keep count for end header */
  c = tempzn;                   /* get start of central */
  n = t = 0;
  for (z = zfiles; z != NULL; z = z->nxt)
  {
    if ((r = putcentral(z, y)) != ZE_OK) {
      ziperr(r, tempzip);
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    tempzn += 4 + CENHEAD + z->nam + z->cext + z->com;
    n += z->len;
    t += z->siz;
    k++;
  }
  if (k == 0)
    zipwarn("zip file empty", "");
  if (verbose)
    fprintf(mesg, "total bytes=%lu, compressed=%lu -> %d%% savings\n",
           n, t, percent(n, t));
  t = tempzn - c;               /* compute length of central */
  diag("writing end of central directory");
  if ((r = putend(k, t, c, zcomlen, zcomment, y)) != ZE_OK) {
    ziperr(r, tempzip);
#ifdef WIZZIPDLL
    return 0;
#endif
  }
  tempzf = NULL;
  if (fclose(y)) {
    ziperr(d ? ZE_WRITE : ZE_TEMP, tempzip);
#ifdef WIZZIPDLL
    return 0;
#endif
  }
  if (x != NULL)
    fclose(x);

  /* Free some memory before spawning unzip */
  lm_free();

  /* Test new zip file before overwriting old one or removing input files */
  if (test) {
    check_zipfile(tempzip, argv[0]);
  }
  /* Replace old zip file with new zip file, leaving only the new one */
  if (strcmp(zipfile, "-") && !d)
  {
    diag("replacing old zip file with new zip file");
    if ((r = replace(zipfile, tempzip)) != ZE_OK)
    {
      zipwarn("new zip file left as: ", tempzip);
      free((zvoid *)tempzip);
      tempzip = NULL;
      ziperr(r, "was replacing the original zip file");
#ifdef WIZZIPDLL
      return 0;
#endif
    }
    free((zvoid *)tempzip);
  }
  tempzip = NULL;
  if (a && strcmp(zipfile, "-")) {
    setfileattr(zipfile, a);
#ifdef VMS
    /* If the zip file existed previously, restore its record format: */
    if (x != NULL)
      (void)VMSmunch(zipfile, RESTORE_RTYPE, NULL);
#endif
  }

#ifdef RISCOS
  /* Set the filetype of the zipfile to &DDC */
  setfiletype(zipfile,0xDDC);
#endif

  /* Finish up (process -o, -m, clean up).  Exit code depends on o. */
  finish(o ? ZE_OPEN : ZE_OK);
  return 0; /* just to avoid compiler warning */
}
