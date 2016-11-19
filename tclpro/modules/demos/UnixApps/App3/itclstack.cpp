#include "itcl.h"
#include "stack.hpp"
#include <string.h>

extern "C" {
    Tcl_ObjCmdProc NewStackCmd;
    Tcl_CmdDeleteProc DeleteStackCmd;
    Tcl_ObjCmdProc StackCmd;
}

EXTERN int Stack_Init(Tcl_Interp*);

int
NewStackCmd (ClientData cdata, Tcl_Interp *interp,
	     int objc, Tcl_Obj *CONST objv[])
{
    static unsigned int id = 0;
    Stack<int> *newStackPtr = new Stack<int>();
    char newName[38];

    /*
     * Create a unique string to use for the new Tcl command and
     * then register the new command with the interpreter.
     */
    sprintf(newName, "stack%d", id++);
    Tcl_CreateObjCommand(interp, newName, StackCmd,
	    static_cast<ClientData>(newStackPtr), DeleteStackCmd);

    Tcl_SetObjResult(interp, Tcl_NewStringObj(newName, -1));

    return TCL_OK;
}


void DeleteStackCmd(ClientData cdata)
{
    delete static_cast<Stack<int> *>(cdata);
}


int
StackCmd (ClientData cdata, Tcl_Interp *interp,
	  int objc, Tcl_Obj *CONST objv[])
{
    Stack<int> *stack = static_cast<Stack<int> *>(cdata);

    if (objc < 2) {
	Tcl_SetObjResult(interp, Tcl_NewStringObj("wrong # args", -1));
	return TCL_ERROR;
    }

    if (strcmp(Tcl_GetStringFromObj(objv[1], NULL), "push") == 0)
    {
	int val;
	if (Tcl_GetIntFromObj(interp, objv[2], &val) != TCL_OK)
	{
	    return TCL_ERROR;
	}
	stack->push(val);
    }
    else if (strcmp(Tcl_GetStringFromObj(objv[1], NULL), "pop") == 0)
    {
	Tcl_Obj *val = Tcl_NewIntObj(stack->pop());
	Tcl_SetObjResult(interp, val);
    }
    else if (strcmp(Tcl_GetStringFromObj(objv[1], NULL), "peek") == 0)
    {
	Tcl_Obj *top = Tcl_NewIntObj(stack->peek());
	Tcl_SetObjResult(interp, top);
    }
    else
    {
	Tcl_SetObjResult(interp, Tcl_NewStringObj(
		"unknown sub-command.  Must be 'peek', 'pop', or 'push'." ,-1));
	return TCL_ERROR;
    }

    return TCL_OK;
}


EXTERN int
Stack_Init(Tcl_Interp* interp)
{
    if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
	return TCL_ERROR;
    }
    if (Itcl_InitStubs(interp, ITCL_VERSION, 0) == NULL) {
	return TCL_ERROR;
    }
  
    if (Itcl_RegisterObjC(interp, "createNewStack", NewStackCmd, NULL,
	    NULL) != TCL_OK) {
	return TCL_ERROR;
    }

    return TCL_OK;
}
