/*
 *  Example application that embeds a Tcl interpreter.
 */

#define STATIC_BUILD
#include <tcl.h>

int
main (int argc, char *argv[])
{
    Tcl_Interp *interp;


    /*
     * Tcl_FindExecutable has the important side effects of initializing
     * the UTF-8 encoding subsystem by finding the Tcl encoding files.
     */

    Tcl_FindExecutable(argv[0]);

    interp = Tcl_CreateInterp();

    /*
     * Setting the tcl_library variable fixes the location of the Tcl script library.
     * If you do not want to predetermine this location, then you can install the binary
     * in the "standard location" and the Tcl runtime will find the script
     * library automatically.  If the Tcl script library is
     * ...somewhere/TclPro1.4/lib/tcl8.3
     * then the standard location for the executable is in
     * ...somewhere/TclPro1.4/win32-ix86/bin
     */

    Tcl_SetVar(interp, "tcl_library", "C:/PROGRAM FILES/TCLPRO1.4/lib/tcl8.3", TCL_GLOBAL_ONLY);

    if (Tcl_Init(interp) != TCL_OK) {

	/* 
	 * By the way, if you do not care about the "unknown" command and other features
	 * added by the init.tcl script library, you don't need to even call Tcl_Init,
	 * nor set up the tcl_library variable as above.
	 */

	puts(Tcl_GetStringResult(interp));
	return 1;
    }

    /*
     * Run some Tcl.  Another useful API here is Tcl_EvalFile to run a script from a file.
     */

    Tcl_Eval(interp, "puts \"hello world!\"");

    Tcl_DeleteInterp(interp);
    Tcl_Finalize();
    return 0;
}
