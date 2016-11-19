/* 
 * cmpWPkg.c --
 *
 *	This file contains the C interfaces to the Tcl load command for the
 *  Compiler package: the Tclcompiler_Init function.
 *
 * Copyright (c) 1998-2000 by Ajuba Solutions.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: cmpWPkg.c,v 1.6 2005/03/18 23:42:12 hobbs Exp $
 */

#include "cmpInt.h"
#include "cmpWrite.h"

/*
 * name and version of this package
 */

static char packageName[] = CMP_WRITER_PACKAGE;
static char packageVersion[] = CMP_VERSION;

/*
 * Default error message for the missing bytecode loader: variable name and
 * variable value.
 */

static char errorVariable[] = LOADER_ERROR_VARIABLE;
static char errorMessage[] = LOADER_ERROR_MESSAGE;

/*
 * List of variables to create when the package is loaded
 */

typedef struct VarTable
{
    char *varName;
    char *varValue;
} VarTable;

static CONST VarTable variables[] =
{
    { errorVariable,		errorMessage },

    { 0, 0 }
};

/*
 * List of commands to create when the package is loaded
 */

typedef struct CmdTable
{
    char *cmdName;		/* command name */
    Tcl_ObjCmdProc *proc;	/* command proc */
    int exportIt;		/* if 1, export the command */
} CmdTable;

static CONST CmdTable commands[] =
{
    { "compile",		Compiler_CompileObjCmd,			1 },
    { "getBytecodeExtension",	Compiler_GetBytecodeExtensionObjCmd,	1 },

    { 0, 0, 0 }
};

/*
 * Declarations for functions defined in this file.
 */

static int RegisterCommand _ANSI_ARGS_((Tcl_Interp* interp,
		char *namespace, CONST CmdTable *cmdTablePtr));
static int RegisterVariable _ANSI_ARGS_((Tcl_Interp* interp,
		char *namespace, CONST VarTable *varTablePtr));

/*
 *----------------------------------------------------------------------
 *
 * Tclcompiler_Init --
 *
 *	This procedure initializes the Compiler package.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
Tclcompiler_Init(interp)
    Tcl_Interp *interp;		/* the Tcl interpreter for which the package
                                 * is initialized */
{
    CONST CmdTable *cmdTablePtr;
    CONST VarTable *varTablePtr;

    /*
     * You cannot use an 8.3 compiled compiler with 8.4 and vice versa.
     */
    if (Tcl_InitStubs(interp, TCL_VERSION, 1) == NULL) {
	return TCL_ERROR;
    }

    CompilerInit(interp);

    for (cmdTablePtr=&commands[0] ; cmdTablePtr->cmdName ; cmdTablePtr++) {
        if (RegisterCommand(interp, packageName, cmdTablePtr) != TCL_OK) {
            return TCL_ERROR;
        }
    }
    
    for (varTablePtr=&variables[0] ; varTablePtr->varName ; varTablePtr++) {
        if (RegisterVariable(interp, packageName, varTablePtr) != TCL_OK) {
            return TCL_ERROR;
        }
    }
    
    return Tcl_PkgProvide(interp, packageName, packageVersion);
}

/*
 *----------------------------------------------------------------------
 *
 * RegisterCommand --
 *
 *	This procedure registers a command in the context of the given
 *	namespace.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
RegisterCommand(interp, namespace, cmdTablePtr)
    Tcl_Interp* interp;			/* the Tcl interpreter for which the
					 * operation is performed */
    char *namespace;			/* the namespace in which the command
					 * is registered */
    CONST CmdTable *cmdTablePtr;	/* the command to register */
{
    char buf[128];

    if (cmdTablePtr->exportIt) {
	sprintf(buf, "namespace eval %s { namespace export %s }",
		namespace, cmdTablePtr->cmdName);
	if (Tcl_Eval(interp, buf) != TCL_OK)
	    return TCL_ERROR;
    }

    sprintf(buf, "%s::%s", namespace, cmdTablePtr->cmdName);
    Tcl_CreateObjCommand(interp, buf, cmdTablePtr->proc, 0, 0);

    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * RegisterVariable --
 *
 *	This procedure registers a variable in the context of the given namespace.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
RegisterVariable(interp, namespace, varTablePtr)
    Tcl_Interp* interp;		    /* the Tcl interpreter for which the
                                     * operation is performed */
    char *namespace;		    /* the namespace in which the variable is
                                     * registered */
    CONST VarTable *varTablePtr;    /* the variable to register */
{
    char buf[1024];
    sprintf(buf, "namespace eval %s { variable %s {%s} }",
            namespace, varTablePtr->varName, varTablePtr->varValue);
    if (Tcl_Eval(interp, buf) != TCL_OK)
        return TCL_ERROR;

    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * CompilerGetPackageName --
 *
 *  Returns the package name for the compiler package.
 *
 * Results:
 *	See above.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

CONST char *
CompilerGetPackageName()
{
    return packageName;
}
