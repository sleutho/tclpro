/* 
 * bigInit.c --
 *
 *	Provides a default version of the Tcl_AppInit procedure for use
 *	in a Tcl-shell or Tk-shell based applications.  This particular
 *	file contains (conditional) initialization for Tcl shells (Tk
 *	shells) that contain [incr Tcl] ([incr Tk],  Expect, TclX (TkX).
 *
 * Copyright (c) 1993 The Regents of the University of California.
 * Copyright (c) 1994 Sun Microsystems, Inc.
 * Copyright (c) 1999-2000 Ajuba Solutions
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: proAppInit.c,v 1.10 2001/11/23 20:45:57 andreas_kupries Exp $
 */

#include "tcl.h"
#include "tclInt.h"


#ifdef TCLPRO_USE_EXPECT
#include "expect_tcl.h"
#endif

#ifdef TCLPRO_USE_TCLX
#include "tclExtend.h"
#endif

#ifdef TCLPRO_USE_TK
#include "tk.h"
#endif

#ifdef TCLPRO_USE_TBCLOAD
/* Hack to get static references to TbcLoad */
#undef DLLIMPORT
#define DLLIMPORT
#include "proTbcLoad.h"
#endif

#ifdef TCLPRO_USE_ITCL
#include "itcl.h"
# ifdef TCLPRO_USE_TK
# include "itk.h"
# endif
#endif



#ifdef TCLPRO_WINDOWS_EXTENSIONS
#undef DLLIMPORT
#define DLLIMPORT
EXTERN int Registry_Init(Tcl_Interp *interp);
EXTERN int Dde_Init(Tcl_Interp *interp);
#endif

#ifdef TCLPRO_USE_COMPILER
EXTERN int Tclcompiler_Init(Tcl_Interp *interp);
EXTERN char *CompilerGetPackageName();
#endif

#ifdef TCLPRO_TEST_COMPILER
EXTERN int Cmptest_Init(Tcl_Interp *interp);
EXTERN char *CmptestGetPackageName();
#endif

#ifdef TCLPRO_USE_PARSER
EXTERN int Tclparser_Init(Tcl_Interp *interp);
#endif

#ifdef TCLPRO_USE_WINUTIL
EXTERN int Dbgext_Init(Tcl_Interp *interp);
#endif

#ifdef TCLPRO_USE_WINICO
EXTERN int Winico_Init(Tcl_Interp *interp);
#endif

extern int Pro_WrapIsWrapped _ANSI_ARGS_((
    CONST char *wrapFileName,
    char **wrappedStartupFileNamePtr,
    char **wrappedArgsPtr));

/*
 *----------------------------------------------------------------------
 *
 * TclPro_AppInit --
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

int
TclPro_AppInit(interp)
    Tcl_Interp *interp;		/* Interpreter for application. */
{

    if (Tcl_AppInit(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }

#ifdef TCLPRO_USE_TBCLOAD
    if (Tbcload_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, (char *) TbcloadGetPackageName(),
	    Tbcload_Init, Tbcload_SafeInit);
#endif /* TCLPRO_USE_TBCLOAD */
    
#ifdef TCLPRO_USE_COMPILER
    if (Tclcompiler_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, (char *) CompilerGetPackageName(),
            Tclcompiler_Init, (Tcl_PackageInitProc *) NULL);

#ifdef TCLPRO_TEST_COMPILER
    if (Cmptest_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, (char *) CmptestGetPackageName(),
            Cmptest_Init, (Tcl_PackageInitProc *) NULL);
#endif
#endif

#ifdef TCLPRO_USE_PARSER
    if (Tclparser_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "tclParser", Tclparser_Init,
	(Tcl_PackageInitProc *) NULL);
#endif

#ifdef TCLPRO_USE_WINICO
    if (Winico_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "Winico", Winico_Init,
	(Tcl_PackageInitProc *) NULL);
#endif

#ifdef TCLPRO_USE_WINUTIL
    if (Dbgext_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "dbgext", Dbgext_Init,
	(Tcl_PackageInitProc *) NULL);
#endif

#ifdef TCLPRO_USE_EXPECT
    Tcl_StaticPackage((Tcl_Interp *) NULL, "Expect", Expect_Init,
	    (Tcl_PackageInitProc *) NULL);
#endif /* TCLPRO_USE_EXPECT */

#ifdef TCLPRO_USE_ITCL    
    /*
     * To provide TclPro 1.0/1.1 compatiblity, we will import all [incr Tcl]
     * commands by default into the global namespace when using "-uses itclsh"
     * and "-uses iwish".  Set the "itcl::native" variable so we can do the
     * same kind of import automatically during the "auto_mkindex" operation.
     * The deprecated "if" clause should be removed when support for the names
     * "itclsh" and "iwish" are removed from TclPro * Wrapper.
     */
 
    Tcl_StaticPackage((Tcl_Interp *) NULL, "Itcl", Itcl_Init, Itcl_SafeInit);
    Tcl_Eval(interp,
	     "if {[info exists ::tcl_uses_itclsh_deprecated]} {\n\
		  package require Itcl\n\
	          namespace import ::itcl::*\n\
	          auto_mkindex_parser::slavehook {\n\
		      _%@namespace import - force itcl::*\n\
		  }\n\
	      }");

#ifdef TCLPRO_USE_TK
    /*
     * To provide TclPro 1.0/1.1 compatibility, we will import all [incr Tcl]
     * commands by default into the global namespace when using "-uses itclsh"
     * and "-uses iwish".  Set the "itcl::native" variable so we can do the
     * same kind of import automatically during the "auto_mkindex" operation.
     * The deprecated "if" clause should be removed when support for the names
     * "itclsh" and "iwish" are removed from TclPro * Wrapper.
     */

    Tcl_StaticPackage((Tcl_Interp *) NULL, "Itk", Itk_Init,
		      (Tcl_PackageInitProc *) NULL);
    Tcl_Eval(interp,
	     "if {[info exists ::tcl_uses_iwish_deprecated]} {\n\
	         package require Itcl\n\
		 package require Itk\n\
		 namespace import ::itk::*\n\
		 auto_mkindex_parser::slavehook {\n\
		     _%@namespace import - force itk::*\n\
		 }\n\
	     }");
#endif /* TCLPRO_USE_TK */
#endif /* TCLPRO_USE_ITCL */

    
#ifdef TCLPRO_USE_TCLX    
    Tcl_StaticPackage ((Tcl_Interp *) NULL, "Tclx", Tclx_Init, Tclx_SafeInit);
#ifdef TCLPRO_USE_TK
    Tcl_StaticPackage ((Tcl_Interp *) NULL, "Tkx", Tkx_Init, Tkx_SafeInit);
#endif /* TCLPRO_USE_TK */
#endif /* TCLPRO_USE_TCLX */
    
#ifdef TCLPRO_WINDOWS_EXTENSIONS
    Tcl_StaticPackage ((Tcl_Interp *) NULL, "Registry", Registry_Init, NULL);
    Tcl_StaticPackage ((Tcl_Interp *) NULL, "Dde", Dde_Init, NULL);
#endif

    return TCL_OK;
}
