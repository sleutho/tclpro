/* 
 * tclUnzip.c --
 *
 *	TclPro Application Packager implementation and hooks.
 *
 * Copyright (c) 1998 by Scriptics, Corp.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: tclUnzip.c,v 1.3 2000/03/15 00:15:33 berry Exp $
 */

#include <tcl.h>
#include <tclInt.h>
#include <tclPort.h>

#include "unzip.h"


static int	UnzipCmd _ANSI_ARGS_((ClientData, Tcl_Interp*, int, char**));
static int	UnzipMemCmd _ANSI_ARGS_((ClientData, Tcl_Interp*, int, char**));
static int	UnzipStatCmd _ANSI_ARGS_((ClientData, Tcl_Interp*, int, char**));


/*
 *----------------------------------------------------------------------
 *
 * UnzipCmd --
 *
 *	A Tcl-ized interface ot the UnZip command line.  See the "UnZip"
 *	command line documentation for more details.
 *
 * Results:
 *      If the UnZip library succeeds or produces warnings TCL_OK is
 *	returned, TCL_ERROR otherwise.
 *
 * Side effects:
 *      None.
 *
 *----------------------------------------------------------------------
 */

static int
UnzipCmd(clientData, interp, argc, argv)
    ClientData clientData;              /* Not used. */
    Tcl_Interp *interp;                 /* Current interpreter. */
    int argc;                           /* Number of arguments. */
    char **argv;                        /* Argument strings. */
{
    int retVal = TCL_ERROR;

    if (argc < 2) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		argv[0], " ?args ...?\"",
                (char *) NULL);
    } else {
        int iError = 0;
	UzpInit uzpInit;

	uzpInit.structlen = sizeof(UzpInit);
	uzpInit.msgfn = WrapMessageFnCallBack;
	uzpInit.inputfn = (InputFn*)NULL;
	uzpInit.pausefn = (PauseFn*)NULL;
	uzpInit.userfn = NULL;

	theCurrentInterp = interp;
	iError = UzpAltMain(argc, argv, &uzpInit);
	theCurrentInterp = NULL;

	if (!iError) {
	    retVal = TCL_OK;
	} else if (iError <= PK_WARN) {
	    char buff[20];
	    sprintf(buff, "%i", iError);
	    Tcl_AppendResult(interp, " unzip warning: ", buff, (char*)NULL);
	    retVal = TCL_OK;
	} else {
	    char buff[20];
	    sprintf(buff, "%i", iError);
	    Tcl_AppendResult(interp, " unzip error: ", buff, (char*)NULL);
	}
    }

    return (retVal);
}

/*
 *--------------------------------------------------------------------
 *
 * UnzipMemCmd --
 *
 *	.... @@@ ....
 *
 * Results:
 *      A standard Tcl result.
 *
 * Side effects:
 *      None.
 *
 *----------------------------------------------------------------------
 */

static int
UnzipMemCmd(clientData, interp, argc, argv)
    ClientData clientData;              /* Not used. */
    Tcl_Interp *interp;                 /* Current interpreter. */
    int argc;                           /* Number of arguments. */
    char **argv;                        /* Argument strings. */
{
    int retVal = TCL_ERROR;
    int iError = 0;
    UzpBuffer uzpBuffer;

    if (argc != 3) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		argv[0], " zip-filename filename-to-extract\"",
                (char *) NULL);
    } else if ((iError = UzpUnzipToMemory(argv[1], (char *)TranslateFilename(argv[2]),
	    &uzpBuffer)) <= PK_WARN) {
	/* @@@ The following result setting needs to be modified to support
		binary blocks of data: switch to using Tcl objects results. */
	Tcl_SetResult(interp, uzpBuffer.strptr, TCL_VOLATILE);
	free(uzpBuffer.strptr);	    /* @@@ Unzip API should provide a free routine */
	retVal = TCL_OK;
    } else {
	char szBuffer[20];
	sprintf(szBuffer, "%i", iError);
	Tcl_AppendResult(interp, "unzip error: ", szBuffer, (char*)NULL);
    }

    return (retVal);
}

/*
 *--------------------------------------------------------------------
 *
 * UnzipStatCmd --
 *
 *	.... @@@ ....
 *
 * Results:
 *      A standard Tcl result.
 *
 * Side effects:
 *      None.
 *
 *----------------------------------------------------------------------
 */

static int
UnzipStatCmd(clientData, interp, argc, argv)
    ClientData clientData;              /* Not used. */
    Tcl_Interp *interp;                 /* Current interpreter. */
    int argc;                           /* Number of arguments. */
    char **argv;                        /* Argument strings. */
{
    int retVal = TCL_OK;
    int iError = 0;
    struct stat statbuf;
    UzpInit uzpInit;
 
    uzpInit.structlen = sizeof(UzpInit);
    uzpInit.msgfn = WrapMessageFnCallBack;
    uzpInit.inputfn = (InputFn*)NULL;
    uzpInit.pausefn = (PauseFn*)NULL;
    uzpInit.userfn = NULL;

    if (argc != 4) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		argv[0], " zip-filename filename-to-stat varName\"",
                (char *) NULL);
	retVal = TCL_ERROR;
    } else if ((iError = UzpStat(argv[1], (char *)TranslateFilename(argv[2]),
	    &statbuf, &uzpInit)) > PK_WARN) {
	char szBuffer[20];
	sprintf(szBuffer, "%i", iError);
	Tcl_AppendResult(interp, "unzip error: ", szBuffer, (char*)NULL);
	retVal = TCL_ERROR;
    } else {
	/* @@@ The following is taken directly out of the file
	   "tcl8.0/generic/tclCmdAH.c" from the function "static int StoreStatData()".
	   It may be cleaner to simply rename that function to "int TclStoreStatData()"
	   and call it from here. */
 	struct stat *statPtr = &statbuf;
	char* varName = argv[3];
	char string[30];

	sprintf(string, "%ld", (long) statPtr->st_dev);
	if (Tcl_SetVar2(interp, varName, "dev", string, TCL_LEAVE_ERR_MSG)
		== NULL) {
	    return TCL_ERROR;
	}
	sprintf(string, "%ld", (long) statPtr->st_ino);
	if (Tcl_SetVar2(interp, varName, "ino", string, TCL_LEAVE_ERR_MSG)
		== NULL) {
	    return TCL_ERROR;
	}
	sprintf(string, "%ld", (long) statPtr->st_mode);
	if (Tcl_SetVar2(interp, varName, "mode", string, TCL_LEAVE_ERR_MSG)
		== NULL) {
	    return TCL_ERROR;
	}
	sprintf(string, "%ld", (long) statPtr->st_nlink);
	if (Tcl_SetVar2(interp, varName, "nlink", string, TCL_LEAVE_ERR_MSG)
		== NULL) {
	    return TCL_ERROR;
	}
	sprintf(string, "%ld", (long) statPtr->st_uid);
	if (Tcl_SetVar2(interp, varName, "uid", string, TCL_LEAVE_ERR_MSG)
		== NULL) {
	    return TCL_ERROR;
	}
	sprintf(string, "%ld", (long) statPtr->st_gid);
	if (Tcl_SetVar2(interp, varName, "gid", string, TCL_LEAVE_ERR_MSG)
		== NULL) {
	    return TCL_ERROR;
	}
	sprintf(string, "%lu", (unsigned long) statPtr->st_size);
	if (Tcl_SetVar2(interp, varName, "size", string, TCL_LEAVE_ERR_MSG)
		== NULL) {
	    return TCL_ERROR;
	}
	sprintf(string, "%ld", (long) statPtr->st_atime);
	if (Tcl_SetVar2(interp, varName, "atime", string, TCL_LEAVE_ERR_MSG)
		== NULL) {
	    return TCL_ERROR;
	}
	sprintf(string, "%ld", (long) statPtr->st_mtime);
	if (Tcl_SetVar2(interp, varName, "mtime", string, TCL_LEAVE_ERR_MSG)
		== NULL) {
	    return TCL_ERROR;
	}
	sprintf(string, "%ld", (long) statPtr->st_ctime);
	if (Tcl_SetVar2(interp, varName, "ctime", string, TCL_LEAVE_ERR_MSG)
		== NULL) {
	    return TCL_ERROR;
	}
	{
	    char* modeStr = "unknown";
	    if (S_ISREG((int) statPtr->st_mode)) {
		modeStr = "file";
	    } else if (S_ISDIR((int) statPtr->st_mode)) {
		modeStr = "directory";
	    } else if (S_ISCHR((int) statPtr->st_mode)) {
		modeStr = "characterSpecial";
	    } else if (S_ISBLK((int) statPtr->st_mode)) {
		modeStr = "blockSpecial";
	    } else if (S_ISFIFO((int) statPtr->st_mode)) {
		modeStr = "fifo";
#ifdef S_ISLNK
	    } else if (S_ISLNK((int) statPtr->st_mode)) {
		modeStr = "link";
#endif
#ifdef S_ISSOCK
	    } else if (S_ISSOCK((int) statPtr->st_mode)) {
		modeStr = "socket";
#endif
	    }
	    if (Tcl_SetVar2(interp, varName, "type",
		    modeStr, TCL_LEAVE_ERR_MSG) 
		    == NULL) {
		return TCL_ERROR;
	    }
	}
    }

    return (retVal);
}

static int CreateUnzipCommands(interp)
{
    /*
     * Create some auxiliary commands to manipulate the contents of a
     * .zip file.  These commands are not used per'se by the packager
     * sub-system, but can be used by the user's Tcl application, if
     * they wish.  Perhaps a data file or maybe even a shared-library,
     * has been zipped into the application up that needs to be streamed
     * stream out to disk or into memory.
     */

    Tcl_CreateCommand(interp, "unzip", UnzipCmd, (ClientData) 0,
            (Tcl_CmdDeleteProc *) NULL);
    Tcl_CreateCommand(interp, "unzipmem", UnzipMemCmd, (ClientData) 0,
            (Tcl_CmdDeleteProc *) NULL);
    Tcl_CreateCommand(interp, "unzipstat", UnzipStatCmd, (ClientData) 0,
            (Tcl_CmdDeleteProc *) NULL);

}

