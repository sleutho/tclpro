/* 
 * proWrapTkMain.c --
 *
 *	Replacement for Tk_Main for applications that use TclPro Wrapper.
 *	This API now exists for backwards compatibility.  Through some
 *	nice code cleanup you can see that it boils down to a hook
 *	call to initialize the wrapper and then it just uses the
 #	regular Tk_Main.
 *
 * Copyright (c) 1998-2000 Ajuba Solutions
 * All rights reserved.
 *
 * RCS: @(#) $Id: proWrapTkMain.c,v 1.4 2000/08/04 08:09:18 welch Exp $
 */

#include "tk.h"

#include <proWrap.h>


/*
 *----------------------------------------------------------------------
 *
 * Pro_WrapTkMain --
 *
 *	Main program for wish and most other Tcl/Tk-based applications
 *	that may or may not be wrapped.
 *
 * Results:
 *	None. This procedure never returns (it exits the process when
 *	it's done.
 *
 * Side effects:
 *	This procedure initializes the Tk world and then starts
 *	interpreting commands;  almost anything could happen, depending
 *	on the script being interpreted.
 *
 *----------------------------------------------------------------------
 */

void
Pro_WrapTkMain(argc, argv, appInitProc)
    int argc;				/* Number of arguments. */
    char **argv;			/* Array of argument strings. */
    Tcl_AppInitProc *appInitProc;	/* Application-specific initialization
					 * procedure to call after most
				 	 * initialization but before starting
					 * to execute commands. */
{
    /*
     * This hook auto-detects a wrapped application and modifies
     * the argv array to contain arguements specified during
     * the wrapping process.
     */

    TclPro_Init(&argc, &argv);
    Tk_Main(argc, argv, appInitProc);
}
