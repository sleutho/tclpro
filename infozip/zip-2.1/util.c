/*

 Copyright (C) 1990-1996 Mark Adler, Richard B. Wales, Jean-loup Gailly,
 Kai Uwe Rommel, Onno van der Linden and Igor Mandrichenko.
 Permission is granted to any individual or institution to use, copy, or
 redistribute this software so long as all of the original files are included,
 that it is not sold for profit, and that this copyright notice is retained.

*/

/*
 *  util.c by Mark Adler.
 */

#include "zip.h"
#include <ctype.h>

#ifdef MSDOS16
#  include <dos.h>
#endif

uch upper[256], lower[256];
/* Country-dependent case map table */


#ifndef UTIL /* UTIL picks out namecmp code (all utils) */

/* Local functions */
local int recmatch OF((uch *, uch *));
local int count_args OF((char *s));

#ifdef MSDOS16
  local unsigned ident OF((unsigned chr));
#endif

#ifdef NO_MKTIME
#include "mktime.c"
#endif

char *isshexp(p)
char *p;                /* candidate sh expression */
/* If p is a sh expression, a pointer to the first special character is
   returned.  Otherwise, NULL is returned. */
{
  for (; *p; p++)
    if (*p == '\\' && *(p+1))
      p++;
#ifdef VMS
    else if (*p == '%' || *p == '*')
#else /* !VMS */
    else if (*p == '?' || *p == '*' || *p == '[')
#endif /* ?VMS */
      return p;
  return NULL;
}


local int recmatch(p, s)
uch *p;       /* sh pattern to match */
uch *s;       /* string to match it to */
/* Recursively compare the sh pattern p with the string s and return 1 if
   they match, and 0 or 2 if they don't or if there is a syntax error in the
   pattern.  This routine recurses on itself no deeper than the number of
   characters in the pattern. */
{
  unsigned int c;       /* pattern char or start of range in [-] loop */

  /* Get first character, the pattern for new recmatch calls follows */
  c = *p++;

  /* If that was the end of the pattern, match if string empty too */
  if (c == 0)
    return *s == 0;

  /* '?' (or '%') matches any character (but not an empty string) */
#ifdef VMS
  if (c == '%')
#else /* !VMS */
  if (c == '?')
#endif /* ?VMS */
    return *s ? recmatch(p, s + 1) : 0;

  /* '*' matches any number of characters, including zero */
#ifdef AMIGA
  if (c == '#' && *p == '?')            /* "#?" is Amiga-ese for "*" */
    c = '*', p++;
#endif /* AMIGA */
  if (c == '*')
  {
    if (*p == 0)
      return 1;
    for (; *s; s++)
      if ((c = recmatch(p, s)) != 0)
        return (int)c;
    return 2;           /* 2 means give up--shmatch will return false */
  }

#ifndef VMS             /* No bracket matching in VMS */
  /* Parse and process the list of characters and ranges in brackets */
  if (c == '[')
  {
    int e;              /* flag true if next char to be taken literally */
    uch *q;   /* pointer to end of [-] group */
    int r;              /* flag true to match anything but the range */

    if (*s == 0)                        /* need a character to match */
      return 0;
    p += (r = (*p == '!' || *p == '^')); /* see if reverse */
    for (q = p, e = 0; *q; q++)         /* find closing bracket */
      if (e)
        e = 0;
      else
        if (*q == '\\')
          e = 1;
        else if (*q == ']')
          break;
    if (*q != ']')                      /* nothing matches if bad syntax */
      return 0;
    for (c = 0, e = *p == '-'; p < q; p++)      /* go through the list */
    {
      if (e == 0 && *p == '\\')         /* set escape flag if \ */
        e = 1;
      else if (e == 0 && *p == '-')     /* set start of range if - */
        c = *(p-1);
      else
      {
        uch cc = case_map(*s);
        if (*(p+1) != '-')
          for (c = c ? c : *p; c <= *p; c++)    /* compare range */
            if (case_map(c) == cc)
              return r ? 0 : recmatch(q + 1, s + 1);
        c = e = 0;                      /* clear range, escape flags */
      }
    }
    return r ? recmatch(q + 1, s + 1) : 0;      /* bracket match failed */
  }
#endif /* !VMS */

  /* If escape ('\'), just compare next character */
  if (c == '\\')
    if ((c = *p++) == 0)                /* if \ at end, then syntax error */
      return 0;

  /* Just a character--compare it */
  return case_map(c) == case_map(*s) ? recmatch(p, ++s) : 0;
}


int shmatch(p, s)
char *p;                /* sh pattern to match */
char *s;                /* string to match it to */
/* Compare the sh pattern p with the string s and return true if they match,
   false if they don't or if there is a syntax error in the pattern. */
{
  return recmatch((uch *) p, (uch *) s) == 1;
}


#ifdef DOS

int dosmatch(p, s)
char *p;                /* dos pattern to match */
char *s;                /* string to match it to */
/* Break the pattern and string into name and extension parts and match
   each separately using shmatch(). */
{
  char *p1, *p2;        /* pattern sections */
  char *s1, *s2;        /* string sections */
  int plen = strlen(p); /* length of pattern */
  int r;                /* result */

  if ((p1 = malloc(plen + 1)) == NULL ||
      (s1 = malloc(strlen(s) + 1)) == NULL)
  {
    if (p1 != NULL)
      free((zvoid *)p1);
    return 0;
  }
  strcpy(p1, p);
  strcpy(s1, s);
  if ((p2 = strrchr(p1, '.')) != NULL)
    *p2++ = '\0';
  else if (plen && p1[plen - 1] == '*')
    p2 = "*";
  else
    p2 = "";
  if ((s2 = strrchr(s1, '.')) != NULL)
    *s2++ = '\0';
  else
    s2 = "";
  r = shmatch(p2, s2) && shmatch(p1, s1);
  free((zvoid *)p1);
  free((zvoid *)s1);
  return r;
}
#endif /* DOS */

zvoid far **search(b, a, n, cmp)
zvoid *b;               /* pointer to value to search for */
zvoid far **a;          /* table of pointers to values, sorted */
extent n;               /* number of pointers in a[] */
int (*cmp) OF((const zvoid *, const zvoid far *)); /* comparison function */

/* Search for b in the pointer list a[0..n-1] using the compare function
   cmp(b, c) where c is an element of a[i] and cmp() returns negative if
   *b < *c, zero if *b == *c, or positive if *b > *c.  If *b is found,
   search returns a pointer to the entry in a[], else search() returns
   NULL.  The nature and size of *b and *c (they can be different) are
   left up to the cmp() function.  A binary search is used, and it is
   assumed that the list is sorted in ascending order. */
{
  zvoid far **i;        /* pointer to midpoint of current range */
  zvoid far **l;        /* pointer to lower end of current range */
  int r;                /* result of (*cmp)() call */
  zvoid far **u;        /* pointer to upper end of current range */

  l = (zvoid far **)a;  u = l + (n-1);
  while (u >= l) {
    i = l + ((unsigned)(u - l) >> 1);
    if ((r = (*cmp)(b, (char *)*(struct zlist **)i)) < 0)
      u = i - 1;
    else if (r > 0)
      l = i + 1;
    else
      return (zvoid far **)i;
  }
  return NULL;          /* If b were in list, it would belong at l */
}

#endif /* !UTIL */

#ifdef MSDOS16

local unsigned ident(unsigned chr)
{
   return chr; /* in al */
}

void init_upper()
{
  static struct country {
    uch ignore[18];
    int (far *casemap)(int);
    uch filler[16];
  } country_info;

  struct country far *info = &country_info;
  union REGS regs;
  struct SREGS sregs;
  int c;

  regs.x.ax = 0x3800; /* get country info */
  regs.x.dx = FP_OFF(info);
  sregs.ds  = FP_SEG(info);
  intdosx(&regs, &regs, &sregs);
  for (c = 0; c < 128; c++) {
    upper[c] = (uch) toupper(c);
    lower[c] = (uch) c;
  }
  for (; c < sizeof(upper); c++) {
    upper[c] = (uch) (*country_info.casemap)(ident(c));
    /* ident() required because casemap takes its parameter in al */
    lower[c] = (uch) c;
  }
  for (c = 0; c < sizeof(upper); c++ ) {
    int u = upper[c];
    if (u != c && lower[u] == (uch) u) {
      lower[u] = (uch)c;
    }
  }
  for (c = 'A'; c <= 'Z'; c++) {
    lower[c] = (uch) (c - 'A' + 'a');
  }
}
#else /* !MSDOS16 */
#  ifndef OS2

void init_upper()
{
  int c;
#if defined(ATARI) || defined(CMS_MVS)
#include <ctype.h>
/* this should be valid for all other platforms too.   (HD 11/11/95) */
  for (c = 0; c< sizeof(upper); c++) {
    upper[c] = islower(c) ? toupper(c) : c;
    lower[c] = isupper(c) ? tolower(c) : c;
  }
#else
  for (c = 0; c < sizeof(upper); c++) upper[c] = lower[c] = c;
  for (c = 'a'; c <= 'z';        c++) upper[c] = c - 'a' + 'A';
  for (c = 'A'; c <= 'Z';        c++) lower[c] = c - 'A' + 'a';
#endif
}
#  endif /* !OS2 */

#endif /* ?MSDOS16 */

int namecmp(string1, string2)
  char *string1, *string2;
/* Compare the two strings ignoring case, and correctly taking into
 * account national language characters. For operating systems with
 * case sensitive file names, this function is equivalent to strcmp.
 */
{
  int d;

  for (;;)
  {
    d = (int) (uch) case_map(*string1)
      - (int) (uch) case_map(*string2);

    if (d || *string1 == 0 || *string2 == 0)
      return d;

    string1++;
    string2++;
  }
}

#ifdef EBCDIC

#include "ebcdic.h"

char *strtoasc(char *str1, char *str2)
{
  char *old;
  old = str1;
  while (*str1++ = (char)ascii[(uch)(*str2++)]);
  return old;
}

char *strtoebc(char *str1, char *str2)
{
  char *old;
  old = str1;
  while (*str1++ = (char)ebcdic[(uch)(*str2++)]);
  return old;
}

#endif /* EBCDIC */

#ifndef UTIL

extern char *getenv OF((const char *));

/*****************************************************************
 | envargs - add default options from environment to command line
 |----------------------------------------------------------------
 | Author: Bill Davidsen, original 10/13/91, revised 23 Oct 1991.
 | This program is in the public domain.
 |----------------------------------------------------------------
 | Minor program notes:
 |  1. Yes, the indirection is a tad complex
 |  2. Parenthesis were added where not needed in some cases
 |     to make the action of the code less obscure.
 ****************************************************************/

void envargs(Pargc, Pargv, envstr, envstr2)
    int *Pargc;
    char ***Pargv;
    char *envstr;
    char *envstr2;
{
    char *envptr;                               /* value returned by getenv */
    char *bufptr;                               /* copy of env info */
    int argc = 0;                               /* internal arg count */
    int ch;                                             /* spare temp value */
    char **argv;                                /* internal arg vector */
    char **argvect;                             /* copy of vector address */

    /* see if anything in the environment */
    if ((envptr = getenv(envstr)) == NULL || *envptr == 0)      /* usual var */
        if ((envptr = getenv(envstr2)) == NULL || *envptr == 0) /* alternate */
            return;

    /* count the args so we can allocate room for them */
    argc = count_args(envptr);
    bufptr = malloc(1+strlen(envptr));
    if (bufptr == NULL)
        ziperr(ZE_MEM, "Can't get memory for arguments");

    strcpy(bufptr, envptr);

    /* allocate a vector large enough for all args */
    argv = (char **)malloc((argc+*Pargc+1)*sizeof(char *));
    if (argv == NULL)
        ziperr(ZE_MEM, "Can't get memory for arguments");
    argvect = argv;

    /* copy the program name first, that's always true */
    *(argv++) = *((*Pargv)++);

    /* copy the environment args first, may be changed */
    do {
        *(argv++) = bufptr;
        /* skip the arg and any trailing blanks */
        while ((ch = *bufptr) != '\0' && ch != ' ') ++bufptr;
        if (ch == ' ') *(bufptr++) = '\0';
        while ((ch = *bufptr) != '\0' && ch == ' ') ++bufptr;
    } while (ch);

    /* now save old argc and copy in the old args */
    argc += *Pargc;
    while (--(*Pargc)) *(argv++) = *((*Pargv)++);

    /* finally, add a NULL after the last arg, like UNIX */
    *argv = NULL;

    /* save the values and return */
    *Pargv = argvect;
    *Pargc = argc;
}

local int count_args(s)
    char *s;
{
    int count = 0;
    int ch;

    do {
        /* count and skip args */
        ++count;
        while ((ch = *s) != '\0' && ch != ' ') ++s;
        while ((ch = *s) != '\0' && ch == ' ') ++s;
    } while (ch);

    return count;
}


/* Extended argument processing -- by Rich Wales
 * This function currently deals only with the MKS shell, but could be
 * extended later to understand other conventions.
 *
 * void expand_args(int *argcp, char ***argvp)
 *
 *    Substitutes the extended command line argument list produced by
 *    the MKS Korn Shell in place of the command line info from DOS.
 *
 *    The MKS shell gets around DOS's 128-byte limit on the length of
 *    a command line by passing the "real" command line in the envi-
 *    ronment.  The "real" arguments are flagged by prepending a tilde
 *    (~) to each one.
 *
 *    This "expand_args" routine creates a new argument list by scanning
 *    the environment from the beginning, looking for strings begin-
 *    ning with a tilde character.  The new list replaces the original
 *    "argv" (pointed to by "argvp"), and the number of arguments
 *    in the new list replaces the original "argc" (pointed to by
 *    "argcp").
 */
void expand_args(argcp, argvp)
      int *argcp;
      char ***argvp;
{
#ifdef DOS

/* Do NEVER include (re)definiton of `environ' variable with any version
   of MSC or BORLAND/Turbo C. These compilers supply an incompatible
   definition in <stdlib.h>.  */
#if defined(__GO32__) || defined(__EMX__)
      extern char **environ;          /* environment */
#endif /* __GO32__ || __EMX__ */
      char        **envp;             /* pointer into environment */
      char        **newargv;          /* new argument list */
      char        **argp;             /* pointer into new arg list */
      int           newargc;          /* new argument count */

      /* sanity check */
      if (environ == NULL
          || argcp == NULL
          || argvp == NULL || *argvp == NULL)
              return;
      /* find out how many environment arguments there are */
      for (envp = environ, newargc = 0;
           *envp != NULL && (*envp)[0] == '~';
           envp++, newargc++) ;
      if (newargc == 0)
              return;                 /* no environment arguments */
      /* set up new argument list */
      newargv = (char **) malloc(sizeof(char **) * (newargc+1));
      if (newargv == NULL)
              return;                 /* malloc failed */
      for (argp = newargv, envp = environ;
           *envp != NULL && (*envp)[0] == '~';
           *argp++ = &(*envp++)[1]) ;
      *argp = NULL;                   /* null-terminate the list */
      /* substitute new argument list in place of old one */
      *argcp = newargc;
      *argvp = newargv;
#else /* ?DOS */
      if (argcp || argvp) return;
#endif /* ?DOS */
}

#endif /* UTIL */
