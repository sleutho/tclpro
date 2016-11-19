/* 
 * proInit.c --
 *
 *	This contains the hook that initializes a wrapped application.
 *
 * Copyright (c) 1998-2000 Ajuba Solutions
 * All rights reserved.
 *
 * RCS: @(#) $Id: proInit.c,v 1.1 2000/08/04 08:09:17 welch Exp $
 */

#include "tclInt.h"

#include <proWrap.h>


/*
 *----------------------------------------------------------------------
 *
 * TclPro_Init --
 *
 *	This procedure initializes a wrapped application.
 *
 *	This hook is called most typically by being configured as
 *	the TCL_LOCAL_MAIN_HOOK (for Tcl-based shells) or the
 *	TK_LOCAL_MAIN_HOOK (for Tcl/Tk based shells).  This hook point
 *	is supported by the main() programs defined by these standard
 *	Tcl and Tk source files:
 *	tcl/unix/tclAppInit.c
 *	tcl/win/tclAppInit.c
 *	tk/unix/tkAppInit.c
 *	tk/win/winMain.c
 *
 *	If you have a custom main program, simply call this hook
 *	before you call Tcl_Main or Tk_Main, and then your shell
 *	can be used as the -executable with TclPro wrapper.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	This will modify argc, argv to contain arguments specified
 *	when the application was wrapped.  It will also set the
 *	startup script for the application to be the one specified
 *	when the application was wrapped.  If the applicationw as
 *	not wrapped, then this procedure does nothing and the
 *	shell behave normally.
 *
 *----------------------------------------------------------------------
 */

int
TclPro_Init(argcPtr, argvPtr)
    int *argcPtr;
    char ***argvPtr;
{
    char *wrappedStartupFileName = NULL; /* Name of the startup script file
					  * that exists in the package. */
    char *wrappedArgs = NULL;		 /* The sequence of arguments that were
					  * specified when the application was
					  * wrapped. */
    char *executableName;

    char ** saveArgv = *argvPtr;
    int saveArgc = *argcPtr;
    
   /*
    * TclpFindExecutable has the important side effect of setting
    * up the encoding subsystem.  It needs to be called at the beginning
    * of time (it's ok to call it multiple times.)
    */

    TclInitSubsystems((*argvPtr)[0]);
    executableName = TclpFindExecutable((*argvPtr)[0]);

    /*
     * Determine if the currently running application is wrapped or not.
     *
     * If the application is wrapped, the wrapped startup script file
     * (if any) is sourced after all other initialization; if additional
     * arguments were supplied during the wrapping process they are
     * inserted between argv[0] and argv[1].
     *
     * A wrapped application that does not specify a startup script file
     * will create an interactive shell.  However, if the first argument
     * (e.g. argv[1]) is a file name (e.g. a string that does not partially
     * match "-file"), that file is used as the startup script file for the
     * interpreter.
     *
     * If the application is not wrapped, the code below behaves exactly
     * like Tcl_Main and Tk_Main.
     */

    if (Pro_WrapIsWrapped(executableName,
    	    &wrappedStartupFileName,
	    &wrappedArgs)) {
	if (wrappedStartupFileName != NULL) {
	    TclSetStartupScriptFileName(wrappedStartupFileName);
	}
        if (wrappedArgs != NULL) {

	    Pro_WrapPrependArgs(wrappedArgs, saveArgc, saveArgv, argcPtr, argvPtr);

	}
    }
    return 0;
}
