# Microsoft Developer Studio Project File - Name="App3" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 5.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) External Target" 0x0106

CFG=App3 - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "App3.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "App3.mak" CFG="App3 - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "App3 - Win32 Release" (based on "Win32 (x86) External Target")
!MESSAGE "App3 - Win32 Debug" (based on "Win32 (x86) External Target")
!MESSAGE 

# Begin Project
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""

!IF  "$(CFG)" == "App3 - Win32 Release"

# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Cmd_Line "NMAKE /f App3.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "App3.exe"
# PROP BASE Bsc_Name "App3.bsc"
# PROP BASE Target_Dir ""
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Cmd_Line "NMAKE /f App3.mak"
# PROP Rebuild_Opt "/a"
# PROP Target_File "App3.exe"
# PROP Bsc_Name "App3.bsc"
# PROP Target_Dir ""

!ELSEIF  "$(CFG)" == "App3 - Win32 Debug"

# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Cmd_Line "NMAKE /f App3.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "App3.exe"
# PROP BASE Bsc_Name "App3.bsc"
# PROP BASE Target_Dir ""
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Cmd_Line "NMAKE -nologo -f App3.mak"
# PROP Rebuild_Opt "/a"
# PROP Target_File "App3.exe"
# PROP Bsc_Name "App3.bsc"
# PROP Target_Dir ""

!ENDIF 

# Begin Target

# Name "App3 - Win32 Release"
# Name "App3 - Win32 Debug"

!IF  "$(CFG)" == "App3 - Win32 Release"

!ELSEIF  "$(CFG)" == "App3 - Win32 Debug"

!ENDIF 

# Begin Source File

SOURCE=.\App3.mak
# End Source File
# Begin Source File

SOURCE=.\itclstack.tcl
# End Source File
# Begin Source File

SOURCE=.\stack.h
# End Source File
# Begin Source File

SOURCE=.\stackinit.cpp
# End Source File
# Begin Source File

SOURCE=.\startup.tcl
# End Source File
# End Target
# End Project

