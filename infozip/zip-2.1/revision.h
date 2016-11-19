/*

 Copyright (C) 1990-1996 Mark Adler, Richard B. Wales, Jean-loup Gailly,
 Kai Uwe Rommel, Onno van der Linden and Igor Mandrichenko.
 Permission is granted to any individual or institution to use, copy, or
 redistribute this software so long as all of the original files are included,
 that it is not sold for profit, and that this copyright notice is retained.

*/

/*
 *  revision.h by Mark Adler.
 */

#ifndef __revision_h
#define __revision_h 1

#define REVISION 21
#define PATCHLEVEL 0
#define VERSION "2.1"
#define REVDATE "April 27th 1996"

/* Copyright notice for binary executables--this notice only applies to
 * those (zip, zipcloak, zipsplit, and zipnote), not to this file
 * (revision.h).
 */

#ifdef NOCPYRT                       /* copyright[] gets defined only once ! */
extern const char *copyright[2];     /* keep array sizes in sync with number */
extern const char *disclaimer[9];    /*  of text line in definition below !! */
extern const char *versinfolines[4];

#else /* !NOCPYRT */

const char *copyright[] = {

#ifdef VMS
"Copyright (C) 1990-1996 Mark Adler, Richard B. Wales, Jean-loup Gailly",
"Onno van der Linden, Christian Spieler and Igor Mandrichenko.",
"Type '%s \"-L\"' for software license."
#endif

#ifdef AMIGA
"Copyright (C) 1990-1996 Mark Adler, Richard B. Wales, Jean-loup Gailly,",
"Onno van der Linden, John Bush and Paul Kienitz.",
"Type '%s -L' for the software License."
#endif

#if defined(__arm) || defined(RISCOS)
"Copyright (C) 1990-1996 Mark Adler, Richard B. Wales, Jean-loup Gailly,",
"Onno van der Linden, Karl Davis and Sergio Monesi.",
"Type '%s \"-L\"' for software Licence."
#endif

#ifdef DOS
"Copyright (C) 1990-1996 Mark Adler, Richard B. Wales, Jean-loup Gailly",
"Onno van der Linden, Christian Spieler and Kai Uwe Rommel."
#endif

#ifdef CMS_MVS
"Copyright (C) 1990-1996 Mark Adler, Richard B. Wales, Jean-loup Gailly",
"Onno van der Linden, George Petrov and Kai Uwe Rommel."
#endif

#if defined(OS2) || defined(WIN32) || defined(UNIX)
"Copyright (C) 1990-1996 Mark Adler, Richard B. Wales, Jean-loup Gailly",
"Onno van der Linden and Kai Uwe Rommel. Type '%s -L' for the software License."
#endif
};

const char *versinfolines[] = {
"This is %s %s (%s), by Info-ZIP.",
"Currently maintained by Onno van der Linden. Please send bug reports to",
"the authors at Zip-Bugs@wkuvx1.wku.edu; see README for details.",
"",
"Latest sources and executables are always in ftp.uu.net:/pub/archiving/zip, at",
"least as of date of this release; See \"Where\" for other ftp and non-ftp sites.",
""
};

const char *disclaimer[] = {
"",
"Permission is granted to any individual or institution to use, copy, or",
"redistribute this executable so long as it is not modified and that it is",
"not sold for profit.",
"",
"LIKE ANYTHING ELSE THAT'S FREE, ZIP AND ITS ASSOCIATED UTILITIES ARE",
"PROVIDED AS IS AND COME WITH NO WARRANTY OF ANY KIND, EITHER EXPRESSED OR",
"IMPLIED. IN NO EVENT WILL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY DAMAGES",
"RESULTING FROM THE USE OF THIS SOFTWARE."
};
#endif /* !NOCPYRT */
#endif /* !__revision_h */
