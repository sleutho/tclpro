# prowrapUses.tcl --
#
#       This file contains all common parts for use by the various
#	.uses scripts.  
#
#	NOTE: These files are for REFERENCE purposes only and any
#	modifications will not change the behavior of TclPro Wrapper.
#	If you wish to make changes to this file, copy it (and any
#	file that sources this file) to different names and create a
#	custom "-uses" specification.
#
# Copyright (c) 1998-1999 by Scriptics Corporation.
# See the file "license.terms" for information on usage and redistribution of this file.
#
# RCS: @(#) $Id: prowrapUses.tcl,v 1.5 2000/10/31 23:31:25 welch Exp $


namespace eval prowrapUses {
    # As of TclPro 1.1 and beyond, we have removed support for the
    # "load" comand in statically wrapped applications for all platforms.
    # There are too many issues with attempting to load a .dll (Windows)
    # or .so (UNIX) file from much an executable.  TclPro Wrapper however
    # uses the "load" command to its advantage to load packages that are
    # statically compiled, linked, and declared in base applications.

    variable code_for_load_command_in_static_wrapped_app {
	rename load load_unsupported
	proc load {args} {
	    if {[string trim [lindex $args 0]] == {}} {
		eval load_unsupported $args
	    } else {
		error "\"load\" command is not supported in a statically \
			wrapped application; use \"load_unsupported\" command"
	    }
	}
    }


    # TclPro Wrapper looks in a pre-defined location for all library files
    # that contribute to a statically wrapped application.

    variable relTo [file dir [file dir [file dir [info nameofexec]]]]


    # TclPro Wrapper looks in a pre-defined location for all base-applications.

    variable inDir [file join [file dir [file dir [info nameofexec]]] lib]


    # Put all version specific wrap binary names here.  The .uses files
    # use these names to craft the base application names.

    variable WRAP_TCL		wraptclsh83
    variable WRAP_TK		wrapwish83
    variable WRAP_BIG_TCL	wrapbigtclsh83
    variable WRAP_BIG_TK	wrapbigwish83


    # The path below is the location where the "pkgIndex.tcl", for a
    # statically wrapped application, will exist.  This file will
    # contain all the code necessary for loading/initializing the
    # static packages that exist in a statically linked wrapped
    # application.

    variable staticPkgIndexFilePath \
	    [file join $::pro_wrapTempDirectory \
		    {lib/_staticPackage_/pkgIndex.tcl}]


    # 'library_files' is an array indexed by package name and holds
    # a list of files for the respective package.

    variable library_files

    # 'library_code' is an array indexed by package name and holds
    # package specific library initialization code to be wrapped.

    variable library_code

    # 'pkgIndex_script' is an array indexed by package name and holds
    # a fragment of code suitable to be placed in a "pkgIndex.tcl".

    variable pkgIndex_script


    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for Tcl.

    set library_files(tcl) {
	lib/tcl8.3/encoding/ascii.enc
	lib/tcl8.3/encoding/big5.enc
	lib/tcl8.3/encoding/cp1250.enc
	lib/tcl8.3/encoding/cp1251.enc
	lib/tcl8.3/encoding/cp1252.enc
	lib/tcl8.3/encoding/cp1253.enc
	lib/tcl8.3/encoding/cp1254.enc
	lib/tcl8.3/encoding/cp1255.enc
	lib/tcl8.3/encoding/cp1256.enc
	lib/tcl8.3/encoding/cp1257.enc
	lib/tcl8.3/encoding/cp1258.enc
	lib/tcl8.3/encoding/cp437.enc
	lib/tcl8.3/encoding/cp737.enc
	lib/tcl8.3/encoding/cp775.enc
	lib/tcl8.3/encoding/cp850.enc
	lib/tcl8.3/encoding/cp852.enc
	lib/tcl8.3/encoding/cp855.enc
	lib/tcl8.3/encoding/cp857.enc
	lib/tcl8.3/encoding/cp860.enc
	lib/tcl8.3/encoding/cp861.enc
	lib/tcl8.3/encoding/cp862.enc
	lib/tcl8.3/encoding/cp863.enc
	lib/tcl8.3/encoding/cp864.enc
	lib/tcl8.3/encoding/cp865.enc
	lib/tcl8.3/encoding/cp866.enc
	lib/tcl8.3/encoding/cp869.enc
	lib/tcl8.3/encoding/cp874.enc
	lib/tcl8.3/encoding/cp932.enc
	lib/tcl8.3/encoding/cp936.enc
	lib/tcl8.3/encoding/cp949.enc
	lib/tcl8.3/encoding/cp950.enc
	lib/tcl8.3/encoding/dingbats.enc
	lib/tcl8.3/encoding/euc-cn.enc
	lib/tcl8.3/encoding/euc-jp.enc
	lib/tcl8.3/encoding/euc-kr.enc
	lib/tcl8.3/encoding/gb12345.enc
	lib/tcl8.3/encoding/gb1988.enc
	lib/tcl8.3/encoding/gb2312.enc
	lib/tcl8.3/encoding/iso2022-jp.enc
	lib/tcl8.3/encoding/iso2022-kr.enc
	lib/tcl8.3/encoding/iso2022.enc
	lib/tcl8.3/encoding/iso8859-1.enc
	lib/tcl8.3/encoding/iso8859-2.enc
	lib/tcl8.3/encoding/iso8859-3.enc
	lib/tcl8.3/encoding/iso8859-4.enc
	lib/tcl8.3/encoding/iso8859-5.enc
	lib/tcl8.3/encoding/iso8859-6.enc
	lib/tcl8.3/encoding/iso8859-7.enc
	lib/tcl8.3/encoding/iso8859-8.enc
	lib/tcl8.3/encoding/iso8859-9.enc
	lib/tcl8.3/encoding/jis0201.enc
	lib/tcl8.3/encoding/jis0208.enc
	lib/tcl8.3/encoding/jis0212.enc
	lib/tcl8.3/encoding/koi8-r.enc
	lib/tcl8.3/encoding/ksc5601.enc
	lib/tcl8.3/encoding/macCentEuro.enc
	lib/tcl8.3/encoding/macCroatian.enc
	lib/tcl8.3/encoding/macCyrillic.enc
	lib/tcl8.3/encoding/macDingbats.enc
	lib/tcl8.3/encoding/macGreek.enc
	lib/tcl8.3/encoding/macIceland.enc
	lib/tcl8.3/encoding/macJapan.enc
	lib/tcl8.3/encoding/macRoman.enc
	lib/tcl8.3/encoding/macRomania.enc
	lib/tcl8.3/encoding/macThai.enc
	lib/tcl8.3/encoding/macTurkish.enc
	lib/tcl8.3/encoding/macUkraine.enc
	lib/tcl8.3/encoding/shiftjis.enc
	lib/tcl8.3/encoding/symbol.enc
	lib/tcl8.3/http2.3/http.tcl
	lib/tcl8.3/http2.3/pkgIndex.tcl
	lib/tcl8.3/http1.0/http.tcl
	lib/tcl8.3/http1.0/pkgIndex.tcl
	lib/tcl8.3/msgcat1.0/msgcat.tcl
	lib/tcl8.3/msgcat1.0/pkgIndex.tcl
	lib/tcl8.3/auto.tcl
	lib/tcl8.3/history.tcl
	lib/tcl8.3/init.tcl
	lib/tcl8.3/ldAout.tcl
	lib/tcl8.3/package.tcl
	lib/tcl8.3/parray.tcl
	lib/tcl8.3/safe.tcl
	lib/tcl8.3/word.tcl
	lib/tcl8.3/tclIndex
    }

    set library_code(tcl) {
	set tcl_library {lib/tcl8.3}
    }
    set pkgIndex_script(tcl) {
	# Nothing to add to pkgIndex.tcl.
    }


    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for Tk.

    set library_files(tk) {
	lib/tk8.3/bgerror.tcl
	lib/tk8.3/button.tcl
	lib/tk8.3/clrpick.tcl
	lib/tk8.3/comdlg.tcl
	lib/tk8.3/console.tcl
	lib/tk8.3/dialog.tcl
	lib/tk8.3/entry.tcl
	lib/tk8.3/focus.tcl
	lib/tk8.3/listbox.tcl
	lib/tk8.3/menu.tcl
	lib/tk8.3/msgbox.tcl
	lib/tk8.3/obsolete.tcl
	lib/tk8.3/optMenu.tcl
	lib/tk8.3/palette.tcl
	lib/tk8.3/safetk.tcl
	lib/tk8.3/scale.tcl
	lib/tk8.3/scrlbar.tcl
	lib/tk8.3/tearoff.tcl
	lib/tk8.3/text.tcl
	lib/tk8.3/tk.tcl
	lib/tk8.3/tkfbox.tcl
	lib/tk8.3/xmfbox.tcl
	lib/tk8.3/tclIndex
	lib/tk8.3/prolog.ps
    }
    set library_code(tk) {
	set tk_library {lib/tk8.3}
    }
    set pkgIndex_script(tk) {
	# Nothing to add to pkgIndex.tcl.
    }


    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for [incr Tcl].

    set library_files(itcl) {
  	lib/itcl3.2/itcl.tcl
    }
    set library_code(itcl) {
    }
    set pkgIndex_script(itcl) {
  	prowrapUses::appendWrappedFile $prowrapUses::staticPkgIndexFilePath {
  	    package ifneeded Itcl 3.2 {
  		namespace eval ::itcl {variable library {lib/itcl3.2}}
  		load {} Itcl
  	    }
  	}
    }


    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for [incr Tk].
    
    set library_files(itk) {
	lib/itk3.2/itk.tcl
  	lib/itk3.2/Widget.itk
  	lib/itk3.2/Archetype.itk
  	lib/itk3.2/Toplevel.itk
  	lib/itk3.2/tclIndex

  	lib/iwidgets2.2.0/pkgIndex.tcl
  	lib/iwidgets2.2.0/iwidgets.tcl
  	lib/iwidgets2.2.0/scripts/buttonbox.itk
  	lib/iwidgets2.2.0/scripts/colors.itk
  	lib/iwidgets2.2.0/scripts/messagedialog.itk
  	lib/iwidgets2.2.0/scripts/canvasprintbox.itk
  	lib/iwidgets2.2.0/scripts/canvasprintdialog.itk
  	lib/iwidgets2.2.0/scripts/combobox.itk
  	lib/iwidgets2.2.0/scripts/dialog.itk
  	lib/iwidgets2.2.0/scripts/feedback.itk
  	lib/iwidgets2.2.0/scripts/dialogshell.itk
  	lib/iwidgets2.2.0/scripts/entryfield.itk
  	lib/iwidgets2.2.0/scripts/hyperhelp.itk
  	lib/iwidgets2.2.0/scripts/fileselectionbox.itk
  	lib/iwidgets2.2.0/scripts/menubar.itk
  	lib/iwidgets2.2.0/scripts/fileselectiondialog.itk
  	lib/iwidgets2.2.0/scripts/labeledwidget.itk
  	lib/iwidgets2.2.0/scripts/notebook.itk
  	lib/iwidgets2.2.0/scripts/pane.itk
  	lib/iwidgets2.2.0/scripts/optionmenu.itk
  	lib/iwidgets2.2.0/scripts/shell.itk
  	lib/iwidgets2.2.0/scripts/panedwindow.itk
  	lib/iwidgets2.2.0/scripts/promptdialog.itk
  	lib/iwidgets2.2.0/scripts/pushbutton.itk
  	lib/iwidgets2.2.0/scripts/radiobox.itk
  	lib/iwidgets2.2.0/scripts/scrolledframe.itk
  	lib/iwidgets2.2.0/scripts/scrolledcanvas.itk
  	lib/iwidgets2.2.0/scripts/scrolledhtml.itk
  	lib/iwidgets2.2.0/scripts/scrolledtext.itk
  	lib/iwidgets2.2.0/scripts/scrolledlistbox.itk
  	lib/iwidgets2.2.0/scripts/selectionbox.itk
  	lib/iwidgets2.2.0/scripts/selectiondialog.itk
  	lib/iwidgets2.2.0/scripts/spindate.itk
  	lib/iwidgets2.2.0/scripts/spinint.itk
  	lib/iwidgets2.2.0/scripts/spinner.itk
  	lib/iwidgets2.2.0/scripts/spintime.itk
  	lib/iwidgets2.2.0/scripts/tabnotebook.itk
  	lib/iwidgets2.2.0/scripts/tabset.itk
  	lib/iwidgets2.2.0/scripts/toolbar.itk
  	lib/iwidgets2.2.0/scripts/tclIndex
  	lib/iwidgets2.2.0/scripts/unknownimage.gif

  	lib/iwidgets3.0.0/pkgIndex.tcl
  	lib/iwidgets3.0.0/iwidgets.tcl
  	lib/iwidgets3.0.0/scripts/buttonbox.itk
  	lib/iwidgets3.0.0/scripts/calendar.itk
  	lib/iwidgets3.0.0/scripts/checkbox.itk
  	lib/iwidgets3.0.0/scripts/canvasprintbox.itk
  	lib/iwidgets3.0.0/scripts/canvasprintdialog.itk
  	lib/iwidgets3.0.0/scripts/combobox.itk
  	lib/iwidgets3.0.0/scripts/dateentry.itk
  	lib/iwidgets3.0.0/scripts/datefield.itk
  	lib/iwidgets3.0.0/scripts/dialog.itk
  	lib/iwidgets3.0.0/scripts/dialogshell.itk
  	lib/iwidgets3.0.0/scripts/entryfield.itk
  	lib/iwidgets3.0.0/scripts/disjointlistbox.itk
  	lib/iwidgets3.0.0/scripts/feedback.itk
  	lib/iwidgets3.0.0/scripts/extfileselectiondialog.itk
  	lib/iwidgets3.0.0/scripts/extfileselectionbox.itk
  	lib/iwidgets3.0.0/scripts/finddialog.itk
  	lib/iwidgets3.0.0/scripts/hierarchy.itk
  	lib/iwidgets3.0.0/scripts/fileselectionbox.itk
  	lib/iwidgets3.0.0/scripts/hyperhelp.itk
  	lib/iwidgets3.0.0/scripts/fileselectiondialog.itk
  	lib/iwidgets3.0.0/scripts/labeledframe.itk
  	lib/iwidgets3.0.0/scripts/labeledwidget.itk
  	lib/iwidgets3.0.0/scripts/mainwindow.itk
  	lib/iwidgets3.0.0/scripts/menubar.itk
  	lib/iwidgets3.0.0/scripts/messagebox.itk
  	lib/iwidgets3.0.0/scripts/messagedialog.itk
  	lib/iwidgets3.0.0/scripts/notebook.itk
  	lib/iwidgets3.0.0/scripts/optionmenu.itk
  	lib/iwidgets3.0.0/scripts/pane.itk
  	lib/iwidgets3.0.0/scripts/panedwindow.itk
  	lib/iwidgets3.0.0/scripts/promptdialog.itk
  	lib/iwidgets3.0.0/scripts/pushbutton.itk
  	lib/iwidgets3.0.0/scripts/radiobox.itk
  	lib/iwidgets3.0.0/scripts/regexpfield.itk
  	lib/iwidgets3.0.0/scripts/scrolledframe.itk
  	lib/iwidgets3.0.0/scripts/scrolledhtml.itk
  	lib/iwidgets3.0.0/scripts/scrolledcanvas.itk
  	lib/iwidgets3.0.0/scripts/scrolledtext.itk
  	lib/iwidgets3.0.0/scripts/scrolledwidget.itk
  	lib/iwidgets3.0.0/scripts/scrolledlistbox.itk
  	lib/iwidgets3.0.0/scripts/selectionbox.itk
  	lib/iwidgets3.0.0/scripts/shell.itk
  	lib/iwidgets3.0.0/scripts/spindate.itk
  	lib/iwidgets3.0.0/scripts/selectiondialog.itk
  	lib/iwidgets3.0.0/scripts/spinint.itk
  	lib/iwidgets3.0.0/scripts/spinner.itk
  	lib/iwidgets3.0.0/scripts/spintime.itk
  	lib/iwidgets3.0.0/scripts/tabnotebook.itk
  	lib/iwidgets3.0.0/scripts/tabset.itk
  	lib/iwidgets3.0.0/scripts/timeentry.itk
  	lib/iwidgets3.0.0/scripts/timefield.itk
  	lib/iwidgets3.0.0/scripts/toolbar.itk
  	lib/iwidgets3.0.0/scripts/watch.itk
  	lib/iwidgets3.0.0/scripts/colors.itcl
  	lib/iwidgets3.0.0/scripts/roman.itcl
  	lib/iwidgets3.0.0/scripts/scopedobject.tcl
  	lib/iwidgets3.0.0/scripts/scopedobject.itcl
  	lib/iwidgets3.0.0/scripts/tclIndex
  	lib/iwidgets3.0.0/scripts/unknownimage.gif
    }
    set library_code(itk) {
    }
    set pkgIndex_script(itk) {
  	prowrapUses::appendWrappedFile $prowrapUses::staticPkgIndexFilePath {
  	    package ifneeded Itk 3.2 {
  		namespace eval ::itk {variable library {lib/itk3.2}}
  		load {} Itk
  	    }
  	}
    }
    
    
    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for Expect.

    set library_files(expect) {
    }
    set library_code(expect) {
    }
    set pkgIndex_script(expect) {
  	prowrapUses::appendWrappedFile $prowrapUses::staticPkgIndexFilePath {
  	    if {$tcl_platform(platform) == "unix"} {
  		set expect_library {}
  		set exp_library {}
  		set exp_exec_library {}
  		package ifneeded Expect 5.31 {
  		    load {} Expect
  		}
  	    }
  	}
    }


    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for Tclx.

    set library_files(tclx) {
	lib/tclX8.3/autoload.tcl
	lib/tclX8.3/buildidx.tcl
	lib/tclX8.3/tcl.tlib
	lib/tclX8.3/tcl.tndx
	lib/tclX8.3/tclx.tcl
    }
    set library_code(tclx) {
    }
    set pkgIndex_script(tclx) {
  	prowrapUses::appendWrappedFile $prowrapUses::staticPkgIndexFilePath {
  	    package ifneeded Tclx 8.3 {
  		set tclx_library {lib/tclX8.3}
  		load {} Tclx
  		foreach __cmd {
  		    abs acos apropos asin assign_fields atan atan2
  		    auto_commands auto_load_file auto_packages buildhelp
  		    ceil cexpand convert_lib convertclock copyfile cos cosh
  		    dirs double edprocs exp fabs floor fmod fmtclock
  		    for_array_keys for_file for_recursive_glob frename
  		    etclock help helpcd helppwd int intersect intersect3
  		    log log10 lrmdups mainloop mkdir popd pow profrep pushd
  		    read_file recursive_glob rmdir round saveprocs searchpath
  		    server_cntl server_connect server_info server_open
  		    server_send showproc sin sinh sqrt tan tanh union unlink
  		    write_file
  		} {
  		    set auto_index($__cmd) {
  			source [file join $tclx_library tcl.tlib]
  		    }
  		}
  		unset __cmd
  	    }
  	}
    }


    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for Tkx.
    
    set library_files(tkx) {
	lib/tkX8.3/tkx.tcl
    }
    set library_code(tkx) {
    }
    set pkgIndex_script(tkx) {
	prowrapUses::appendWrappedFile $prowrapUses::staticPkgIndexFilePath {
	    package ifneeded Tkx 8.3 {
		set tkx_library {lib/tkX8.3}
		load {} Tkx
	    }
	}
    }
}


# prowrapUses::appendWrappedFile --
#
#	This routine writes a temporary file given by the fully qualified
#	path 'filePath'.  The appended data is the value of the script
#	literal.
#
# Arguments
#	filePath	the path name of the create file
#	scriptLiteral	the actual contents of the created file
#
# Results
#	Nothing.  The parent directory of the file will be created if it
#	doesn't already exist.  The file will be appended to (created) if
#	it exists (doesn't exist).

proc prowrapUses::appendWrappedFile {filePath scriptLiteral} {
    file mkdir [file dir $filePath]
    set f [open $filePath "a"]
    puts $f $scriptLiteral
    close $f
}


# prowrapUses::prependRelTo --
#
#	This routine returns a modified list with each element of the given
#	list prepended with the first argument.
#
# Arguments
#	relTo		the directory part that should be "pre-pended"
#	libList		a list of files that need pre-pending
#
# Results
#	A list that has each of the original file elements prepended with the
#	'relTo' argument.

proc prowrapUses::prependRelTo {relTo libList} {
    set ret {}
    foreach lib $libList {
	lappend ret [file join $relTo $lib]
    }
    return $ret
}


# prowrapUses::buildCommandLine --
#
#	This routine returns builds a complete command line for the given
#	packages in 'args'.
#
# Arguments
#	baseApp		name of base application for complete package list
#	args		a list of known static package names supported by
#			TclPro Wrapper
#
# Results
#	A list that represents new command line flags and file names that
#	is used by TclPro Wrapper.

proc prowrapUses::buildCommandLine {baseApp args} {
    set commandLine {}

    lappend commandLine \
	    -executable $baseApp \
	    -code $prowrapUses::code_for_load_command_in_static_wrapped_app

    foreach pkg $args {
	eval $prowrapUses::pkgIndex_script($pkg)

	lappend commandLine \
		-code $prowrapUses::library_code($pkg)

	lappend commandLine \
		-relativeto $prowrapUses::relTo
	set commandLine [concat $commandLine \
		[prowrapUses::prependRelTo \
			$prowrapUses::relTo \
			$prowrapUses::library_files($pkg)]]
    }

    if {[file exists [file join $prowrapUses::staticPkgIndexFilePath]]} {
	lappend commandLine \
		-relativeto $::pro_wrapTempDirectory \
			[file join $::pro_wrapTempDirectory \
		    	    	   $prowrapUses::staticPkgIndexFilePath]
    }

    return $commandLine
}

