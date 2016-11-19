# gui.tcl --
#
#	This file contains procedures for implementing the graphical
#	interface to the build environment.
#
# Copyright (c) 1998-2000 by Ajuba Solutions
# See the file license.terms.
#
# RCS: @(#) $Id: gui.tcl,v 1.15 2000/10/31 23:30:46 welch Exp $

package require BWidget
package require ModuleOps
package provide buildenvGui 1.0

option add *text.background white

namespace eval ::gui {
    # Array containing a list of useful widgets
    variable window

    array set window {
	textOutput {}
	moduleListbox {}
	fileMenu {}
	moduleTree {}
	moduleSelect {}
    }

    # Array containing the list of images used for buttons

    variable image

    set imageDir [file join [file dirname [info script]] images]
    set image(new) [image create photo -file [file join $imageDir new.gif]]
    set image(open) [image create photo -file [file join $imageDir open.gif]]
    set image(save) [image create photo -file [file join $imageDir save.gif]]
    set image(module) [image create photo -file \
	    [file join $imageDir module.gif]]

    # This variable is used for waiting on dialogs.
    variable waitVar

    # This variable is used for gui globals
    variable parms

    array set parms {
	buildFlavor Debug
	lastDir	{}
    }
}

# ::gui::create --
#
#	This routine builds all of the main interface.
#
# Arguments:
#	None.
#
# Side Effects:
#	A new window will appear on the screen.
#
# Results:
#	None.

proc ::gui::create {} {
    toplevel .buildFrame
    wm title .buildFrame "Build Project"
    frame .buildFrame.menubar -borderwidth 2 -relief raised
    frame .buildFrame.toolbar
    frame .buildFrame.actionbar -borderwidth 1 -relief ridge
    frame .buildFrame.settings -borderwidth 1 -relief ridge
    frame .buildFrame.modules
    frame .buildFrame.modulesel
    frame .buildFrame.output

    ::gui::CreateMenubar .buildFrame.menubar
    ::gui::CreateToolbar .buildFrame.toolbar
    ::gui::CreateActionbar .buildFrame.actionbar
    ::gui::CreateSettings .buildFrame.settings

    # TEMPORARY:  hack to toggle the module listing widget type.  The
    # command line argument "-tree" turns on the tree widget.

    global use_tree
    if {$use_tree} {
	::gui::CreateTreeModulearea .buildFrame.modules
    } else {
	::gui::CreateModulelist .buildFrame.modules
    }
    ::gui::CreateOutput .buildFrame.output

    grid .buildFrame.menubar -row 0 -column 0 -sticky we -columnspan 2
    grid .buildFrame.toolbar -row 1 -column 0 -sticky w -columnspan 2
    grid .buildFrame.actionbar -row 2 -column 0 -sticky we -columnspan 2
    grid .buildFrame.settings -row 3 -column 0 -sticky we -columnspan 2
    grid .buildFrame.modules -row 4 -column 0 -sticky news
    grid .buildFrame.output -row 4 -column 1 -sticky news
    grid rowconfigure .buildFrame 4 -weight 1
    grid columnconfigure .buildFrame 0 -weight 1

    return
}

# ::gui::CreateMenubar --
#
#	Create a menubar for the main interface.
#
# Arguments:
#	parent		Name of frame containing this widget set.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::CreateMenubar {parent} {
    variable window

    menubutton $parent.file -text File -menu $parent.file.menu
    menu $parent.file.menu -tearoff 0
    set window(fileMenu) $parent.file.menu
    $parent.file.menu add command -label New... \
	    -command ::gui::newProject
    $parent.file.menu add command -label Open \
	    -command ::gui::openProject
    $parent.file.menu add command -label Save \
	    -command ::gui::saveProject \
	    -state disabled
    $parent.file.menu add command -label "Save As..." \
	    -command "::gui::saveProject 1" \
	    -state disabled
    $parent.file.menu add command -label Close \
	    -command ::gui::closeProject \
	    -state disabled
    $parent.file.menu add separator
    $parent.file.menu add command -label "Save Output..." \
	    -command ::gui::saveOutput
    $parent.file.menu add command -label Exit -command exit

    grid $parent.file -row 0 -col 0 -sticky w
    grid columnconfigure $parent 0 -weight 1

    return
}

# ::gui::CreateToolbar --
#
#	Create a toolbar for the main interface.
#
# Arguments:
#	parent		Name of frame containing this widget set.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::CreateToolbar {parent} {
    variable image

    button $parent.new -image $image(new) -relief flat \
	    -command "::gui::newProject"
    button $parent.open -image $image(open) -relief flat \
	    -command "::gui::openProject"
    button $parent.save -image $image(save) -relief flat \
	    -command "::gui::saveProject"
    button $parent.build -text B -relief flat \
	    -command "::gui::runBuild"
    button $parent.savelog -image $image(new) -relief flat \
	    -command "::gui::unimplemented"
    button $parent.init -text I -relief flat \
	    -command "::gui::initProject"
    button $parent.sync -text L -relief flat \
	    -command "::gui::UpdateModulelist" \
	    -state disabled

    grid $parent.new -row 0 -column 0 -sticky w
    grid $parent.open -row 0 -column 1 -sticky w
    grid $parent.save -row 0 -column 2 -sticky w
    grid $parent.build -row 0 -column 3 -sticky w
    grid $parent.savelog -row 0 -column 4 -sticky w
    grid $parent.init -row 0 -column 5 -sticky w
    grid $parent.sync -row 0 -column 6 -sticky w

    return
}

# ::gui::CreateActionbar --
#
#	Create a set of action selecting buttons for the main interface.
#
# Arguments:
#	parent		Name of frame containing this widget set.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::CreateActionbar {parent} {
    label $parent.label -text "Select Action:"
    checkbutton $parent.hose -text Hose \
	    -variable ::ModuleOps::buildAction(hose)
    checkbutton $parent.update -text "Update Source" \
	    -variable ::ModuleOps::buildAction(update)
    checkbutton $parent.build -text Build \
	    -variable ::ModuleOps::buildAction(install)
    checkbutton $parent.test -text Test \
	    -variable ::ModuleOps::buildAction(test)

    grid $parent.label -row 0 -column 0 -sticky w
    grid $parent.hose -row 0 -column 1 -sticky w
    grid $parent.update -row 0 -column 2 -sticky w
    grid $parent.build -row 0 -column 3 -sticky w
    grid $parent.test -row 0 -column 4 -sticky w

    grid columnconfigure $parent 0 -weight 1
    grid columnconfigure $parent 1 -weight 1
    grid columnconfigure $parent 2 -weight 1
    grid columnconfigure $parent 3 -weight 1
    grid columnconfigure $parent 4 -weight 1
    grid rowconfigure $parent 0 -pad 10

    return
}

# ::gui::CreateSettings --
#
#	Create an area in the GUI for showing the current project settings.
#
# Arguments:
#	parent		Frame in which this gui will be created.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::CreateSettings {parent} {
    label $parent.masterLabel -text "Master Directory:"
    label $parent.buildLabel -text "Build Directory:"
    label $parent.installLabel -text "Install Directory:"
    label $parent.flavorLabel -text "Build Flavor:"
    label $parent.moduleLabel -text "Selected Modules:"

    label $parent.masterVal -textvariable ::ModuleOps::masterDir
    label $parent.buildVal -textvariable ::ModuleOps::buildDir
    label $parent.installVal -textvariable ::ModuleOps::installDir
    label $parent.flavorVal -textvariable ::ModuleOps::buildFlavor
    label $parent.moduleVal -textvariable ::ModuleOps::activeModuleList \
	    -wraplength 600 -justify left

    grid $parent.masterLabel -row 0 -column 0 -sticky w
    grid $parent.buildLabel -row 1 -column 0 -sticky w
    grid $parent.installLabel -row 2 -column 0 -sticky w
    grid $parent.flavorLabel -row 3 -column 0 -sticky w
    grid $parent.moduleLabel -row 4 -column 0 -sticky w
    grid $parent.masterVal -row 0 -column 1 -sticky w
    grid $parent.buildVal -row 1 -column 1 -sticky w
    grid $parent.installVal -row 2 -column 1 -sticky w
    grid $parent.flavorVal -row 3 -column 1 -sticky w
    grid $parent.moduleVal -row 4 -column 1 -sticky w

    grid columnconfigure $parent 0 -weight 1
    grid columnconfigure $parent 1 -weight 1

    return
}

# ::gui::CreateModulelist --
#
#	Create an area in the GUI for displaying the list of available modules.
#
# Arguments:
#	parent		Frame in which this GUI will be created.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::CreateModulelist {parent} {
    variable window

    label $parent.label -text "Module Listing:"
    listbox $parent.modList -listvariable ::ModuleOps::moduleList \
	    -selectmode extended -yscrollcommand "$parent.vsb set"
    scrollbar $parent.vsb -orient vertical -command "$parent.modList yview"
    set window(moduleListbox) $parent.modList

    grid $parent.label -row 0 -column 0 -columnspan 2 -sticky we
    grid $parent.modList -row 1 -column 0 -sticky nwes
    grid $parent.vsb -row 1 -column 1 -sticky ns
    grid rowconfigure $parent 1 -weight 1
    grid columnconfigure $parent 0 -weight 1

    # Take action whenever the listbox selection is changed.

    bind $parent.modList <<ListboxSelect>> {
	::gui::updateActiveModules
    }

    return
}

# ::gui::CreateTreeModulearea --
#
#	Creates an area in the interface for dragging and dropping modules
#	as a way of selecting them.
#
# Arguments:
#	parent		Name of frame containing this widget area.
#
# Side Effects:
#	New widgets will be created and mapped.
#
# Results:
#	None.

proc ::gui::CreateTreeModulearea {parent} {
    frame $parent.lefttree
    frame $parent.righttree

    ::gui::CreateTreeModulelist $parent.lefttree
    ::gui::CreateTreeModuleselection $parent.righttree

    grid $parent.lefttree -row 0 -column 0 -sticky news
    grid $parent.righttree -row 0 -column 1 -sticky news
    grid columnconfigure $parent 0 -weight 1
    grid columnconfigure $parent 1 -weight 1
    grid rowconfigure $parent 0 -weight 1

    return
}

# ::gui::CreateTreeModulelist --
#
#	Create an area in the GUI for displaying the list of available modules.
#
# Arguments:
#	parent		Frame in which this GUI will be created.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::CreateTreeModulelist {parent} {
    variable window

    Tree $parent.tree -yscrollcommand "$parent.vsb set" \
	    -dragenabled 1
    set window(moduleTree) $parent.tree
    scrollbar $parent.vsb -orient vertical -command "$parent.tree yview"

    grid $parent.tree -row 0 -column 0 -sticky news
    grid $parent.vsb -row 0 -column 1 -sticky ns
    grid columnconfigure $parent 0 -weight 1
    grid rowconfigure $parent 0 -weight 1

    return
}

# ::gui::CreateTreeModuleselection --
#
#	Create an area in the GUI for displaying the list of selected modules.
#
# Arguments:
#	parent		Frame in which this GUI will be created.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::CreateTreeModuleselection {parent} {
    variable window

    Tree $parent.tree -yscrollcommand "$parent.vsb set" \
	    -dropenabled 1 -dropcmd ::gui::DropModule \
	    -dropovermode n -takefocus 1
    set window(moduleSelect) $parent.tree
    scrollbar $parent.vsb -orient vertical -command "$parent.tree yview"
    menu $parent.tree.nodemenu -tearoff 0
    $parent.tree.nodemenu add command \
	    -command ::gui::unimplemented \
	    -label "Show nodeid" \
	    -state disabled
    $parent.tree.nodemenu add command \
	    -command ::gui::DeleteModuleSel \
	    -label "Remove Module"
    $parent.tree.nodemenu add command \
	    -command ::gui::unimplemented \
	    -label "Add Dependencies"
    $parent.tree.nodemenu add command \
	    -command ::gui::unimplemented \
	    -label "Show Dependencies"
    menu $parent.tree.rootmenu -tearoff 0
    $parent.tree.rootmenu add command \
	    -command "::gui::DeleteModuleSel $parent.tree Build" \
	    -label "Remove all modules"
    $parent.tree.rootmenu add command \
	    -command "::gui::SortModuleList $parent.tree" \
	    -label "Sort modules"

    bind $window(moduleSelect) <Delete> \
	    "::gui::DeleteModuleSel $window(moduleSelect)"
    $window(moduleSelect) bindText <Button-3> \
	    "::gui::ShowTreePopup $window(moduleSelect) %X %Y"

    focus $window(moduleSelect)

    grid $parent.tree -row 0 -column 0 -sticky news
    grid $parent.vsb -row 0 -column 1 -sticky ns
    grid columnconfigure $parent 0 -weight 1
    grid rowconfigure $parent 0 -weight 1

    return
}

# ::gui::ShowTreePopup --
#
#	Display a pop-up menu to take action on a specific tree node.
#
# Arguments:
#	tree	Tree widget containing the node to act upon.
#	x	X position of event.
#	y	Y position of event.
#	node	Node to act upon.
#
# Side Effects:
#	The node may be altered in some way, depending on the menu
#	entry selected.
#
# Results:
#	None.

proc ::gui::ShowTreePopup {tree x y node} {
    switch -exact $node {
	Build {
	    tk_popup $tree.rootmenu $x $y
	}
	default {
	    $tree.nodemenu entryconfigure 0 \
		    -label "$node"
	    $tree.nodemenu entryconfigure 1 \
		    -command "::gui::DeleteModuleSel $tree $node"
	    $tree.nodemenu entryconfigure 2 \
		    -command "::gui::ExpandModuleSel add $tree $node"
	    $tree.nodemenu entryconfigure 3 \
		    -command "::gui::ExpandModuleSel show $tree $node"
	    tk_popup $tree.nodemenu $x $y
	}
    }

    return
}

# ::gui::DeleteModuleSel --
#
#	Deletes a node in the specified tree.
#
# Arguments:
#	tree	Path to tree widget containing the node.
#	node	Name of node to delete.
#
# Side Effects:
#	The given node will be deleted from the tree.
#
# Results:
#	None.

proc ::gui::DeleteModuleSel {tree node} {
    if {![string equal $node Build]} {
	$tree delete $node
    } else {
	$tree delete [$tree nodes Build]
    }
    GetModuleList

    return
}

# ::gui::ExpandModuleSel --
#
#	Expands a module and acts upon the children.  The children may be
#	either added or shown.
#
# Arguments:
#	action		One of "show" or "add"
#	tree		Pathname of tree in use.
#	node		Name of node that was chosen.
#
# Side Effects:
#	New nodes may be added to the tree, and the list of modules to build
#	may get updated.
#
# Results:
#	None.

proc ::gui::ExpandModuleSel {action tree node} {
    if {![string equal $node Build]} {
	switch -exact $action {
	    add {
		set modList [::ModuleHints::getCanonicalDependencies $node {} \
			"::gui::addModuleDep $tree"]
	    }
	    show {
		$tree delete [$tree nodes $node]
		$tree opentree $node
		set modList [::ModuleHints::getCanonicalDependencies $node {} \
			"::gui::showModuleDep $tree"]
	    }
	    default {
		::ModuleHints::logError "Action '$action' not supported\
			by [info level 0]"
	    }
	}
    }

    return
}

# ::gui::addModuleDep --
#
#	Add the dependents of a module to the top level of the tree.
#
# Arguments:
#	tree	Name of tree in use.
#	node	Name of node whose children are being added.
#	prefix	unused
#	args	List of nodes to add at the same level as "node"
#
# Side Effects:
#	New nodes are added to the tree.
#
# Results:
#	None.

proc ::gui::addModuleDep {tree node prefix args} {
    variable image

    foreach subnode $args {
	if {![$tree exists $subnode]} {
	    $tree insert [$tree index $node] Build $subnode -image $image(module) -text $subnode
	}
    }

    GetModuleList

    return
}

# ::gui::showModuleDep --
#
#	Show the dependency tree for a module.
#
# Arguments:
#	tree	Name of tree in use.
#	node	Name of node whose children are being added.
#	prefix	dotted path describing position of node in tree.  This is used
#		to generate a unique node name.
#	args	List of nodes to add under "node"
#
# Side Effects:
#	New nodes are added to the tree.
#
# Results:
#	None.

proc ::gui::showModuleDep {tree node prefix args} {
    variable image

    foreach subnode $args {
	$tree insert end $prefix $prefix.$subnode \
		-image $image(module) \
		-fill #797979 \
		-text $subnode
    }

    return
}

# ::gui::DropModule --
#
#	This routine is called when a drop event is detected on the
#	Module selection tree widget.
#
# Arguments:
#	widget		Pathname of the tree
#	src		Pathname of the drag source
#	dropSite	List describing the drop site.  See the BWidget
#			help docs for more info.
#	op		Current operation
#	type		Data type
#	clientData	Drop item data
#
# Side Effects:
#	|>args<|
#
# Results:
#	|>args<|

proc ::gui::DropModule {widget src dropSite op type clientData} {
    variable image
    variable window

    set dropNode [lindex $dropSite 1]

    # clientData may be a qualified name, such as "tk.tcl".  Strip off
    # the qualifying part of the name.

    regsub {.*\.} $clientData {} clientData

    if {![$widget exists $clientData]} {
	if {[string equal $dropNode Build]} {
	    set dropIndex 0
	} else {
	    set dropIndex [expr [$widget index $dropNode]+1]
	}
	$widget insert $dropIndex Build $clientData \
		-text $clientData \
		-image $image(module)

	GetModuleList
    }
    $widget itemconfigure  Build -open 1

    focus $window(moduleSelect)

    return
}

# ::gui::CreateOutput --
#
#	Create an area in the GUI for displaying processing output.
#
# Arguments:
#	parent		Name of the parent frame containing this GUI.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::CreateOutput {parent} {
    variable window

    label $parent.label -text "Output:"
    text $parent.text \
	    -xscrollcommand "$parent.hsb set" \
	    -yscrollcommand "$parent.vsb set"
    menu $parent.text.menu -tearoff 0
    $parent.text.menu add command -label "Save Log" \
	    -command ::gui::saveOutput
    $parent.text.menu add command -label "Clear Log" \
	    -command ::gui::clearOutput
    bind $parent.text <Button-3> "tk_popup $parent.text.menu %X %Y"
    set window(textOutput) $parent.text
    scrollbar $parent.vsb -orient vertical -command "$parent.text yview"
    scrollbar $parent.hsb -orient horizontal -command "$parent.text xview"

    # Error messages are highlighted so that they stand out.

    $parent.text tag configure error -foreground red

    grid $parent.label -row 0 -column 0 -columnspan 2 -sticky we
    grid $parent.text -row 1 -column 0 -sticky news
    grid $parent.vsb -row 1 -column 1 -sticky ns
    grid $parent.hsb -row 2 -column 0 -sticky we

    grid columnconfigure $parent 0 -weight 1
    grid rowconfigure $parent 1 -weight 1

    return
}

# ::gui::UpdateModulelist --
#
#	Update the contents of the module listbox to reflect the currently
#	available modules.
#
# Arguments:
#	None.
#
# Side Effects:
#	Contents of listbox will be updated.
#
# Results:
#	None.

proc ::gui::UpdateModulelist {} {
    variable window
    variable image

    $window(moduleTree) delete
    $window(moduleTree) insert end root Project -text "Project Modules" \
	    -image $image(module)
    $window(moduleTree) opentree Project
    foreach mod [::ModuleHints::getModuleListing] {
	$window(moduleTree) insert end Project $mod -text $mod \
		-image $image(module)
	::gui::showModuleDep $window(moduleTree) $mod {}
	::ModuleHints::getCanonicalDependencies $mod {} \
			"::gui::showModuleDep $window(moduleTree)"
	update idletasks
    }
    $window(moduleSelect) delete
    $window(moduleSelect) insert end root Build -text "Build Modules" \
	    -image $image(module)

    return
}

# ::gui::GetModuleList --
#
#	Generate a list of modules to build based on the contents of the
#	Build Tree widget.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	Returns a list of modules to be built.

proc ::gui::GetModuleList {} {
    variable window

    set ::ModuleOps::activeModuleList [lsort -unique \
	    -command ::ModuleOps::CompareModuledep \
	    [$window(moduleSelect) nodes Build]]

    return $::ModuleOps::activeModuleList
}

# ::gui::SortModuleList --
#
#	Sort the modules in the tree based on their position in the
#	depency list.
#
# Arguments:
#	tree	Tree whose contents will be sorted.
#
# Side Effects:
#	Order of modules in tree will be changed.
#
# Results:
#	Returns the list of modules in sorted order.

proc ::gui::SortModuleList {tree} {
    set moduleList [lsort -unique -command ::ModuleOps::CompareModuledep \
	    [$tree nodes Build]]

    $tree reorder Build $moduleList

    return $moduleList
}

# ::gui::newProject --
#
#	Initialize a new project with information provided by the user.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::newProject {} {
    variable window

    set top [toplevel .newProject]

    set parent [frame $top.master]

    label $parent.masterLabel -text "Master Directory"
    entry $parent.masterEntry
    $parent.masterEntry delete 0 end
    $parent.masterEntry insert end $::ModuleOps::masterDir
    button $parent.masterFilebutton -text "Choose..." \
	    -command [list ::gui::ChooseDir $parent.masterEntry \
	    "Select Master Directory"]

    label $parent.buildLabel -text "Build Directory"
    entry $parent.buildEntry
    $parent.buildEntry delete 0 end
    $parent.buildEntry insert end $::ModuleOps::buildDir
    button $parent.buildFilebutton -text "Choose..." \
	    -command [list ::gui::ChooseDir $parent.buildEntry \
	    "Select Build Directory"]

    label $parent.installLabel -text "Install Directory"
    entry $parent.installEntry
    $parent.installEntry delete 0 end
    $parent.installEntry insert end $::ModuleOps::installDir
    button $parent.installFilebutton -text "Choose..." \
	    -command [list ::gui::ChooseDir $parent.installEntry \
	    "Select Install Directory"]

    label $parent.buildFlavor -text "Build Flavor" 
    tk_optionMenu $parent.buildom parms(buildFlavor) Debug Release

    grid $parent.masterLabel -row 0 -column 0 -sticky w
    grid $parent.masterEntry -row 0 -column 1 -sticky we
    grid $parent.masterFilebutton -row 0 -column 2 -sticky e
    grid $parent.buildLabel -row 1 -column 0 -sticky w
    grid $parent.buildEntry -row 1 -column 1 -sticky we
    grid $parent.buildFilebutton -row 1 -column 2 -sticky e
    grid $parent.installLabel -row 2 -column 0 -sticky w
    grid $parent.installEntry -row 2 -column 1 -sticky we
    grid $parent.installFilebutton -row 2 -column 2 -sticky e
    grid $parent.buildFlavor -row 3 -column 0 -sticky w
    grid $parent.buildom -row 3 -column 1 -sticky w

    grid columnconfigure $parent 1 -weight 1

    frame $top.separator -borderwidth 2 -relief sunken

    set parent [frame $top.bbox]

    button $parent.ok -text Ok -command "set ::gui::waitVar ok"
    button $parent.cancel -text Cancel -command "set ::gui::waitVar cancel"

    grid $parent.ok -row 0 -column 0
    grid $parent.cancel -row 0 -column 1
    grid rowconfigure $parent 0 -pad 10
    grid columnconfigure $parent 0 -pad 10
    grid columnconfigure $parent 1 -pad 10

    grid $top.master -row 0 -column 0 -sticky we
    grid $top.separator -row 1 -column 0 -sticky we
    grid $top.bbox -row 2 -column 0

    grid columnconfigure $top 0 -weight 1

    vwait ::gui::waitVar

    if {[string equal $::gui::waitVar "ok"]} {
	global parms
	set ModuleOps::masterDir [$top.master.masterEntry get]
	set ModuleOps::buildDir [$top.master.buildEntry get]
	set ModuleOps::installDir [$top.master.installEntry get]
	set ModuleOps::buildFlavor $parms(buildFlavor)

	destroy $top
	::gui::initProject

	$window(fileMenu) entryconfigure Close -state normal
	$window(fileMenu) entryconfigure Save -state normal
	$window(fileMenu) entryconfigure "Save As..." -state normal
    } else {
	destroy $top
    }

    return
}

# ::gui::saveOutput --
#
#	Save the output of the output log window.
#
# Arguments:
#	None.
#
# Side Effects:
#	A new file may be created.
#
# Results:
#	None.

proc ::gui::saveOutput {} {
    variable window

    set outputFile [tk_getSaveFile -defaultextension .log -title "Save Output"]

    if {$outputFile != ""} {
	set fileId [open $outputFile w]
	puts $fileId [$window(textOutput) get 0.0 end]
	close $fileId
    }

    return
}

# ::gui::clearOutput --
#
#	Clear all text from the output window.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::clearOutput {} {
    variable window

    $window(textOutput) delete 0.0 end

    return
}

# ::gui::ChooseDir --
#
#	Get a directory name from the user and store it in an engry widget.  If
#	the user "cancel"s out of the operation, the widget is left unchanged.
#
# Arguments:
#	widgetName	Name of text widget which will store the result.
#	title		Title to display for choose directory dialog
#
# Side Effects:
#	None.
#
# Results:
#	The value of the text variable may change.

proc ::gui::ChooseDir {widgetName {title {}}} {
    global $widgetName
    variable parms

    if {$parms(lastDir) == ""} {
	set initialDir [pwd]
    } else {
	set initialDir $parms(lastDir)
    }

    set dirName [tk_chooseDirectory -initialdir $initialDir -title $title]

    if {$dirName != ""} {
	$widgetName delete 0 end
	$widgetName insert end $dirName
	set parms(lastDir) $dirName
    }

    return
}

# ::gui::initProject --
#
#	Initialize a new project.  This routine assumes that the project
#	settings are already in place.  It will autoconf/configure the
#	master module and update the module listbox.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::initProject {} {
    ::ModuleOps::initMaster
    UpdateModulelist

    return
}

# ::gui::runBuild --
#
#	Perform a build using the current project settings.  All parameters
#	specifying how the build should be performed are taken from the
#	values set by the gui.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::runBuild {} {
    ::ModuleOps::takeBuildAction

    return
}

# ::gui::updateActiveModules --
#
#	Updates the active module listing based on the current listbox
#	selection.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::updateActiveModules {} {
    variable window

    set ModuleList {}
    foreach index [$window(moduleListbox) curselection] {
	lappend ModuleList [$window(moduleListbox) get $index]
    }
    ::ModuleOps::setActiveModules $ModuleList

    return
}

# ::gui::saveProject --
#
#	Save the current project settings.
#
# Arguments:
#	newFile		Boolean expressing if we should prompt for a file name.
#			1 means prompt, 0 means don't prompt.
#
# Side Effects:
#	A new file may be created.  The existing project file may be updated.
#
# Results:
#	None.

proc ::gui::saveProject {{newFile 0}} {
    set projectFile [::ModuleOps::getProjectFile]

    if {$newFile} {
	set projectFile \
		[tk_getSaveFile -defaultextension .bpj -title "Save Project"]
    } elseif {[string equal $projectFile ""]} {
	set projectFile \
		[tk_getSaveFile -defaultextension .bpj -title "Save Project"]
    }

    if {$projectFile == ""} {
	return
    } else {
	::ModuleOps::setProjectFile $projectFile
	::ModuleOps::saveProject $projectFile
    }

    return
}

# ::gui::closeProject --
#
#	Close the current project.  Update the File menu to reflect the new
#	state.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::closeProject {} {
    variable window

    ::ModuleOps::closeProject

    # Enable/disable menu entries

    $window(fileMenu) entryconfigure Close -state disabled
    $window(fileMenu) entryconfigure Save -state disabled
    $window(fileMenu) entryconfigure "Save As..." -state disabled

    return
}

# ::gui::openProject --
#
#	Load an existing project.
#
# Arguments:
#	None.
#
# Side Effects:
#	The current project is closed before the new one is opened.
#
# Results:
#	None.

proc ::gui::openProject {} {
    variable window

    set fileName [tk_getOpenFile -defaultextension .bpj -title "Open Project"]
    if {$fileName == ""} {
	return
    }

    ::gui::closeProject

    # Get the name of the project to open.

    set result [::ModuleOps::openProject $fileName]
    if {[lindex $result 0]} {
	$window(fileMenu) entryconfigure Close -state normal
	$window(fileMenu) entryconfigure Save -state normal
	$window(fileMenu) entryconfigure "Save As..." -state normal

	::gui::initProject
    } else {
	tk_dialog .errdialog "Open Project Failed" \
		"Open Failed:  [lindex $result 1]" \
		error 0 Ok
    }

    return
}

# ::gui::unimplemented --
#
#	Inform the user that the requested action has not been implemented.
#
# Arguments:
#	None.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::unimplemented {} {
    tk_dialog .unimplemented "Unimplemented feature" "This feature has not\
	    been implemented" info 0 Ok

    return
}

# ::gui::logError --
#
#	Redirects command output so that it is sent to the text output widget.
#
# Arguments:
#	string		String to display.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::logError {string} {
    variable window

    set endInView [$window(textOutput) bbox insert]

    $window(textOutput) insert end $string\n error
    if {$endInView != ""} {
	$window(textOutput) see end
    }
    update idletasks

    return
}

# ::gui::logMessage --
#
#	Redirects command output so that it is sent to the text output widget.
#
# Arguments:
#	string		String to display.
#
# Side Effects:
#	None.
#
# Results:
#	None.

proc ::gui::logMessage {string} {
    variable window

    set endInView [$window(textOutput) bbox insert]

    $window(textOutput) insert end $string\n
    if {$endInView != ""} {
	$window(textOutput) see end
    }
    update idletasks

    return
}

# ::ModuleHints::logError --
#
#	Redefine the standard logMessage routine so that output is not sent
#	to stderr.
#
# Arguments:
#	string		String to display.
#
# Side Effects:
#	The original ::ModuleHints::logError routine will be deleted.
#
# Results:
#	None.

proc ::ModuleHints::logError {string} {
    ::gui::logError $string
    return
}

# ::ModuleHints::logMessage --
#
#	Redefine the standard logMessage routine so that output is not sent
#	to stdout.
#
# Arguments:
#	string		String to display.
#
# Side Effects:
#	The original ::ModuleHints::logMessage routine will be deleted.
#
# Results:
#	None.

proc ::ModuleHints::logMessage {string} {
    ::gui::logMessage $string
    return
}
