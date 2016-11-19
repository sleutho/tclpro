/*

 Copyright (C) 1990-1996 Mark Adler, Richard B. Wales, Jean-loup Gailly,
 Kai Uwe Rommel, Onno van der Linden and Igor Mandrichenko.
 Permission is granted to any individual or institution to use, copy, or
 redistribute this software so long as all of the original files are included,
 that it is not sold for profit, and that this copyright notice is retained.

*/

#ifndef UTIL    /* this file contains nothing used by UTIL */

#include "zip.h"

#include <direct.h>     /* for rmdir() */
#include <time.h>

#ifndef __BORLANDC__
#include <sys/utime.h>
#else
#include <utime.h>
#endif
#include <windows.h> /* for findfirst/findnext stuff */
char *GetLongPathEA OF((char *name));

#include <io.h>
#define MATCH         shmatch

#define PAD           0
#define PATH_END      '/'
#define HIDD_SYS_BITS (FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM)


typedef struct zdirent {
  ush    d_date, d_time;
  ulg    d_size;
  char   d_attr;
  char   d_name[MAX_PATH];
  int    d_first;
  HANDLE d_hFindFile;
} zDIR;

#include "win32/win32zip.h"

/* Local functions */
local zDIR           *Opendir  OF((const char *));
local struct zdirent *Readdir  OF((zDIR *));
local void            Closedir OF((zDIR *));

local char           *readd    OF((zDIR *));

/* Module level variables */
extern char *label /* = NULL */ ;       /* defined in fileio.c */
local ulg label_time = 0;
local ulg label_mode = 0;
local time_t label_utim = 0;

/* Module level constants */
local const char wild_match_all[] = "*.*";

local zDIR *Opendir(n)
const char *n;          /* directory to open */
/* Start searching for files in the MSDOS directory n */
{
  zDIR *d;              /* malloc'd return value */
  char *p;              /* malloc'd temporary string */
  char *q;
  WIN32_FIND_DATA fd;

  if ((d = (zDIR *)malloc(sizeof(zDIR))) == NULL ||
      (p = malloc(strlen(n) + 5)) == NULL) {
    if (d != NULL) free((zvoid *)d);
    return NULL;
  }
  strcpy(p, n);
  q = p + strlen(p);
  if ((q - p) > 0 && *(q - 1) != '/')
    *q++ = '/';
  strcpy(q, wild_match_all);

  d->d_hFindFile = FindFirstFile(p, &fd);
  free((zvoid *)p);

  if (d->d_hFindFile == INVALID_HANDLE_VALUE)
  {
    free((zvoid *)d);
    return NULL;
  }

  strcpy(d->d_name, fd.cFileName);
  d->d_attr = (unsigned char) fd.dwFileAttributes;
  d->d_first = 1;
  return d;
}

local struct zdirent *Readdir(d)
zDIR *d;                /* directory stream to read from */
/* Return pointer to first or next directory entry, or NULL if end. */
{
  if (d->d_first)
    d->d_first = 0;
  else
  {
    WIN32_FIND_DATA fd;

    if (!FindNextFile(d->d_hFindFile, &fd))
        return NULL;
    strcpy(d->d_name, fd.cFileName);
    d->d_attr = (unsigned char) fd.dwFileAttributes;
  }
  return (struct zdirent *)d;
}

local void Closedir(d)
zDIR *d;                /* directory stream to close */
{
  FindClose(d->d_hFindFile);
  free((zvoid *)d);
}


local char *readd(d)
zDIR *d;                /* directory stream to read from */
/* Return a pointer to the next name in the directory stream d, or NULL if
   no more entries or an error occurs. */
{
  struct zdirent *e;

  do
    e = Readdir(d);
  while (!hidden_files && e && e->d_attr & HIDD_SYS_BITS);
  return e == NULL ? (char *) NULL : e->d_name;
}

int wild(w)
char *w;                /* path/pattern to match */
/* If not in exclude mode, expand the pattern based on the contents of the
   file system.  Return an error code in the ZE_ class. */
{
  zDIR *d;              /* stream for reading directory */
  char *e;              /* name found in directory */
  int r;                /* temporary variable */
  char *n;              /* constructed name from directory */
  int f;                /* true if there was a match */
  char *a;              /* alloc'ed space for name */
  char *p;              /* path */
  char *q;              /* name */
  char v[5];            /* space for device current directory */

  /* special handling of stdin request */
  if (strcmp(w, "-") == 0)   /* if compressing stdin */
    return newname(w, 0);

  /* Allocate and copy pattern */
  if ((p = a = malloc(strlen(w) + 1)) == NULL)
    return ZE_MEM;
  strcpy(p, w);

  /* Normalize path delimiter as '/'. */
  for (q = p; *q; q++)                  /* use / consistently */
    if (*q == '\\')
      *q = '/';

  /* Only name can have special matching characters */
  if ((q = isshexp(p)) != NULL &&
      (strrchr(q, '/') != NULL || strrchr(q, ':') != NULL))
  {
    free((zvoid *)a);
    return ZE_PARMS;
  }

  /* Separate path and name into p and q */
  if ((q = strrchr(p, '/')) != NULL && (q == p || q[-1] != ':'))
  {
    *q++ = '\0';                        /* path/name -> path, name */
    if (*p == '\0')                     /* path is just / */
      p = strcpy(v, "/.");
  }
  else if ((q = strrchr(p, ':')) != NULL)
  {                                     /* has device and no or root path */
    *q++ = '\0';
    p = strcat(strcpy(v, p), ":");      /* copy device as path */
    if (*q == '/')                      /* -> device:/., name */
    {
      strcat(p, "/");
      q++;
    }
    strcat(p, ".");
  }
  else if (recurse && (strcmp(p, ".") == 0 ||  strcmp(p, "..") == 0))
  {                                    /* current or parent directory */
    /* I can't understand Mark's code so I am adding a hack here to get
     * "zip -r foo ." to work. Allow the dubious "zip -r foo .." but
     * reject "zip -rm foo ..".
     */
    if (dispose && strcmp(p, "..") == 0)
       ziperr(ZE_PARMS, "cannot remove parent directory");
    q = (char *)wild_match_all;
  }
  else                                  /* no path or device */
  {
    q = p;
    p = strcpy(v, ".");
  }
  if (recurse && *q == '\0') {
    q = (char *)wild_match_all;
  }
  /* Search that level for matching names */
  if ((d = Opendir(p)) == NULL)
  {
    free((zvoid *)a);
    return ZE_MISS;
  }
  if ((r = strlen(p)) > 1 &&
      (strcmp(p + r - 2, ":.") == 0 || strcmp(p + r - 2, "/.") == 0))
    *(p + r - 1) = '\0';
  f = 0;
  while ((e = readd(d)) != NULL) {
    if (strcmp(e, ".") && strcmp(e, "..") && MATCH(q, e))
    {
      f = 1;
      if (strcmp(p, ".") == 0) {                /* path is . */
        r = procname(e);                        /* name is name */
        if (r) {
           f = 0;
           break;
        }
      } else
      {
        if ((n = malloc(strlen(p) + strlen(e) + 2)) == NULL)
        {
          free((zvoid *)a);
          Closedir(d);
          return ZE_MEM;
        }
        n = strcpy(n, p);
        if (n[r = strlen(n) - 1] != '/' && n[r] != ':')
          strcat(n, "/");
        r = procname(strcat(n, e));             /* name is path/name */
        free((zvoid *)n);
        if (r) {
          f = 0;
          break;
        }
      }
    }
  }
  Closedir(d);

  /* Done */
  free((zvoid *)a);
  return f ? ZE_OK : ZE_MISS;
}

int procname(n)
char *n;                /* name to process */
/* Process a name or sh expression to operate on (or exclude).  Return
   an error code in the ZE_ class. */
{
  char *a;              /* path and name for recursion */
  zDIR *d;              /* directory stream from opendir() */
  char *e;              /* pointer to name from readd() */
  int m;                /* matched flag */
  char *p;              /* path for recursion */
  struct stat s;        /* result of stat() */
  struct zlist far *z;  /* steps through zfiles list */

  if (strcmp(n, "-") == 0)   /* if compressing stdin */
    return newname(n, 0);
  else if (LSSTAT(n, &s)
#if defined(__TURBOC__) || defined(VMS) || defined(__WATCOMC__)
           /* For these 3 compilers, stat() succeeds on wild card names! */
           || isshexp(n)
#endif
          )
  {
    /* Not a file or directory--search for shell expression in zip file */
    p = ex2in(n, 0, (int *)NULL);       /* shouldn't affect matching chars */
    m = 1;
    for (z = zfiles; z != NULL; z = z->nxt) {
      if (MATCH(p, z->zname))
      {
        z->mark = pcount ? filter(z->zname) : 1;
        if (verbose)
            fprintf(mesg, "zip diagnostic: %scluding %s\n",
               z->mark ? "in" : "ex", z->name);
        m = 0;
      }
    }
    free((zvoid *)p);
    return m ? ZE_MISS : ZE_OK;
  }

  /* Live name--use if file, recurse if directory */
  for (p = n; *p; p++)          /* use / consistently */
    if (*p == '\\')
      *p = '/';
  if ((s.st_mode & S_IFDIR) == 0)
  {
    /* add or remove name of file */
    if ((m = newname(n, 0)) != ZE_OK)
      return m;
  } else {
    /* Add trailing / to the directory name */
    if ((p = malloc(strlen(n)+2)) == NULL)
      return ZE_MEM;
    if (strcmp(n, ".") == 0 || strcmp(n, "/.") == 0) {
      *p = '\0';  /* avoid "./" prefix and do not create zip entry */
    } else {
      strcpy(p, n);
      a = p + strlen(p);
      if (a[-1] != '/')
        strcpy(a, "/");
      if (dirnames && (m = newname(p, 1)) != ZE_OK) {
        free((zvoid *)p);
        return m;
      }
    }
    /* recurse into directory */
    if (recurse && (d = Opendir(n)) != NULL)
    {
      while ((e = readd(d)) != NULL) {
        if (strcmp(e, ".") && strcmp(e, ".."))
        {
          if ((a = malloc(strlen(p) + strlen(e) + 1)) == NULL)
          {
            Closedir(d);
            free((zvoid *)p);
            return ZE_MEM;
          }
          strcat(strcpy(a, p), e);
          if ((m = procname(a)) != ZE_OK)   /* recurse on name */
          {
            if (m == ZE_MISS)
              zipwarn("name not matched: ", a);
            else
              ziperr(m, a);
          }
          free((zvoid *)a);
        }
      }
      Closedir(d);
    }
    free((zvoid *)p);
  } /* (s.st_mode & S_IFDIR) == 0) */
  return ZE_OK;
}

char *ex2in(x, isdir, pdosflag)
char *x;                /* external file name */
int isdir;              /* input: x is a directory */
int *pdosflag;          /* output: force MSDOS file attributes? */
/* Convert the external file name to a zip file name, returning the malloc'ed
   string or NULL if not enough memory. */
{
  char *n;              /* internal file name (malloc'ed) */
  char *t;              /* shortened name */
  int dosflag;


  dosflag = dosify || IsFileSystemOldFAT(x);
  if (!dosify && use_longname_ea && (t = GetLongPathEA(x)) != NULL)
  {
    x = t;
    dosflag = 0;
  }

  /* Find starting point in name before doing malloc */
  t = *x && *(x + 1) == ':' ? x + 2 : x;
  while (*t == '/' || *t == '\\')
    t++;

  /* Make changes, if any, to the copied name (leave original intact) */
  for (n = t; *n; n++)
    if (*n == '\\')
      *n = '/';

  if (!pathput)
    t = last(t, PATH_END);

  /* Malloc space for internal name and copy it */
  if ((n = malloc(strlen(t) + 1)) == NULL)
    return NULL;
  strcpy(n, t);

  if (dosify)
    msname(n);

  /* Returned malloc'ed name */
  if (pdosflag)
    *pdosflag = dosflag;
  return n;
}


char *in2ex(n)
char *n;                /* internal file name */
/* Convert the zip file name to an external file name, returning the malloc'ed
   string or NULL if not enough memory. */
{
  char *x;              /* external file name */

  if ((x = malloc(strlen(n) + 1 + PAD)) == NULL)
    return NULL;
  strcpy(x, n);

  if ( !IsFileNameValid(x) )
    ChangeNameForFAT(x);
  return x;
}


void stamp(f, d)
char *f;                /* name of file to change */
ulg d;                  /* dos-style time to change it to */
/* Set last updated and accessed time of file f to the DOS time d. */
{
#if defined(__TURBOC__) && !defined(__BORLANDC__)
  int h;                /* file handle */

  if ((h = open(f, 0)) != -1)
  {
    setftime(h, (struct ftime *)&d);
    close(h);
  }
#else /* !__TURBOC__ */

  struct utimbuf u;     /* argument for utime() */

  /* Convert DOS time to time_t format in u.actime and u.modtime */
  u.actime = u.modtime = dos2unixtime(d);

  /* Set updated and accessed times of f */
  utime(f, &u);
#endif /* ?__TURBOC__ */
}


ulg filetime(f, a, n, t)
char *f;                /* name of file to get info on */
ulg *a;                 /* return value: file attributes */
long *n;                /* return value: file size */
ztimbuf *t;             /* return value: access and modification time */
/* If file *f does not exist, return 0.  Else, return the file's last
   modified date and time as an MSDOS date and time.  The date and
   time is returned in a long with the date most significant to allow
   unsigned integer comparison of absolute times.  Also, if a is not
   a NULL pointer, store the file attributes there, with the high two
   bytes being the Unix attributes, and the low byte being a mapping
   of that to DOS attributes.  If n is not NULL, store the file size
   there.  If t is not NULL, the file's access and modification time
   are stored there as UNIX time_t values.
   If f is "-", use standard input as the file. If f is a device, return
   a file size of -1 */
{
  struct stat s;        /* results of stat() */
  char name[FNMAX];
  int len = strlen(f), isstdin = !strcmp(f, "-");

  if (f == label) {
    if (a != NULL)
      *a = label_mode;
    if (n != NULL)
      *n = -2L; /* convention for a label name */
    if (t != NULL)
      t->actime = t->modtime = label_utim;
    return label_time;
  }
  strcpy(name, f);
  if (name[len - 1] == '/')
    name[len - 1] = '\0';
  /* not all systems allow stat'ing a file with / appended */

  if (isstdin) {
    if (fstat(fileno(stdin), &s) != 0)
      error("fstat(stdin)");
    time((time_t *)&s.st_mtime);       /* some fstat()s return time zero */
  } else if (LSSTAT(name, &s) != 0)
             /* Accept about any file kind including directories
              * (stored with trailing / with -r option)
              */
    return 0;

  if (a != NULL) {
    *a = ((ulg)s.st_mode << 16) | (isstdin ? 0L : (ulg)GetFileMode(name));
  }
  if (n != NULL)
    *n = (s.st_mode & S_IFMT) == S_IFREG ? s.st_size : -1L;
  if (t != NULL) {
    t->actime = s.st_atime;
    t->modtime = s.st_mtime;
  }

  return unix2dostime((time_t *)&s.st_mtime);
}

int set_extra_field(z, z_utim)
  struct zlist far *z;
  ztimbuf *z_utim;
  /* create extra field and change z->att if desired */
{
#ifdef USE_EF_UX_TIME
  if ((z->extra = (char *)malloc(EB_HEADSIZE+EB_UX_MINLEN)) == NULL)
    return ZE_MEM;

  z->extra[0]  = 'U';
  z->extra[1]  = 'X';
  z->extra[2]  = EB_UX_MINLEN;          /* length of data part of e.f. */
  z->extra[3]  = 0;
  z->extra[4]  = (char)(z_utim->actime);
  z->extra[5]  = (char)(z_utim->actime >> 8);
  z->extra[6]  = (char)(z_utim->actime >> 16);
  z->extra[7]  = (char)(z_utim->actime >> 24);
  z->extra[8]  = (char)(z_utim->modtime);
  z->extra[9]  = (char)(z_utim->modtime >> 8);
  z->extra[10] = (char)(z_utim->modtime >> 16);
  z->extra[11] = (char)(z_utim->modtime >> 24);

  z->cext = z->ext = (EB_HEADSIZE+EB_UX_MINLEN);
  z->cextra = z->extra;

  return ZE_OK;
#else /* !USE_EF_UX_TIME */
  return (int)(z-z);
#endif /* ?USE_EF_UX_TIME */
}

int deletedir(d)
char *d;                /* directory to delete */
/* Delete the directory *d if it is empty, do nothing otherwise.
   Return the result of rmdir(), delete(), or system().
   For VMS, d must be in format [x.y]z.dir;1  (not [x.y.z]).
 */
{
    return rmdir(d);
}

/******************************/
/*  Function version_local()  */
/******************************/

void version_local()
{
    static const char CompiledWith[] = "Compiled with %s%s for %s%s%s%s.\n\n";
#if (defined(_MSC_VER) || defined(__WATCOMC__))
    char buf[80];
#endif

    printf(CompiledWith,

#ifdef _MSC_VER  /* MSC == MSVC++, including the SDK compiler */
      (sprintf(buf, "Microsoft C %d.%02d ", _MSC_VER/100, _MSC_VER%100), buf),
#  if (_MSC_VER == 800)
        "(Visual C++ v1.1)",
#  elif (_MSC_VER == 850)
        "(Windows NT v3.5 SDK)",
#  elif (_MSC_VER == 900)
        "(Visual C++ v2.0/v2.1)",
#  elif (_MSC_VER == 1000)
        "(Visual C++ v4.0)",
#  elif (_MSC_VER == 1010)
        "(Visual C++ v4.1)",
#  elif (_MSC_VER > 800)
        "(Visual C++)",
#  else
        "(bad version)",
#  endif
#endif /* _MSC_VER */

#ifdef __WATCOMC__
#  if (__WATCOMC__ % 10 > 0)
/* We do this silly test because __WATCOMC__ gives two digits for the  */
/* minor version, but Watcom packaging prefers to show only one digit. */
        (sprintf(buf, "Watcom C/C++ %d.%02d", __WATCOMC__ / 100,
                 __WATCOMC__ % 100), buf), "",
#  else
      (sprintf(buf, "Watcom C/C++ %d.%d", __WATCOMC__ / 100,
               (__WATCOMC__ % 100) / 10), buf), "",
#  endif /* __WATCOMC__ % 10 > 0 */
#endif /* __WATCOMC__ */

#ifdef __TURBOC__
#  ifdef __BORLANDC__
     "Borland C++",
#    if (__BORLANDC__ == 0x0452)   /* __BCPLUSPLUS__ = 0x0320 */
        " 4.0 or 4.02",
#    elif (__BORLANDC__ == 0x0460)   /* __BCPLUSPLUS__ = 0x0340 */
        " 4.5",
#    elif (__BORLANDC__ == 0x0500)   /* __TURBOC__ = 0x0500 */
        " 5.0",
#    else
        " later than 5.0",
#    endif
#  else /* !__BORLANDC__ */
     "Turbo C",
#    if (__TURBOC__ >= 0x0400)     /* Kevin:  3.0 -> 0x0401 */
        "++ 3.0 or later",
#    elif (__TURBOC__ == 0x0295)     /* [661] vfy'd by Kevin */
        "++ 1.0",
#    endif
#  endif /* __BORLANDC__ */
#endif /* __TURBOC__ */

#if !defined(__TURBOC__) && !defined(__WATCOMC__) && !defined(_MSC_VER)
      "unknown compiler (SDK?)", "",
#endif

      "\n\tWindows 95 / Windows NT", " (32-bit)",

#ifdef __DATE__
      " on ", __DATE__
#else
      "", ""
#endif
    );

    return;

} /* end function version_local() */

#endif /* !UTIL */
