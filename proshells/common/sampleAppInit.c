/* 
 * sampleAppInit.c --
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
 * RCS: @(#) $Id: sampleAppInit.c,v 1.1 2000/08/04 08:04:29 welch Exp $
 */

#include "tcl.h"
#include "tclInt.h"


#ifdef TCLPRO_USE_EXPECT
#include "expect_tcl.h"
#endif

#ifdef TCLPRO_USE_ITCL
#include "itcl.h"
#endif

#ifdef TCLPRO_USE_TCLX
#include "tclExtend.h"
#endif

#ifdef TCLPRO_USE_TK
#include "tk.h"
#ifdef TCLPRO_USE_ITCL
#include "itk.h"
#endif
#endif

#ifdef TCLPRO_USE_TBCLOAD
/*
 * Clear the definition of DLLIMPORT to force static references to 
 * the Tbcload_Init function.
 */
#undef DLLIMPORT
#define DLLIMPORT
#include "proTbcLoad.h"
#endif

#ifdef TCLPRO_WINDOWS_EXTENSIONS
#undef DLLIMPORT
#define DLLIMPORT
EXTERN int Registry_Init(Tcl_Interp *interp);
EXTERN int Dde_Init(Tcl_Interp *interp);
#endif

#ifdef TCLPRO_USE_WINICO
EXTERN int Winico_Init(Tcl_Interp *interp);
#endif


/*
 *----------------------------------------------------------------------
 *
 * Sample_AppInit --
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
Sample_AppInit(interp)
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
    
#ifdef TCLPRO_USE_WINICO
    if (Winico_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "Winico", Winico_Init,
	(Tcl_PackageInitProc *) NULL);
#endif

#ifdef TCLPRO_USE_EXPECT
    Tcl_StaticPackage((Tcl_Interp *) NULL, "Expect", Expect_Init,
	    (Tcl_PackageInitProc *) NULL);
#endif /* TCLPRO_USE_EXPECT */

#ifdef TCLPRO_USE_ITCL    
    /*
     * To provide "itclsh" compatibility, we will import all [incr Tcl]
     * commands by default into the global namespace.
     * Set the "itcl::native" variable so we can do the
     * same kind of import automatically during the "auto_mkindex" operation.
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
