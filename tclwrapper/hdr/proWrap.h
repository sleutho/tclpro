/* 
 * proWrap.h --
 *
 *      Declarations of prototypes used by the TclPro Application Packager.
 *
 * Copyright (c) 1998 by Scriptics, Corp.
 * All rights reserved.
 *
 * RCS: @(#) $Id: proWrap.h,v 1.5 2000/08/04 09:16:17 welch Exp $
 */

#ifndef _PROWRAP
# define _PROWRAP

#ifndef _TCL
#   include <tcl.h>
#endif

#ifdef BUILD_wrapper
# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLEXPORT
#endif

/*
 * Prototypes of public functions for the TclPro Wrapper.
 */

EXTERN int	TclPro_Init _ANSI_ARGS_((int *argcPtr, char ***argvPtr));
EXTERN int	Pro_WrapInit _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN void	Pro_WrapPrependArgs _ANSI_ARGS_((
			char *prependArgs,
			int argc, char **argv,
			int *newArgcPtr, char ***newArgvPtr));
EXTERN int	Pro_WrapIsWrapped _ANSI_ARGS_((
			CONST char *wrapFileName,
			char **wrappedStartupFileNamePtr,
			char **wrappedArgsPtr));
EXTERN void	Pro_WrapTclMain _ANSI_ARGS_((
			int argc, char **argv,
			Tcl_AppInitProc *appInitProc));
EXTERN void	Pro_WrapTkMain _ANSI_ARGS_((
			int argc, char **argv,
			Tcl_AppInitProc *appInitProc));

# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLIMPORT

#endif /* _PROWRAP */

