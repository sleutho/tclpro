# messages.tcl --
# 
#	This file contains textual messages that are used by the TclPro UNIX
#	installation application.
# 
# Copyright (c) 1998-2000 by Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: messages.tcl,v 1.7 2001/02/08 21:38:43 welch Exp $

proc Append {args} {
    foreach arg $args {
	append string $arg
    }
    return $string
}

set TCLPRO  "TclPro Version ${projectInfo::patchLevel}"
set SINGLE  "$TCLPRO for a named user"
set SHARED  "$TCLPRO for shared network users\nand Ajuba Solutions License Server"
set SERVER  "Ajuba Solutions License Server Version $projectInfo::serverVersion"
set ACROBAT "Adobe Acrobat Reader Version ${projectInfo::acrobatVersion}"

set HTTP_BUY  "http://dev.scriptics.com/software/tclpro/"
set HTTP_EVAL "http://dev.scriptics.com/software/tclpro/eval/"

set INSTALL_LIST [Append \
    "$TCLPRO or related components"]
set TCLPRODIR            [format "%s%s" "TclPro" "${projectInfo::directoryName}"]
set TCLPRO_TITLE        "$TCLPRO Installation"
set DEFTCLPRODIR         "[file join /usr local $TCLPRODIR]"
set PRESS_ENTER_CONTINUE "Press ENTER to continue"
set TCLPRO_LICENSE       "prolicense"
set TCLPRO_LICENSETTY    "prolicensetty"
set SERVER_EXE           "prolserver"
set YN                   "\[y/n\]"

set IMAGE                "tclProSplash.gif"
set LICENSE_TXT          "license.txt"
set LICENSE_TXT_NOLNBRK  "license.txt.nolnbrk"
set ACROBAT_LICENSE_TXT  "acrobat_license.txt"
set ACROBAT_LICENSE_TXT_NOLNBRK  "acrobat_license.txt.nolnbrk"

set ACROBATDIR            [format "%s%s" "Acrobat" "${projectInfo::acrobatVersion}"]
set DEFACROBATDIR         "/opt/$ACROBATDIR"

set SERVERDIR             [format "%s%s" "prolserver" "${projectInfo::directoryName}"]
set DEFSERVERDIR          "[file join /usr local $SERVERDIR]"

set DEFSERVERLOGDIR       "/var/log"
set DEFSERVERGID         "bin"
set DEFSERVERUID         "bin"
set DEFSERVERPORT        2577
set SERVER_NAME "prolserver"

set BACK_BUT   "< Back"
set NEXT_BUT   "Next >"
set DONE_BUT   "Cancel"
set FINISH_BUT "Finish"
set YES_BUT    "Yes"
set NO_BUT     "No"
set IAGREE_BUT "I Accept"
set QUIT_BUT   "Quit"
set MENU_BUT   "Main Menu"

set TITLE_WELCOME     "Install $TCLPRO"
set TITLE_WELCOME     "Welcome!"
set TITLE_MAIN_MENU   "Main Menu"
set TITLE_SHARED_MENU "Install A Shared Network License"
set TITLE_LICENSE     "View The License Terms"
set TITLE_PLATFORM    "Select Platforms"
set TITLE_DESTDIR     "Select A Destination Directory"
set TITLE_COMPONENTS  "Select TclPro Components To Install"
set TITLE_READY       "Ready To Install"
set TITLE_INSTALLING  "Installing"
set TITLE_INSTALL_KEY "Install License Key?"
set TITLE_LAUNCH_SERVER "Launch License Server?"
set TITLE_HOST_PORT   "Specify Server Location"
set TITLE_COMPLETE    "Installation Complete!"
set TITLE_USER_GROUP  "Choose your User ID and Group ID"
set TITLE_PORT        "Choose Communication Port"
set TITLE_ACROBAT     "Acrobat ${::projectInfo::acrobatVersion} Installation"
set TITLE_SERVER_DIRS "Select Destination Directories"

set WELCOME_TTY [Append \
    "Welcome to $TCLPRO Setup program. This program will install " \
    "$TCLPRO on your computer."]
set WELCOME_GUI [Append \
    "Welcome to $TCLPRO Setup program. This program will install " \
    "$INSTALL_LIST on your computer.\n\nPress the Next button to start " \
    "the installation.  You can press the Cancel button now if you do not " \
    "wish to install at this time."]
set WELCOME_WARNING [Append \
    "WARNING: This program is protected by copyright law and international " \
    "treaties."]
set WELCOME_LAWYER [Append \
    "Unauthorized reproduction or distribution of this program, or any " \
    "portion of it, may result in severe civil and criminal penalties, and " \
    "will be prosecuted to the maximum extent possible under law."]


set MAIN_MENU_GUI "Please choose which component you would like to install."
set MAIN_MENU_TTY "Please enter which component you would like to install."

set MENU_TTY_ONLYONE "Please enter a number from the list"
set MENU_TTY_MULTI [Append \
	"Please enter one or more numbers from the list separated by spaces"]
set MENU_TTY_CHOOSE "Choice"

set SHARED_MENU_GUI [Append \
	"Choose one of the following options if you are using a Shared " \
	"Network License for $TCLPRO.  The TclPro installation contains the " \
	"same options as the standard TclPro installation (for named "\
	"users) except that instead of installing your license, you are "\
	"asked for the host and port of your license server.\n"]
set SHARED_MENU_TTY [Append \
	"Choose one of the following options if you are using a Shared " \
	"Network License for $TCLPRO.  The TclPro installation contains the " \
	"same options as the standard TclPro installation (for named "\
	"users) except that instead of installing your license, you are "\
	"asked for the host and port of your license server.\n\n"]
set SHARED_MENU_NOTE [Append \
	"Note:  You must have root access to properly " \
	"install Ajuba Solutions License Server.\n"]

set ASK_DISPLAY_README [Append \
    "Would you like to view the README file at this time? $YN"]

set PLATFORM_TTY [Append \
    "If you are installing TclPro binaries, please select the platform(s) " \
    "below that you want, separated with spaces like " \
    "\"1 2 3\".  If you are only installing Tcl/Tk source files, " \
    "the platform selection will not matter." \
    "\n\nNote:  each machine using TclPro from the same directory must " \
    "mount that directory in the same manner. For example, if you install " \
    "in \"$DEFTCLPRODIR\" on one machine, other machines must mount that " \
    "same directory (or have access to it) using the same \"$DEFTCLPRODIR\" " \
    "directory name. This is especially important to remember if you are " \
    "installing TclPro for multiple platforms."]
set PLATFORM_GUI  [Append \
    "If you are installing TclPro binaries, please enter the platform(s) " \
    "below that you want.  If you are only installing Tcl/Tk source files, " \
    "you do not need to select a platform."]
set PLATFORM_GUI_NOTE [Append \
    "\nNote:  each machine using TclPro from the same directory must mount " \
    "that directory in the same manner. For example, if you install in " \
    "\"$DEFTCLPRODIR\" on one machine, other machines must mount that same " \
    "directory (or have access to it) using the same \"$DEFTCLPRODIR\" " \
    "directory name. This is especially important to remember if you are " \
    "installing TclPro for multiple platforms."]

set PLATFORM_TTY_CHOOSE "Platforms to install"

set COMPONENT_TTY [Append \
	"The following components are available for installation.  " \
	"You may choose to install one or more at a time, separated " \
	"with spaces like \"1 2\"."]
set COMPONENT_TTY_CHOOSE "Components to install"


set DEST_DIR_CHOOSE [Append \
    "Enter a destination directory for the TclPro product (e.g., " \
    "\"$DEFTCLPRODIR\".  SETUP will attempt to create this directory."]

set DEST_DIR_GUI_NOTEXIST [Append \
    "The directory you entered does not exist.  " \
    "Would you like to create it now?"]
set DEST_DIR_TTY_NOTEXIST [Append "$DEST_DIR_GUI_NOTEXIST $YN"]

# for Server install, one window has two directories, need better message
set DEST_DIRNAME_GUI_NOTEXIST [Append \
    "The directory \"%1\$s\" does not exist.  " \
    "Would you like to create it now?"]

set DEST_DIR_GUI_CHOOSE [Append \
    "SETUP will install $TCLPRO in the following directory.\n\n" \
    "To install into a different directory, change the entry to " \
    "another directory.\n\n" \
    "Destination Directory:"]

set DEST_DIR_ACROBAT_GUI_CHOOSE [Append \
    "SETUP will install $ACROBAT in the following directory.\n\nTo " \
    "install into a different directory, change the entry to " \
    "another directory.\n\nNote: Acrobat requires approx. 12M of " \
    "of disk space.\n\nDestination Directory:"]

set DEST_DIR_SERVER_GUI_CHOOSE [Append \
    "SETUP will install $SERVER in the following directory.  To install " \
    "$SERVER into a different directory, change the " \
    "entry to another directory.\n\nDestination Directory:"]
set LOG_DIR_SERVER_GUI_CHOOSE [Append \
    "\n\n\n\n$SERVER will create a log file to record usage data in a " \
    "separate directory.  You may want your log directory to be located " \
    "on a separate partition or disk from the $SERVER destination directory " \
    "for ease of management.\n\nLog Directory:"]

set SERVER_TITLE "$SERVER Installation"
set SERVER_PORT_GUI_CHOOSE [Append \
    "Ajuba Solutions License Server will monitor and use a Communications " \
    "Port in order to communicate with client software requesting a " \
    "license. You should select a port that is not already in use by " \
    "another application.\n\nThis is also the port used to administer " \
    "Ajuba Solutions License Server, view license and server statistics, " \
    "set preferences, and manage licenses. It is an HTTP server and you " \
    "can point any Web browser to the port and access the administration " \
    "HTML pages.\n\nTo change the port number, change the entry to "\
    "another port number.\n\nPort number:"]
set SERVER_USERID_GUI_CHOOSE [Append \
    "When Ajuba Solutions License Server is launched at boot time, it will " \
    "initially be running as 'root'.  To improve security on your system, " \
    "Ajuba Solutions License Server can change its User ID and Group ID to " \
    "values that you choose.  Enter the name or number of the User ID " \
    "and Group ID below.\n\n\To change the User ID, change the entry to " \
    "another User name or UID number.\n\nUser name or UID number:"]
set SERVER_USER_GROUP_TTY [Append \
    "Ajuba Solutions License Server should be run with a User ID " \
    "and Group ID other than 'root'.  Please specify which user and " \
    "group should be used."]
set SERVER_GROUPID_GUI_CHOOSE [Append \
    "To change the Group ID, change the entry to another " \
    "Group name or GID number.\n\nGroup name or GID number:"]
set SERVER_GUI_BAD_UID [Append \
    "The User name or User ID you entered is invalid."]
set SERVER_GUI_BAD_GID [Append \
    "The Group name or Group ID you entered is invalid."]
set SERVER_GUI_BAD_PORT [Append \
    "The port number you entered is invalid."]

set SERVER_INSTALL_DIR_CHOOSE [Append \
	"Enter a destination directory for $SERVER"]
set SERVER_LOG_DIR_CHOOSE [Append \
	"Enter a directory for the server log file"]

set SERVER_USER_GROUP_TTY [Append \
	"Please select the user and group for Ajuba Solutions License " \
	"Server.  This is typically something other than 'root'. "]
set SERVER_USER_TTY "User"
set SERVER_BAD_USER_TTY "Please enter a valid user name or id"
set SERVER_GROUP_TTY "Group"
set SERVER_BAD_GROUP_TTY "Please enter a valid group name or id"
set INSTALL_SERVER_GUI_RUNNING "\n\nPlease wait...installing $SERVER\n\n\n"
set INSTALL_SERVER_GUI_FAILED [Append \
    "\nError Detected while installing $SERVER \n\n" \
    "Review the text above, then press the Back button to reenter the " \
    "installation information or the " \
    "Cancel button to abort the installation."]
set INSTALL_SERVER_GUI_SUCCESSFUL [Append \
    "\n$SERVER Installation Successful!\n\n" \
    "Review the text above for warnings or special instructions, then " \
    "press the Next button to continue."]

set DEST_DIR_GUI_NOTEXIST [Append \
    "The directory you entered does not exist.  " \
    "Would you like to create it now?"]
set DEST_DIR_TTY_NOTEXIST [Append "$DEST_DIR_GUI_NOTEXIST $YN"]
set DEST_DIR_NO_WRITE_PERMISSION [Append \
    "You do not have write permissions in that directory.  " \
    "Enter another directory."]
set DEST_DIRNAME_NO_WRITE_PERMISSION [Append \
    "You do not have write permissions in the directory \"%1\$s\".  " \
    "Enter another directory."]
set DEST_DIR_ENTER_REL_PATH [Append \
    "\"%1\$s\" is a relative path, please enter an absolute path,"]

set COMPONENTS_GUI [Append \
    "In the option list below, select the checkboxes for the components " \
    "that you would like to install."]

set SHARED_GUI_HOST_PORT [Append \
    "A shared network installation is configured to work with an " \
    "installed Ajuba Solutions License Server.  When you use TclPro, the product " \
    "will automatically contact the Ajuba Solutions License Server that you " \
    "specify below to check out a license."]

set SHARED_HOST "Host:"
set SHARED_PORT "Port:"
set SHARED_NEED_HOST "Please specify a host name."
set SHARED_NEED_PORT "Please specify a port number."
set SHARED_BAD_PORT  "Invalid port number, please enter an integer port number."
set SHARED_HOST_TTY "Host"
set SHARED_PORT_TTY "Port"

# This value should be generated by the license module
set DEFAULT_SHARED_PORT 2577

set INSTALL_SOURCES_TCL    "Tcl version $projectInfo::srcVers(tcl)"
set INSTALL_SOURCES_TK     "Tk version $projectInfo::srcVers(tk)"
set INSTALL_SOURCES_INCR   "\[incr Tcl\] version $projectInfo::srcVers(itcl)"
set INSTALL_SOURCES_TCLX   "TclX version $projectInfo::srcVers(tclx)"
set INSTALL_SOURCES_EXPECT "Expect version $projectInfo::srcVers(expect)"


set INSTALL_TTY_READY [Append \
    "You are now ready to install $TCLPRO with the following options:\n\n" \
    "\tDestination\t%2\$s\n" \
    "\n\tPlatform%4\$s \t%1\$s" \
    "\n\tComponent%5\$s\t%3\$s" \
    "\n\nInstallation may take several minutes.\n\n"]
set INSTALL_TTY_READY_PROMPT [Append \
    "Press ENTER to begin the installation or CTRL+C to abort now"]
set INSTALL_GUI_READY_1 [Append \
    "You are now ready to install $TCLPRO with the following options:\n\n" \
    ]
set INSTALL_GUI_READY_2 [Append \
    "\nPress the Next button to begin the installation or the Back button " \
    "to reenter the installation information.\n\nInstallation may take " \
    "several minutes."]
set INSTALL_ACROBAT_TTY_READY [Append \
    "You are now ready to install $ACROBAT.  " \
    "Press ENTER to begin the installation or CTRL+C to abort now"]
set INSTALL_ACROBAT_GUI_READY [Append \
    "You are now ready to install $ACROBAT with the following options:\n\n" \
    "\tDestination\t%1\$s\n\n" \
    "Press the Next button to begin the installation or the Back button " \
    "to reenter the installation information."]
set INSTALL_SERVER_TTY_READY [Append \
    "You are now ready to install $SERVER with the following options:\n\n" \
    "\tDestination  \t%1\$s\n" \
    "\tLog Directory\t%2\$s\n" \
    "\tUser ID      \t%3\$s\n" \
    "\tGroup ID     \t%4\$s\n" \
    "\tPort Number  \t%5\$s\n"]
set INSTALL_SERVER_GUI_READY [Append \
    "You are now ready to install $SERVER with the following options:\n\n" \
    "\tDestination  \t%1\$s\n" \
    "\tLog Directory\t%2\$s\n" \
    "\tUser ID      \t%3\$s\n" \
    "\tGroup ID     \t%4\$s\n" \
    "\tPort Number  \t%5\$s\n" \
    "\n\nPress the Next button to begin the installation or the Back button " \
    "to reenter the installation information."]
set INSTALL_TTY_ACROBAT "Launching Acrobat installer..."
set INSTALL_GUI_ACROBAT [Append \
    "In order to view TclPro online documentation, you will need to " \
    "have Adobe Acrobat Reader 3.0.2 or later installed on your system." \
    "\n\nNote: Acrobat's installer is purely text based.  To install " \
    "Acrobat Reader, please refer to the UNIX Console used to launch " \
    "this installation program.\n\nWould like to install version 3.0.2 " \
    "at this time?"]
set INSTALL_KEY_NOTE [Append \
    "If you do not have a license key, you may go to $HTTP_BUY to purchase " \
    "one, or to $HTTP_EVAL to get a free 15 day evaluation license.\n"]
set INSTALL_GUI_KEY [Append \
    "You must install a license key before you can use $TCLPRO.  If you " \
    "do not install the license key now you may do so by running " \
    "\"$TCLPRO_LICENSE\" before using $TCLPRO.\n\n" \
    "$INSTALL_KEY_NOTE \n" \
    "Would like to install the license key at this time?"]
set INSTALL_TTY_KEY [Append \
    "You must install a license key before you can use $TCLPRO.  If you " \
    "do not install the license key now you may do so by running " \
    "\"$TCLPRO_LICENSE\" before using $TCLPRO.\n\n" \
    "$INSTALL_KEY_NOTE"]
set INSTALL_TTY_KEY_PROMPT [Append \
    "Would you like to install the license key at this time? \[y/n\]"]
set INSTALL_TTY_DONE [Append \
    "$TCLPRO has been successfully installed.  " \
    "You will need to set the PATH " \
    "variable in your environment to include the TclPro bin directory: %PATH%"]
set INSTALL_TTY_DONE_PROMPT [Append \
    "Press ENTER to continue"]
set INSTALL_GUI_DONE [Append \
    "$TCLPRO has been successfully installed.\n\n" \
    "You will need to set the PATH variable in your environment " \
    "to include the TclPro bin directory according to the platform " \
    "you are using:\n\n%1\$s"]
set INSTALL_GUI_DONE_NO_PATHS [Append \
    "$TCLPRO has been successfully installed.\n\n"]
set INSTALL_ACROBAT_TTY_DONE [Append \
    "$ACROBAT has been successfully installed.  " \
    "Press ENTER to exit the installation program"]
set INSTALL_ACROBAT_GUI_DONE [Append \
    "$ACROBAT has been successfully installed.\n\n" \
    "You will need to set the PATH variable in your environment " \
    "to include the Acrobat bin directory:\n\n\t%PATH%\n\n"]
set INSTALL_SERVER_TTY_DONE [Append \
    "$SERVER has been successfully installed. In order to start the license " \
    "manually, type the following command:"]
set INSTALL_SERVER_TTY_HTTP [Append \
    "You must access the server to complete the setup of the server " \
    "preferences and install licenses.  Once $SERVER has been started, " \
    "you can access the server using a web browser via the following URL:"]
set INSTALL_SERVER_TTY_DONE_PROMPT [Append \
    "Would you like to start the server now?"]
set INSTALL_SERVER_GUI_DONE [Append \
    "$SERVER has been successfully installed. In order to start the license " \
    "manually, type the following command:\n\n" \
    "\t%3\$s\n\n" \
    "You must access the server to complete the setup of the server " \
    "preferences and install licenses.  Once $SERVER has been started, " \
    "you can access the server using a web browser via the following " \
    "URL:\n\n\thttp://%1\$s:%2\$s"]
set SERVER_GUI_LAUNCH "Would you like to start the server now?"

set INSTALL_ABORT [Append \
    "Do you want to quit the installation?"]	
set INSTALL_ERROR [Append \
    "An unexpected error occured while installing $TCLPRO:\n%1\$s"]


set LICENSE_GUI_TERMS [Append \
	"BY CLICKING ON THE \"I ACCEPT\" BUTTON OR INSTALLING THE SOFTWARE " \
	"YOU ARE CONSENTING TO BE BOUND BY THE TERMS OF THIS AGREEMENT " \
	"(THIS \"AGREEMENT\").  IF YOU DO NOT AGREE TO ALL OF THE TERMS, "  \
	"CLICK THE \"QUIT\" BUTTON AND DO NOT INSTALL THE SOFTWARE.  If you " \
	"have purchased the software, you should promptly return the " \
	"software and you will receive a refund of your money.  After " \
	"installing the software, you can view a copy of this Agreement " \
	"from the file \"license.txt\" in the directory where you installed " \
        "the software."]
set LICENSE_TTY_TERMS [Append \
	"BY TYPING \"ACCEPT\" OR INSTALLING THE SOFTWARE YOU " \
	"ARE CONSENTING TO BE BOUND BY THE TERMS OF THIS AGREEMENT (THIS " \
	"\"AGREEMENT\").  IF YOU DO NOT AGREE TO ALL OF THE TERMS, TYPE "  \
	"\"QUIT\" AND DO NOT INSTALL THE SOFTWARE.  If you have purchased " \
	"the software, you should promptly return the software and you will " \
	"receive a refund of your money.  After installing the software, " \
	"you can view a copy of this Agreement from the file " \
	"\"license.txt\" in the directory where you installed the software."]

set ACROBAT_LICENSE_GUI_TERMS [Append \
	"BY CLICKING ON THE \"I ACCEPT\" BUTTON OR INSTALLING THE SOFTWARE " \
	"YOU ARE CONSENTING TO BE BOUND BY THE TERMS OF THIS AGREEMENT " \
	"(THIS \"AGREEMENT\").  IF YOU DO NOT AGREE TO ALL OF THE TERMS, "  \
	"CLICK THE \"QUIT\" BUTTON AND DO NOT INSTALL THE SOFTWARE.  If you " \
	"have purchased the software, you should promptly return the " \
	"software and you will receive a refund of your money.  After " \
	"installing the software, you can view a copy of this Agreement " \
	"from the file \"Reader/License.pdf\" in the directory where you installed " \
        "the software."]
set ACROBAT_LICENSE_TTY_TERMS [Append \
	"BY TYPING \"ACCEPT\" OR INSTALLING THE SOFTWARE YOU " \
	"ARE CONSENTING TO BE BOUND BY THE TERMS OF THIS AGREEMENT (THIS " \
	"\"AGREEMENT\").  IF YOU DO NOT AGREE TO ALL OF THE TERMS, TYPE "  \
	"\"QUIT\" AND DO NOT INSTALL THE SOFTWARE.  If you have purchased " \
	"the software, you should promptly return the software and you will " \
	"receive a refund of your money.  After installing the software, " \
	"you can view a copy of this Agreement from the file " \
	"\"Reader/License.pdf\" in the directory where you installed the software."]

set LICENSE_TTY_AGREE  "Do you accept the license terms? \[accept/quit\]"
set LICENSE_TTY_LOOP   "Please type either \"accept\" or \"quit\""
set LICENSE_AGREE_STR  "accept"
set LICENSE_QUIT_STR   "quit"

