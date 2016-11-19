#define STATIC_BUILD
#include <tcl.h>
#include <itcl.h>
#include <proWrap.h>
#include <proTbcLoad.h>

Tcl_AppInitProc MyAppInit;

int
main(int argc, char *argv[])
{
    Pro_WrapTclMain(argc, argv, MyAppInit);
    return 0;
}

int
MyAppInit(Tcl_Interp *interp)
{
    extern Tcl_PackageInitProc Stack_Init;

    if (Tcl_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }

    if (Itcl_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "Itcl", Itcl_Init, Itcl_SafeInit);

    if (Stack_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "Stack", Stack_Init, Stack_Init);

    if (Tbcload_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "tbcload", Tbcload_Init, Tbcload_SafeInit);

    return TCL_OK;
}

