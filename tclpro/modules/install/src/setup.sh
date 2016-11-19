#!/bin/sh

# SETUP.SH --
# 
#   This file boot-straps the TclPro installation.
# 
# Copyright (c) 1998-1999 by Scriptics Corporation.
# All rights reserved.
# 
# RCS: @(#) $Id: setup.sh,v 1.4 2001/03/15 06:03:25 karll Exp $

#
# Initialize
#

GUI_MODE=true
TEXT_MODE=false
BAD_ARGS=false

usage="Usage: $0 [-T[ext]]"

#
# Parse the arguments
#

for arg in $@
do
    if [ "$arg" = "-T" -o "$arg" = "-Text" ]; then
	TEXT_MODE=true
	GUI_MODE=false
    else
	BAD_ARGS=true
    fi
done

$BAD_ARGS && echo "$usage" && exit 0

#
# Verify if a GUI installation can be performed.
#

if [ "$TEXT_MODE" = "false" -a "$DISPLAY" = "" ]; then
    echo ""
    echo "Note: The DISPLAY environment variable is not set."
    echo "      Please set it to perform graphical installation."
    echo "      Proceeding with text based installation."
    echo ""
    GUI_MODE=false
    TEXT_MODE=true
fi

SETUP_ROOT=`dirname $0`
cd $SETUP_ROOT

SETUP_ROOT="NOSUCHDIR"
DIRLIST="unix UNIX unix. UNIX."
for i in $DIRLIST; do
    if [ -d $i ] ; then
	SETUP_ROOT="$i"
    fi
done
cd $SETUP_ROOT

SETUP_ROOT=`pwd`
HOST_TYPE=`uname -srvm`

case $HOST_TYPE in
    SunOS\ 5.*\ sun4*)
	$TEXT_MODE && programList="ptsol* PTSOL*"
	$GUI_MODE && programList="pwsol* PWSOL*"
	HOST_TYPE=solaris-sparc
        ;;

    HP-UX\ ?.10.*\ 9000/*)
	$TEXT_MODE && programList="pthp* PTHP*"
	$GUI_MODE && programList="pwhp* PWHP*"
	HOST_TYPE=hpux-parisc
        ;;

    HP-UX\ ?.11.*\ 9000/*)
	$TEXT_MODE && programList="pthp* PTHP*"
	$GUI_MODE && programList="pwhp* PWHP*"
	HOST_TYPE=hpux-parisc
        ;;

    Linux*)
	$TEXT_MODE && programList="ptlin* PTLIN*"
	$GUI_MODE && programList="pwlin* PWLIN*"

	#
	# Need to check for Linux systems using older libc libraries
	# that will not work with our Linux distribution.
	#
	glibc=`ldd PWLIN pwlin PWLIN. pwlin. 2>/dev/null | grep libc.so.6`
	if [ -z "$glibc" ]; then
	    echo "Cannot find GNU Libc 2.0.6 library required by TclPro."
	    echo ""
	    echo "If you are using Red Hat Linux 5.0+ on an Intel processor,"
	    echo "please report this bug at the following web site:"
	    echo "     http://www.scriptics.com/support/bugForm"
	    echo ""
	    echo "Otherwise, please consider upgrading to Red Hat Linux 5.0+"
	    echo "or another Linux distribution that uses GNU Libc 2.0.6."
	    exit 0
        fi
	HOST_TYPE=linux-ix86
	;;

    IRIX*)
	$TEXT_MODE && programList="ptsgi* PTSGI*"
	$GUI_MODE && programList="pwsgi* PWSGI*"
	HOST_TYPE=irix-mips
	;;


    IRIX*)
	$TEXT_MODE && programList="ptsgi* PTSGI*"
	$GUI_MODE && programList="pwsgi* PWSGI*"
	HOST_TYPE=irix-mips
	;;


    IRIX*)
	$TEXT_MODE && programList="ptsgi* PTSGI*"
	$GUI_MODE && programList="pwsgi* PWSGI*"
	HOST_TYPE=irix-mips
	;;

    AIX*)
	$TEXT_MODE && programList="ptaix* PTAIX*"
	$GUI_MODE && programList="pwaix* PWAIX*"
	HOST_TYPE=aix-risc
	;;

    FreeBSD*)
	$TEXT_MODE && programList="ptbsd* PTBSD*"
	$GUI_MODE && programList="pwbsd* PWBSD*"
	HOST_TYPE=freebsd-ix86
	;;

    *)
        echo 1>&2 "Error: $HOST_TYPE is not a supported platform."
	exit 0
        ;;
esac

PATH=${SETUP_ROOT}:$PATH
export PATH

TMPDIR=/tmp
TCLPRODEST_FILE=$TMPDIR/tclpro$$.dest
touchPathList="/bin /usr/bin"

find_program() {
    PROGRAM="NOSUCHFILE"
    for i in $programList; do
	if [ -f $i ] ; then
	    PROGRAM=$i
	fi
    done
}

find_touch() {
    touch="NOSUCHFILE"
    for i in $touchPathList; do
	if [ -f $i/touch ] ; then
	    touch=$i/touch
	fi
    done
}

cleanup() {
    trap `` 1 2 15
 
    echo ""; echo ""
    if [ -f $TCLPRODEST_FILE ]; then
        echo ""; echo ""
	echo "Warning: TclPro installation aborted by the user."
	if [ -d "`cat $TCLPRODEST_FILE`" ]; then
            echo "         You may have an incomplete installation"
            echo "         in the following directory:"
	    echo "         `cat $TCLPRODEST_FILE`."
	fi
	echo ""; echo ""
	/bin/rm -f $TCLPRODEST_FILE
    fi
    exit 1
}
 
find_touch
$touch $TCLPRODEST_FILE 2> /dev/null

find_program

if [ ! -f $TCLPRODEST_FILE ]; then
    echo "Error: TclPro installation could not create temp. files in '$TCLPRODEST_FILE'."
else
    if [ ! -f $PROGRAM ]; then
        echo "Error: Could not locate the TclPro installation application."
    else
        trap cleanup 1 2 15

	# The umask affects the permissions on directories created by zip
	# TclPro 1.3 and earlier this was 000 which lead to
	# world-writable directories.

        umask 022

        $PROGRAM $HOST_TYPE $SETUP_ROOT $TEXT_MODE $TCLPRODEST_FILE
    fi

    /bin/rm -f $TCLPRODEST_FILE
fi

