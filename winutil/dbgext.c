/* 
 * dbgext.c --
 *
 *	The file contains various C based commands used by the Tcl
 *	debugger.  In the future these types of commands may work
 *	themselves into the Tcl core.
 *
 * Copyright (c) 1998-2000 Ajuba Solutions
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: dbgext.c,v 1.3 2000/05/30 21:15:01 wart Exp $
 */

#include "tkWinInt.h"
#include "tclInt.h"
#include "tclWinInt.h"
#include <shellapi.h>


/*
 * Declarations for functions defined in this file.
 */

static int  KillObjCmd _ANSI_ARGS_((ClientData clientData,
		Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
static int  ShortNameObjCmd _ANSI_ARGS_((ClientData clientData,
		Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
static int  StartObjCmd _ANSI_ARGS_((ClientData clientData,
		Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
static int  WinHelpObjCmd _ANSI_ARGS_((ClientData clientData,
		Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));


/*
 *----------------------------------------------------------------------
 *
 * Dbgext_Init --
 *
 *	This procedure initializes the parse command.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int DLLEXPORT
Dbgext_Init(interp)
    Tcl_Interp *interp;
{

    if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
	return TCL_ERROR;
    }

//    Tcl_PkgRequire(interp, "Tk", TK_VERSION, 0);
    
    if (Tk_InitStubs(interp, TK_VERSION, 0) == NULL) {
	return TCL_ERROR;
    }
    
    Tcl_CreateObjCommand(interp, "kill", KillObjCmd, NULL, NULL);
    Tcl_CreateObjCommand(interp, "winHelp", WinHelpObjCmd, NULL, NULL);
    Tcl_CreateObjCommand(interp, "shortname", ShortNameObjCmd, NULL, NULL);
    Tcl_CreateObjCommand(interp, "start", StartObjCmd, NULL, NULL);

    return Tcl_PkgProvide(interp, "dbgext", VERSION);
}

/*
 *----------------------------------------------------------------------
 *
 * KillObjCmd --
 *
 *	This function will kill a process given a passed in PID.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	The specified process will die.
 *
 *----------------------------------------------------------------------
 */

static int
KillObjCmd(dummy, interp, objc, objv)
    ClientData dummy;		/* Not used. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int objc;			/* Number of arguments. */
    Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    int pid, result;
    HANDLE processHandle;


    if (objc != 2) {
	Tcl_WrongNumArgs(interp, 1, objv, "pid");
	return TCL_ERROR;
    }

    result = Tcl_GetIntFromObj(interp, objv[1], &pid);
    if (result != TCL_OK) {
	return result;
    }

    processHandle = OpenProcess(PROCESS_TERMINATE, FALSE, pid);
    if (processHandle == NULL) {
	Tcl_AppendResult(interp, "invalid pid", (char *) NULL);
	return TCL_ERROR;
    }

    TerminateProcess(processHandle, 7);
    CloseHandle(processHandle);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WinHelpObjCmd --
 *
 *	This function launch the WINHELP.EXE application and show help
 *	based on the information passed in.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	The WINHELP.EXE will be launached and/or change state.
 *
 *----------------------------------------------------------------------
 */

static int
WinHelpObjCmd(dummy, interp, objc, objv)
    ClientData dummy;		/* Not used. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int objc;			/* Number of arguments. */
    Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    Tk_Window main = Tk_MainWindow(interp);
    HWND hWnd;
    char *string, *nativeName;
    Tcl_DString buffer, nativeStr;
    int result;
    unsigned long sectionNumber;

    hWnd = TkWinGetWrapperWindow(main);

    if (! ((objc == 2) || (objc == 3))) {
	Tcl_WrongNumArgs(interp, 1, objv, "path ?section?");
	return TCL_ERROR;
    }

    /*
     * Get the file path to the help file.
     */
    
    string = Tcl_GetStringFromObj(objv[1], NULL);
    nativeName = Tcl_TranslateFileName(interp, string, &buffer);
    if (nativeName == NULL) {
	return TCL_ERROR;
    }
    nativeName = Tcl_UtfToExternalDString(NULL, nativeName, -1, &nativeStr);

    /*
     * Get the sub section if given.
     */
    
    if (objc == 3) {
	result = Tcl_GetLongFromObj(interp, objv[2], &sectionNumber);
	if (result != TCL_OK) {
	    result = TCL_ERROR;
	} else {
	    WinHelp(hWnd, nativeName, HELP_CONTEXT, sectionNumber);
	}
    } else {
	WinHelp(hWnd, nativeName, HELP_FINDER, 0);
	result = TCL_OK;
    }

    Tcl_DStringFree(&buffer);
    Tcl_DStringFree(&nativeStr);
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * ShortNameObjCmd --
 *
 *	Compute the short form of a Windows path.
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
ShortNameObjCmd(dummy, interp, objc, objv)
    ClientData dummy;		/* Not used. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int objc;			/* Number of arguments. */
    Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    char *string, *nativeName;
    Tcl_DString buffer, longBuf, shortBuf;
    DWORD length;
    Tcl_Obj *resultObj;
    int result;

    if (objc != 2) {
	Tcl_WrongNumArgs(interp, 1, objv, "path");
	return TCL_ERROR;
    }

    string = Tcl_GetStringFromObj(objv[1], NULL);
    nativeName = Tcl_TranslateFileName(interp, string, &buffer);
    if (nativeName == NULL) {
	return TCL_ERROR;
    }
    nativeName = Tcl_UtfToExternalDString(NULL, nativeName, -1, &longBuf);

    Tcl_DStringInit(&shortBuf);
    length = GetShortPathName(Tcl_DStringValue(&longBuf),
	    Tcl_DStringValue(&shortBuf),  0);
    Tcl_DStringSetLength(&shortBuf, length);
    length = GetShortPathName(Tcl_DStringValue(&longBuf),
	    Tcl_DStringValue(&shortBuf), length + 1);
    if (length == 0) {
	LPVOID lpMsgBuf;
	FormatMessage(
	    FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
	    NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
	    (LPTSTR) &lpMsgBuf, 0, NULL );
	Tcl_SetResult(interp, (char*) lpMsgBuf,TCL_VOLATILE);
	LocalFree(lpMsgBuf);
	result = TCL_ERROR;
    } else {
	resultObj = Tcl_GetObjResult(interp);
	Tcl_SetStringObj(resultObj, Tcl_DStringValue(&shortBuf), length);
	result = TCL_OK;
    }
    Tcl_DStringFree(&buffer);
    Tcl_DStringFree(&longBuf);
    Tcl_DStringFree(&shortBuf);
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * StartObjCmd --
 *
 *	Perform a ShellExecuteEx.
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
StartObjCmd(dummy, interp, objc, objv)
    ClientData dummy;		/* Not used. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int objc;			/* Number of arguments. */
    Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    SHELLEXECUTEINFO info;
    char *lpFileStr, *lpParmStr, *lpDirStr;
    Tcl_DString lpFileBuf, lpParmBuf, lpDirBuf;

    if (objc != 4) {
	Tcl_WrongNumArgs(interp, 1, objv, "executable args startdir");
	return TCL_ERROR;
    }

    /*
     * Convert all of the UTF stirings to the native encoding
     * before passing off the arguments to the system.
     */
    
    lpFileStr = Tcl_UtfToExternalDString(NULL, Tcl_GetStringFromObj(objv[1],
	    NULL), -1, &lpFileBuf);
    lpParmStr = Tcl_UtfToExternalDString(NULL, Tcl_GetStringFromObj(objv[2],
	    NULL), -1, &lpParmBuf);
    lpDirStr  = Tcl_UtfToExternalDString(NULL, Tcl_GetStringFromObj(objv[3],
	    NULL), -1, &lpDirBuf);

    memset(&info, 0, sizeof(SHELLEXECUTEINFO));
    info.cbSize       = sizeof(SHELLEXECUTEINFO);
    info.fMask        = SEE_MASK_FLAG_NO_UI;
    info.hwnd         = NULL;
    info.lpVerb       = NULL;
    info.lpFile       = lpFileStr;
    info.lpParameters = lpParmStr;
    info.lpDirectory  = lpDirStr;
    info.nShow        = SW_SHOWNORMAL;
    info.hInstApp     = NULL;
    info.hProcess     = NULL;

    if (ShellExecuteEx(&info) == 0) {
	TclWinConvertError(GetLastError());
	Tcl_SetResult(interp, Tcl_PosixError(interp), TCL_STATIC);
	return TCL_ERROR;
    }

    Tcl_DStringFree(&lpFileBuf);
    Tcl_DStringFree(&lpParmBuf);
    Tcl_DStringFree(&lpDirBuf);    
    return TCL_OK;
}
