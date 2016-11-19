/* 
 * wrapper.c --
 *
 *	This file contains the wrapper specific initialization routine.
 *
 * Copyright (c) 1998 by Scriptics Corporation.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: wrapper.c,v 1.3 2000/03/15 00:15:33 berry Exp $
 */

#include <tcl.h>


/*
 *----------------------------------------------------------------------
 *
 * Tcl_AppInit --
 *
 *	There is nothing needed for TclPro Wrapper.
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

int
Tcl_AppInit(interp)
    Tcl_Interp *interp;		/* Interpreter for application. */
{
    return TCL_OK;
}

