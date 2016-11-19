# newcheck3.tcl --
#
# This file contains several snippets of Tcl code, each of which
# has one or more errors.  It should be used as a sample input
# file for TclPro Checker.  This file contains potential upgrade
# problems.

# Every non-comment, non-blank line produces a warning under TclPro
# Checker, and none at all if the -use tk3.6 flag is specified.

# The command "pack newinfo" from Tk 3.6 is no longer supported.

pack newinfo .x.y

# Various options from Tk 3.6 are no longer supported.

frame .f -geometry "80x24"

canvas .c -scrollincrement 123

checkbutton .cb -selector red
radiobutton .rb -selector red

entry .e -scrollcommand {puts "Hi, Mom!"}

# tkerror is replaced with bgerror

tkerror "Oh dear"
