/*
 *  Example application that embeds a Tcl interpreter.
 */

#define STATIC_BUILD
#include <tcl.h>

int
main (int argc, char *argv[])
{
    Tcl_Interp *interp;
    char buffer[1024];


    /*
     * Tcl_FindExecutable has the important side effects of initializing
     # the UTF-8 encoding subsystem by finding the Tcl encoding files.
     */

    Tcl_FindExecutable(argv[0]);

    interp = Tcl_CreateInterp();

#ifdef notdef
    /*
     * This hardwires the location of the directory containing "init.tcl"
     */
    Tcl_SetVar(interp, "tcl_library", "/opt/ajuba/TclPro1.4/lib/tcl8.3", TCL_GLOBAL_ONLY);
#endif

    if (Tcl_Init(interp) != TCL_OK) {

	/*
	 * This means Tcl was unable to find the Tcl script library.
	 *
	 * You can deal with this in several ways:
	 * 1) Hardwire the location into your binary by setting the "tcl_library"
	 *	variable as in the above ifdef clause
	 * 2) Have users set the TCL_LIBRARY environment variable
	 * 3) Install your program into the TclPro1.4/<arch>/bin directory, in
	 *	which case Tcl will find the ../../lib/tcl8.3 directory automatically
	 * 4) Ignore the issue.  This just means you do not have the "unknown"
	 *	command hook and other conveniences defined in the script library.
	 */

	printf("Warning: ");
	printf(Tcl_GetStringResult(interp));
	printf("Proceeding anyway...\n");
	/* exit(1); */
    }

    /*
     * Run some Tcl.  Another useful API here is Tcl_EvalFile to run a script from a file.
     */

    Tcl_Eval(interp, "puts \"hello world!\"");

    /*
     * For anything non-trivial, you must put the script into a variable so
     * Tcl can scribble on it while parsing. Or, compile with 
     * -fwritable-strings.
     */

    strcpy(buffer, "puts \"The time is [clock format [clock seconds]]\"");
    Tcl_Eval(interp, buffer);

    Tcl_DeleteInterp(interp);
    Tcl_Finalize();
    return 0;
}
