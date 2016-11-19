# Simple makefile for an application linked against the Tcl library

OBJECTS = App2.o
PROG = App2

# Set TCLPRO_HOME to the root of your TclPro installation

#TCLPRO_HOME = /opt/ajuba/TclPro1.4
TCLPRO_HOME = /home/welch/TclPro1.4

# Pick your compiler. We have used gcc on all platforms but IRIX,
# where we use the vendor-supplied cc.

CC = gcc
#CC = cc

# Set compiler flags.  For IRIX you'll need -n32
# For a more sophisticated way of determining these flags
# you can use autoconf as illustrated by the App3 example.

CFLAGS = -g
#CFLAGS = -g -n32

# Link libraries.  This is the thing thata varies most among platforms.
# Again, the most robust way to determine these is to use autoconf,
# but we'll show you what we've come up with on the TclPro platforms.

LIBS = -L$(TCLPRO_HOME)/linux-ix86/lib -ltcl8.3
#LIBS = -L$(TCLPRO_HOME)/solaris-sparc/lib -ltcl8.3

$(PROG) : $(OBJECTS)
	$(CC) $(OBJECTS) $(LIBS) -o $(PROG)
