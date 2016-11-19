/* 
 * proMainTcl.c --
 *
 *	This file contains the generic initialization code used by all
 *	TclPro executables.
 *
 * Copyright (c) 1998 by Scriptics Corporation.
 * All rights reserved.
 *
 * RCS: @(#) $Id: proTclMain.c,v 1.3 2000/03/15 00:15:33 berry Exp $
 */

#include <tcl.h>

#ifdef WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#undef WIN32_LEAN_AND_MEAN
#include <locale.h>
#endif /* WIN32 */

#include <proTbcLoad.h>
#include <proWrap.h>

#ifndef WIN32
static int TclPro_AppInit _ANSI_ARGS_((Tcl_Interp *interp));
#else /* WIN32 */
/*
 * External pacakge init routines.
 */

EXTERN int	Registry_Init _ANSI_ARGS_((Tcl_Interp *interp));

/*
 * The following declaration refers to the internal Tcl initialization
 * routine.
 */

EXTERN void		TclWinInit(HINSTANCE hInstance);

/*
 * Forward declarations for procedures defined later in this file:
 */

static int TclPro_AppInit _ANSI_ARGS_((Tcl_Interp *interp));

/*
 * Include a block of code that is shared between this file and mainTk.c.
 */

#include "setargv.c"
#endif /* WIN32 */


/*
 *----------------------------------------------------------------------
 *
 * main --
 *
 *	This is the main program for the application.
 *
 * Results:
 *	None: Tcl_Main never returns here, so this procedure never
 *	returns either.
 *
 * Side effects:
 *	Whatever the application does.
 *
 *----------------------------------------------------------------------
 */

int
main(argc, argv)
    int argc;			/* Number of command-line arguments. */
    char **argv;		/* Values of command-line arguments. */
{
#ifndef WIN32
    Pro_WrapTclMain(argc, argv, TclPro_AppInit);
#else /* WIN32 */
    char *p;
    char buffer[MAX_PATH];

#ifndef BUILD_SHARED
    TclWinInit(GetModuleHandle(NULL));
#endif

    /*
     * Set up the default locale to be standard "C" locale so parsing
     * is performed correctly.
     */

    setlocale(LC_ALL, "C");

    setargv(&argc, &argv);

    /*
     * Replace argv[0] with full pathname of executable, and forward
     * slashes substituted for backslproMainTcl.$(OBJEXT)ashes.
     */

    GetModuleFileName(NULL, buffer, sizeof(buffer));
    argv[0] = buffer;
    for (p = buffer; *p != '\0'; p++) {
	if (*p == '\\') {
	    *p = '/';
	}
    }

    Pro_WrapTclMain(argc, argv, TclPro_AppInit);
#endif /* WIN32 */
    return 0;			/* Needed only to prevent compiler warning. */
}

/*
 *----------------------------------------------------------------------
 *
 * TclPro_AppInit --
 *
 *	Initialize the loader as a static Tcl package, then call the
 *	application specific init routine.
 *
 * Results:
 *	Returns a standard Tcl completion code, and leaves an error
 *	message in interp->result if an error occurs.
 *
 * Side effects:
 *	Depends on the startup script.
 *
 *----------------------------------------------------------------------
 */

static int
TclPro_AppInit(interp)
    Tcl_Interp *interp;		/* Interpreter for application. */
{
    if (Tcl_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
#ifdef WIN32

    if (Registry_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "registry", Registry_Init, NULL);

#endif /* WIN32 */
    if (Tbcload_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, (char *) TbcloadGetPackageName(),
            Tbcload_Init, Tbcload_SafeInit);
#ifdef WIN32

#endif /* WIN32 */
    return Tcl_AppInit(interp);
}

