/* 
 * sampleinit.c --
 *
 *  Main program and Tcl_AppInit for the wrapper sample shell.
 *
 * Copyright (c) 1998 by Scriptics Corporation.
 * All rights reserved.
 *
 * RCS: @(#) $Id: sampleinit.c,v 1.3 2000/03/15 00:15:33 berry Exp $
 */

#include "tcl.h"
#include "proWrap.h"

#define RCFILE "~/.tclshrc"

/*
 * The following variable is a special hack that is needed in order for
 * Sun shared libraries to be used for Tcl.
 */

extern int matherr();
int *tclDummyMathPtr = (int *) matherr;

static int		ProTclAppInit _ANSI_ARGS_((Tcl_Interp *interp));

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
    Pro_WrapTclMain(argc, argv, ProTclAppInit);
    return 0;			/* Needed only to prevent compiler warning. */
}

/*
 *----------------------------------------------------------------------
 *
 * ProTclAppInit --
 *
 *	This procedure performs application-specific initialization.
 *	Most applications, especially those that incorporate additional
 *	packages, will have their own version of this procedure.
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
ProTclAppInit(interp)
    Tcl_Interp *interp;		/* Interpreter for application. */
{
    if (Tcl_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }

    Tcl_SetVar(interp, "tcl_rcFileName", RCFILE, TCL_GLOBAL_ONLY);

    return TCL_OK;
}

