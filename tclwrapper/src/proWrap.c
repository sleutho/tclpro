/* 
 * proWrap.c --
 *
 *	TclPro Wrapper implementation and hooks.
 *
 * Copyright (c) 1998-1999 by Scriptics, Corp.
 * All rights reserved.
 *
 * RCS: @(#) $Id: proWrap.c,v 1.3 2000/03/15 00:15:33 berry Exp $
 */

#include <tcl.h>
#include <tclInt.h>
#include <tclPort.h>
#include "unzip.h"
#include "proWrap.h"


/*
 * For any entry that exists in a wrapped application, this structure holds the
 * particular 'stat()' type information: size, mode, and last modification time.
 */

typedef struct WrapFileEntry {
    unsigned long size;			/* It's complete size. */
    int mode;				/* The 'stat' specific mode bits for
					 * this entry. */
    time_t lastModDateTime;		/* The date/time it was last mod'd. */
} WrapFileEntry;

/*
 * For each wrapped application known to the wrapper core, this structure holds
 * the name a pointer to the has table of file entries contained in the package,
 * and a usage count that represents the number of times it's been "loaded"
 * (see the API 'LoadWrap()' below.
 */

typedef struct WrapFileInfo {
    char *fileName;			/* The name of the file that holds the
					 * wrapped app.. */
    Tcl_HashTable *fileEntriesTable;	/* A hash table pointer to hold
					 * information for all files in the
					 * particular wrapped app.. */
    int usageCount;			/* This will count the number of times
					 * this "wrapped entity" has been loaded
					 * for use and ensure it stays loaded
					 * until the usage count hits zero. */
} WrapFileInfo;

/*
 * This static structure represents the information for the wrapped app., if
 * any, in the currently running executable!  The structure starts out with
 * null-pointers and gets initialized when 'Pro_WrapInit(...)' is called.
 */

static WrapFileInfo tclExecutableFileWrap = {
    NULL, NULL, 0
};

/*
 * Unfortunately, the UNZIP library does not provide a magic-cookie (a'la
 * ClientData) when it calls the 'WrapMessageFnCallBack()' function
 * during a redirected 'Uzp???()' function call.  Use 'theCurrentInterp' as a
 * global variable to this file to be able to direct the output of a 'Uzp???()'
 * function calls to the "current interpreter's" result.
 */

static Tcl_Interp * theCurrentInterp = NULL;
static CONST char *defaultEncoding = "identity";
static char wrappedEncoding[205] = "identity";
static int useEncoding = 0;

/*
 * The pre-defined name of a wrapped application's Tcl initialization script
 * The first string is used by the packaging utility to determine the name of
 * this file by searching for the pattern that preseeds the ':' character and
 * collecting the characters up to the final ':' character. The second string
 * is used by this module.
 */

static CONST char *_wrapInitFileName =
    "wrapInitFileName:_proWrapInit_.tcl:";
static CONST char *wrapInitFileName =
		     "_proWrapInit_.tcl";

/*
 * The pre-defined name of a file in the wrapped app. that contains the name of
 * the startup Tcl script filename.  The first string is used by the wrapper
 * utility to determine the name of this file by searching for the pattern that
 * preseeds the ':' character and collecting the characters up to the final ':'
 * character. The second string is used by this module.
 */

static CONST char *_wrapScriptInfoFileName =
    "wrapScriptInfoFileName:_proWrapScriptInfo_:";
static char *wrapScriptInfoFileName =
			   "_proWrapScriptInfo_";

/*
 * A static data structure used to hold a return value for a call to the
 * local routine 'TranslateRelativeFilename(...)'.  This variable is
 * initialized once and kept around forever; it essentially will grow
 * to the largest path ever translated.
 */

Tcl_DString translatedPathDString;

/*
 * Declarations for local procedures defined in this file:
 */

static int	    WrapMessageFnCallBack _ANSI_ARGS_((zvoid* pG, uch* buf,
			ulg size, int flag));
static int	    WrapStat _ANSI_ARGS_((CONST char *path,
			struct stat * statptr));
static int	    WrapAccess _ANSI_ARGS_((CONST char *path,
			int mode));
static Tcl_Channel  WrapOpenFileChannel _ANSI_ARGS_((
			Tcl_Interp *interp,
			char *fileName, char *modeString,
			int permissions));
static int	    WrapListCallBack _ANSI_ARGS_((char * path,
			cdir_file_hdr *crec));
static int	    LoadWrap _ANSI_ARGS_((CONST char * WrapFilename));

/*
 * The following function is implemented in wrapper/src/tclMemChan.c.
 * The prototype is here to prevent having to create a new header file.
 *
 */
EXTERN Tcl_Channel      TclCreateMemoryChannel _ANSI_ARGS_((
                            Tcl_Interp *interp, char *memPtr,
                            int mode, int permissions,
                            long memSize,
			    Tcl_FreeProc *freeProcPtr,
			    char *encoding));

/*
 *----------------------------------------------------------------------
 *
 * TranslateRelativeFilename --
 *
 *	Translates the string given by 'relativepath' to have forward-
 *	slashes ("/") instead of backslashes ("\").  Additionally, on
 *	Windows covert all characters to lowercase characters.  If
 *	'sripTrailingSlash' is set as 1, the trailing slash is removed
 *	during the translation.
 *
 *	Additionally, if 'reducePath' is set to 1, all "." components,
 *	path elements that precede any ".." components, and the ".."
 *	components of the path, are "reduced" from the translated path.
 *
 * Results:
 *      Returns a pointer to a static string.  If 'hasTrailingSlashPtr'
 *	is non-NULL, it is filled with 1 or 0 depending on whether
 *	'relativePath' contains a trailing slash or not (which ZIP
 *	uses to indicate a directory).
 *
 * Side effects:
 *      This routine keeps a static string internally that will be
 *	changed with this call, thereby making this static character
 *	array valid for only one call to this function.
 *
 *----------------------------------------------------------------------
 */

static char *
TranslateRelativeFilename(CONST char *relativePath,
			  int sripTrailingSlash, int *hasTrailingSlashPtr,
			  int reducePath)
{
    static int dsInitialized = 0;
    char * tmpCh;
    int hasTrailingSlash;

    if (!dsInitialized) {
	/*
	 * This is the first time this routine is being called; initialize
	 * our static DString.
	 */

	Tcl_DStringInit(&translatedPathDString);
	dsInitialized = 1;
    }

    Tcl_DStringSetLength(&translatedPathDString, 0);
    tmpCh = Tcl_DStringAppend(&translatedPathDString, relativePath, -1);

    while (*tmpCh) {
	if (*tmpCh == '\\') {
	    *tmpCh = '/';
	} else {
#	ifdef __WIN32__
    	    /*
	     * On Windows, file systems are case insensitive and we want
	     * to emulate the zipped files in much the same way.
	     */

	    *tmpCh = tolower(*tmpCh);
#	endif
	}

        ++tmpCh;
    }

    hasTrailingSlash = (*(tmpCh - 1) == '/');
    if (sripTrailingSlash && hasTrailingSlash) {
	*(tmpCh - 1) = 0;
    }
    if (hasTrailingSlashPtr != NULL) {
	*hasTrailingSlashPtr = hasTrailingSlash;
    }

    if (reducePath) {
	int nPathElems;
	char **pathElems = NULL;

	/*
	 * Split the path into its components.
	 */

	Tcl_SplitPath(Tcl_DStringValue(&translatedPathDString),
		      &nPathElems, &pathElems);

	if (nPathElems && (pathElems != NULL)) {
	    register int i;
	    char * elem;
	    int atLeastOneElemAppended = 0;

	    /*
	     * Loop through all the path elements searching for "." and ".."
	     * sequences.  Such elements are "reduced" out of setting them
	     * to NULL in the array. (Later we join the path elements back
	     * together, resulting in the ultimately desired path.)
	     */

	    for (i = 0; i < nPathElems; i++) {
		elem = pathElems[i];

		if ((*elem == '.') && (*(elem + 1) == '.')
			&& (*(elem + 2) == '\0')) {
		    register int j;

		    /*
		     * ".." found.  Look backward in the array and NULLify
		     * the nearest non-NULL element that precedes this ".."
		     * element.  Stop searching when a ".." is encountered,
		     * because this one has been processed alread.
		     */

		    for (j = i - 1; j >= 0; j--) {
			elem = pathElems[j];

			if (elem == NULL) {
			    continue;
			} else if ((*elem == '.') && (*(elem + 1) == '.')
				&& (*(elem + 2) == '\0')) {
			    break;
			} else if (*elem != '\0') {
			    /*
			     * Mark this ".." element to be ignored since a
			     * corresponding path element was located.
			     */

			    pathElems[j] = NULL;
			    pathElems[i] = NULL;

			    break;
			}
		    }
		} else if ((*elem == '.')
			&& (*(elem + 1) == '\0')) {
		    /*
		     * "." found.  Mark this element to be ignored.
		     */

		    pathElems[i] = NULL;
		}
	    }

	    /*
	     * Now join all the non-empty file elements that remain,
	     * delimiting with the "/" character.
	     */

	    Tcl_DStringSetLength(&translatedPathDString, 0);

	    for (i = 0; i < nPathElems; i++) {
		elem = pathElems[i];
		if (elem != NULL) {
		    if (atLeastOneElemAppended) {
			Tcl_DStringAppend(&translatedPathDString, "/", -1);
		    }
		    Tcl_DStringAppend(&translatedPathDString, elem, -1);
		    atLeastOneElemAppended = 1;
		}
	    }

	    Tcl_Free((char *)pathElems);
	}
    }
	
    return (Tcl_DStringValue(&translatedPathDString));
}

/*
 *----------------------------------------------------------------------
 *
 * WrapMessageFnCallBack --
 *
 *	This callback function is used to intercept messages that the
 *	UnZip library would normally write to standard out/standard error.
 *	Because the UnZip library does not provide any sort of magic
 *	cookie, this function is generally 
 *
 * Results:
 *      Returns 0 to the UnZip library to indicate no error occured.
 *
 * Side effects:
 *      If 'theCurrentInterp' is non-NULL, the passed 'buf' is appended
 *	to that interpreter's result.
 *
 *----------------------------------------------------------------------
 */

static
int WrapMessageFnCallBack(pG, buf, size, flag)
    zvoid *pG;	    /* not used */
    uch *buf;	    /* the output buffer itself */
    ulg size;	    /* size of the buffer being passed */
    int flag;	    /* not used */
{
    if (theCurrentInterp != NULL) {
	Tcl_AppendResult(theCurrentInterp, (char*)buf, (char*)NULL);
    }

    return 0;
}

/*
 *----------------------------------------------------------------------
 *
 * WrapStat --
 *
 *	Similar to the call 'TclStat(...)', this function returns the
 *	'stat' like information for the named 'path' that exists in the
 *	set of loaded wrapped objects.
 *
 * Results:
 *	See the C run-time library documentation on 'stat()'.
 *
 * Side effects:
 *	See the C run-time library documentation on 'stat()'.
 *
 *----------------------------------------------------------------------
 */

static int
WrapStat(path, statptr)
    CONST char *path;		/* Path of file to stat (in current CP). */
    struct stat *statptr;	/* Filled with results of stat call. */
{
    if ((tclExecutableFileWrap.fileEntriesTable != NULL)
	    && (Tcl_GetPathType((char *)path) == TCL_PATH_RELATIVE)) {
	Tcl_HashEntry *hashEntryPtr;

	path = (char *)TranslateRelativeFilename(path, 1, NULL, 1);

	hashEntryPtr = Tcl_FindHashEntry(
		tclExecutableFileWrap.fileEntriesTable, path);

	if (hashEntryPtr != NULL) {
	    WrapFileEntry *fileEntryPtr =
		(WrapFileEntry *)Tcl_GetHashValue(hashEntryPtr);

	    /*
	     * Return all the stat information known about this file entry.
	     */

	    statptr->st_size = fileEntryPtr->size;
	    statptr->st_mode = fileEntryPtr->mode;
	    statptr->st_ctime = fileEntryPtr->lastModDateTime;
	    statptr->st_atime = fileEntryPtr->lastModDateTime;
	    statptr->st_mtime = fileEntryPtr->lastModDateTime;
	    statptr->st_nlink = 1;
	    statptr->st_ino  = 0;
	    statptr->st_uid  = 0;
	    statptr->st_gid  = 0;

	    return 0;
	}
    }
    errno = ENOENT;
    return -1;
}

/*
 *----------------------------------------------------------------------
 *
 * WrapAccess --
 *
 *	Similar to the 'TclAccess(...)' function call, but the
 *	information for the requested 'path' is taken out from within
 *	all loaded wrapped objects.
 *
 * Results:
 *	See the C run-time library documentation on 'access()'.
 *	Generally no path in the wrapped app. is neither writable,
 *	executable, nor writable/readable; so therefore all requests for
 *	the modes 'W_OK', 'X_OK', and 06 (readable/writable), return a
 *	value of -1 with 'errno' set to EACCESS.
 *
 * Side effects:
 *	See the C run-time library documentation on 'access()'.
 *
 *----------------------------------------------------------------------
 */

static int
WrapAccess(path, mode)
    CONST char *path;		/* Path of file to stat (in current CP). */
    int mode;			/* Permission setting. */
{
    if ((tclExecutableFileWrap.fileEntriesTable != NULL)
	    && (Tcl_GetPathType((char *)path) == TCL_PATH_RELATIVE)) {
	path = (char *)TranslateRelativeFilename(path, 1, NULL, 1);

	if (Tcl_FindHashEntry(tclExecutableFileWrap.fileEntriesTable,
		    path) != NULL) {
	    switch (mode) {
	    case F_OK:

		/*
		 * The path does indeed exist in the wrapped app.
		 */

	    case R_OK:

		/*
		 * All paths in the wrapped app. are read-only.
		 */

		return 0;

	    case W_OK:
	    case X_OK:
	    case 6:	/* Read and write permission */ 

		/*
		 * No path in the wrap app. are neiter writable, executable,
		 * nor readable/writable.
		 */

		errno = EACCES;
		return -1;
	    }
	}
    }

    errno = ENOENT;
    return -1;
}

/*
 *----------------------------------------------------------------------
 *
 * WrapOpenFileChannel --
 *
 *	This routine is functionally equivalent to the
 *	Tcl_OpenFileChannel() routine but opens a "memory channel" to
 *	the requested file, if the file is wrapped in the currently
 *	running executable.
 *	
 *
 * Results:
 *
 *	The new memory channel or NULL, if the named file could not be
 *	opened in the wrapped executable.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static Tcl_Channel
WrapOpenFileChannel(interp, fileName, modeString, permissions)
    Tcl_Interp *interp;
    char *fileName;
    char *modeString;
    int permissions;
{
    Tcl_Channel retVal = NULL;

    /*
     * See if the requested file is in the ZIPped part of the executable.
     */

    if ((tclExecutableFileWrap.fileEntriesTable != NULL)
	    && (Tcl_GetPathType(fileName) == TCL_PATH_RELATIVE)) {
        UzpBuffer uzpBuffer;
	int mode;
	int seekFlag;

	uzpBuffer.strptr = NULL;
	uzpBuffer.strlength = 0;

	/*
	 * Fix Defect ID #413.  We pass NULL for the interp argument to
	 * 'TclGetOpenMode(...)', so that in the case of an error in the mode
	 * string, the interpreter result is left unchanged.  If there is an
	 * error in the mode, string, it will be handled by the built-in
	 * 'Tcl_OpenFileChannel(...)' routine.
	 */

	mode = TclGetOpenMode(NULL, modeString, &seekFlag);
	if (mode == -1) {
	    return NULL;
	}

	fileName = (char *)TranslateRelativeFilename(fileName, 1, NULL, 1);

	if ((Tcl_FindHashEntry(tclExecutableFileWrap.fileEntriesTable,
		fileName) != NULL)
		&& (UzpUnzipToMemory(tclExecutableFileWrap.fileName,
			fileName, &uzpBuffer)
			<= PK_WARN)
		&& uzpBuffer.strptr) {
	    /*
	     * 'free' is used as the memory deallocation procedure, because
	     * the Unzip library uses 'malloc' to do it's allocation.
	     */

	    retVal = TclCreateMemoryChannel(interp, uzpBuffer.strptr,
		    mode, permissions, uzpBuffer.strlength,
		    (Tcl_FreeProc *)free, 
                    /*useEncoding ? wrappedEncoding : */ (char *)defaultEncoding);
	} else if (uzpBuffer.strptr) {
	    /*
	     * Unzip API should provide a free routine.
	     */

	    free(uzpBuffer.strptr);
	}
    }

    return retVal;
}

/*
 *----------------------------------------------------------------------
 *
 * LoadWrap --
 *
 *	Currently called when the wrapper is initialized via a call to
 *	'Tcl_WrapInit(...)'.  Declares the filename given by
 *	'wrapFilename' as a wrapped object and loads all zipped file
 *	information from that file.
 *
 * Results:
 *	Returns TCL_OK if the named wrapped file was located and file
 *	entry information was retrievable.  Otherwise, TCL_ERROR is
 *	returned if either the package could not be located or an error
 *	was encountered while attempting to retrive the file entry
 *	informaiton.
 *
 * Side effects:
 *	Allocates memory as required to hold the file entry information.
 *	See the routine "WrapListCallBack(...)'.
 *
 *----------------------------------------------------------------------
 */

static int
LoadWrap(wrapFilename)
    CONST char * wrapFilename;		/* Name of a file containing a
					 * wrapped Tcl application */
{
    int retVal = TCL_ERROR;

    if (wrapFilename != NULL) {
	if ((tclExecutableFileWrap.fileName =
		(char *)Tcl_Alloc(strlen(wrapFilename) + 1)) != NULL) {
	    UzpInit uzpInit;
	    int iError;

	    uzpInit.structlen = sizeof(UzpInit);
	    uzpInit.msgfn = WrapMessageFnCallBack;
	    uzpInit.inputfn = (InputFn*)NULL;
	    uzpInit.pausefn = (PauseFn*)NULL;
	    uzpInit.userfn = NULL;

	    strcpy(tclExecutableFileWrap.fileName, wrapFilename);

	    iError = UzpFileTree2(tclExecutableFileWrap.fileName,
		    WrapListCallBack,
		    NULL, NULL, &uzpInit);

	    retVal = (iError <= PK_WARN ? TCL_OK : TCL_ERROR);
	}
    }

    return retVal;
}

/*
 *----------------------------------------------------------------------
 *
 * AddDirectoryPaths --
 *
 *	Given the translated file path, this routine adds all the
 *	interim directory paths for this file.
 *
 * Results:
 *	Nothing.
 *
 * Side effects:
 *	The hash table that keeps wrapped file information is updated.
 *
 *----------------------------------------------------------------------
 */

static void AddDirectoryPaths(translatedPath, tmPtr)
    char * translatedPath;
    struct tm *tmPtr;
{
    int pargc = 0;
    char **pargv = NULL;


    Tcl_SplitPath(translatedPath, &pargc, &pargv);
    if (pargv) {
	int newEntry;
	Tcl_HashEntry *newHashEntryPtr;
	Tcl_DString buffer;

	Tcl_DStringInit(&buffer);

	while (--pargc) {
	    /*
	     * Add only directory paths that haven't already been
	     * added before.  The first time we encounter a directory
	     * path that already exists, we stop because such a path
	     * would have already added it's parents on a previous
	     * call.
	     */

	    Tcl_DStringSetLength(&buffer, 0);
    	    Tcl_JoinPath(pargc, pargv, &buffer);
	    if (Tcl_FindHashEntry(tclExecutableFileWrap.fileEntriesTable,
				  Tcl_DStringValue(&buffer)) != NULL) {
		/*
		 * Stop because this directory path--and all its parents--
		 * have already been added.
		 */

		break;
	    }

	    newHashEntryPtr =
		    Tcl_CreateHashEntry(tclExecutableFileWrap.fileEntriesTable,
					Tcl_DStringValue(&buffer), &newEntry);

	    if (newEntry && newHashEntryPtr) {
		WrapFileEntry *newFileEntryPtr =
			(WrapFileEntry *)Tcl_Alloc(sizeof(WrapFileEntry));

		if (newFileEntryPtr != NULL) {
		    newFileEntryPtr->size = 0;
		    newFileEntryPtr->mode = (S_IFDIR | S_IREAD);
		    newFileEntryPtr->lastModDateTime = mktime(tmPtr);

		    Tcl_SetHashValue(newHashEntryPtr,
				     (ClientData)newFileEntryPtr);
		}
	    }
	}

	Tcl_DStringFree(&buffer);
	ckfree((char *)pargv);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * WrapListCallBack --
 *
 *	This callback function is used to process the list request
 *	of a zipped file (a call to 'UzpFileTree2(...')) initiated by the
 *	'LoadWrap(...)' function.
 *
 * Results:
 *      Returns 0 to the UNZIP library to indicate no error occured.
 *
 * Side effects:
 *      Allocates and initializes the hash table in the particular
 *	wrapped info structure.  On successful hash table initialization
 *	the particular path is added to the has table, and the hash table
 *	value for the particular path is set to the associated 'stat'
 *	type information.
 *
 *----------------------------------------------------------------------
 */

int WrapListCallBack(path, crec)
    char * path;
    cdir_file_hdr *crec;
{
    if (path != NULL) {
	if (tclExecutableFileWrap.fileEntriesTable == NULL) {

	    /*
	     * The hash table hasn't been allocated and initialized.  Do it now.
	     */

	    if ((tclExecutableFileWrap.fileEntriesTable =
		    (Tcl_HashTable *)Tcl_Alloc(sizeof(Tcl_HashTable))) != NULL) {
		Tcl_InitHashTable(tclExecutableFileWrap.fileEntriesTable,
			TCL_STRING_KEYS);
	    }
	}
	if (tclExecutableFileWrap.fileEntriesTable != NULL) {
	    int newEntry;
	    Tcl_HashEntry *newHashEntryPtr;
	    int pathHasTrailingSlash;
	    struct tm t;
	    char *translatedPath;

	    translatedPath =
		    TranslateRelativeFilename(path, 1,
					      &pathHasTrailingSlash, 1);
	    newHashEntryPtr = Tcl_CreateHashEntry(
		    tclExecutableFileWrap.fileEntriesTable,
		    translatedPath, &newEntry);

	    if (newEntry && newHashEntryPtr) {
		WrapFileEntry *newFileEntryPtr =
			(WrapFileEntry *)Tcl_Alloc(sizeof(WrapFileEntry));

		if (newFileEntryPtr != NULL) {
		    newFileEntryPtr->size = crec->ucsize;

		    /*
		     * Determine if the file is a directory or file and set
		     * the mode bits accordingly.
		     */

		    if (pathHasTrailingSlash) {
		        newFileEntryPtr->mode = (S_IFDIR | S_IREAD);
		    } else {
		        newFileEntryPtr->mode = (S_IFREG | S_IREAD);
		    }

		    /*
		     * Calculate the date the file was last modified.
		     */

		    t.tm_year =
		    	(unsigned short)((((crec->last_mod_file_date >> 9) & 0x7f) + 80)
		    		% (unsigned)100);
		    t.tm_mon =
		    	(unsigned short)((crec->last_mod_file_date >> 5) & 0x0f) - 1;
		    t.tm_mday =
		    	(unsigned short)(crec->last_mod_file_date & 0x1f);
		    t.tm_hour =
		    	(unsigned short)((crec->last_mod_file_time >> 11) & 0x1f);
		    t.tm_min =
		    	(unsigned short)((crec->last_mod_file_time >> 5) & 0x3f);
		    t.tm_sec = 0;
		    newFileEntryPtr->lastModDateTime = mktime(&t);

    		    Tcl_SetHashValue(newHashEntryPtr,
			    (ClientData)newFileEntryPtr);

		    /*
		     * Now add all the interim directory paths that make up
		     * this file path. 
		     */

		    AddDirectoryPaths(translatedPath, &t);
		}
	    }
	}
    }

    return 0;
}

/*
 *----------------------------------------------------------------------
 *
 * WrapInitialize --
 *
 *	This routine is responsible for inserting the WrapStat(),
 *	WrapAccess(), and WrapOpenFileChannel() routines into the
 *	respective chain of callback functions in the Tcl core.
 *
 * Results
 *	None.
 *
 * Side effects:
 *	Adds the above noted callback functions.
 *
 *----------------------------------------------------------------------
 */

static void
WrapInitialize(path)
     char * path;
{
    static int bInitialized = 0;

    if (!bInitialized) {
	TclStatInsertProc(WrapStat);

	TclAccessInsertProc(WrapAccess);

	TclOpenFileChannelInsertProc(WrapOpenFileChannel);

	bInitialized = 1;

	if (path != NULL) {
	    UzpInit uzpInit;
	    UzpBuffer uzpBuffer;
	    
	    /*
	     * Register the name of the Tcl executable (if its name has been
	     * determined) and load the file list from the zip.
	     */
	    LoadWrap(path);
	    
	    uzpInit.structlen = sizeof(UzpInit);
	    uzpInit.msgfn = WrapMessageFnCallBack;
	    uzpInit.inputfn = (InputFn*)NULL;
	    uzpInit.pausefn = (PauseFn*)NULL;
	    uzpInit.userfn = NULL;
	    
	    uzpBuffer.strptr = NULL;
	    uzpBuffer.strlength = 0;
	    
	    if ((UzpUnzipToMemory(path,
		    (char *)wrapInitFileName, &uzpBuffer) <= PK_WARN)
	            && uzpBuffer.strptr
	            && uzpBuffer.strlength) {
	        /*
		 * Retrieve the wrapped application's initialization script and
		 * set the 'tclPreInitScript' C pointer (defined in file:
		 * "generic/tclInitScript.h") to point to this script.  This
		 * script will contain all the "-code <scripts>" collected
		 * together.
		 */
	      
	      TclSetPreInitScript(uzpBuffer.strptr);
	    }
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Pro_WrapInit --
 *
 *	Initializes the TclPro Wrapper sub-system.
 *
 * Results:
 *	TCL_OK on successful initialization, TCL_ERROR otherwise.
 *
 * Side effects:
 *	Hooks to the 'TclStat', 'TclAccess', and 'Tcl_OpenFileChannel'
 *	routines are added as a result of this function call.
 *
 *----------------------------------------------------------------------
 */

int
Pro_WrapInit(interp)
    Tcl_Interp *interp;
{
    CONST char *s;

    s = _wrapInitFileName;		/* Suppress unused variable warning. */
    s = _wrapScriptInfoFileName;	/* Suppress unused variable warning. */

    useEncoding = 1;

    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Pro_WrapIsWrapped --
 *
 *	This functions assists in determining if the file named by
 *	wrapFileName is a wrapped application or not (e.g. contains
 *	a concatenated Zip file and contains the file named by
 *	the variables wrapScriptInfoFileName).
 *
 * Results
 *	Returns 1 if the file wrapFileName is wrapped, 0 otherwise.
 *	If it is wrapped, the pointers referenced by the variables
 *	below will point to a local static string containing the
 *	values from the listed flags from the "prowrap" utility:
 *
 *	    wrappedScriptFileNamePtr	-startup <scriptFileName>
 *	    wrappedArgsPtr		-arguments <arguments>
 *
 *	If either (or both) of these flags were not used when "prowrap"
 *	was used, then the respective reference variable will remain
 *	unchanged (the caller should set them to NULL before calling
 *	this routine to test for a change).  The strings pointed to
 *	by the respective variables are valid for only one call to
 *	this function--the caller should copy the values if desired.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
Pro_WrapIsWrapped(wrapFileName, wrappedScriptFileNamePtr, wrappedArgsPtr)
    CONST char *wrapFileName;
    char **wrappedScriptFileNamePtr;
    char **wrappedArgsPtr;
{
    int retVal = 0;

    /*
     * The string below will contain the contests of the file name by the
     * variable 'wrapScriptInfoFileName' subsequent to a call to
     * 'Pro_WrapIsWrapped()'.  This is guaraneteed to be valid for only
     * one call to this function.
     */

    static char wrappedScriptFileName[205];
    static char wrappedArgs[205];
    static char wrappedEncodingDir[1025];

    WrapInitialize(wrapFileName);

    if (wrapFileName) {
	UzpInit uzpInit;
	UzpBuffer uzpBuffer;

	uzpInit.structlen = sizeof(UzpInit);
	uzpInit.msgfn = WrapMessageFnCallBack;
	uzpInit.inputfn = (InputFn*)NULL;
	uzpInit.pausefn = (PauseFn*)NULL;
	uzpInit.userfn = NULL;

	uzpBuffer.strptr = NULL;
	uzpBuffer.strlength = 0;

	if ((UzpUnzipToMemory((char *)wrapFileName,
		(char *)wrapScriptInfoFileName, &uzpBuffer) <= PK_WARN)
		&& uzpBuffer.strptr
		&& uzpBuffer.strlength) {

	    char *startup, *arguments, *firstEOL, *secondEOL;
	    char *tclLibrary, *encoding, *thirdEOL, *fourthEOL;
	    
    	    wrappedScriptFileName[0] = '\0';
	    wrappedArgs[0] = '\0';

	    /*
	     * Attempt to get, if any, the wrapped application startup
	     * scrip filename and wrapped applications arguments.
	     */

#	    define STARTUP "-startup "
#	    define ARGUMENTS "-arguments "
#           define ENCODING_DIR "-tcllibrary "
#           define ENCODING  "-encoding " 
	    if ((startup = strstr(uzpBuffer.strptr, STARTUP))
		    && (firstEOL = strchr(startup + 1, '\n'))
		    && (arguments = strstr(firstEOL + 1, ARGUMENTS))
		    && (secondEOL = strchr(arguments + 1, '\n'))
		    && (tclLibrary = strstr(secondEOL + 1, ENCODING_DIR))
		    && (thirdEOL = strchr(tclLibrary + 1, '\n'))
		    && (encoding = strstr(thirdEOL + 1, ENCODING))
		    && (fourthEOL = strchr(encoding + 1, '\n'))) {
		startup += strlen(STARTUP);
		*firstEOL = 0;
		strcpy(wrappedScriptFileName, startup);

		arguments += strlen(ARGUMENTS);
		*secondEOL = 0;
		strcpy(wrappedArgs, arguments);

		tclLibrary += strlen(ENCODING_DIR);
		*thirdEOL = 0;
		strcpy(wrappedEncodingDir, tclLibrary);

		encoding += strlen(ENCODING);
		*fourthEOL = 0;
		strcpy(wrappedEncoding, encoding);

		if (strlen(wrappedScriptFileName)) {
		    *wrappedScriptFileNamePtr = wrappedScriptFileName;
		}
		if (strlen(wrappedArgs)) {
		    *wrappedArgsPtr = wrappedArgs;
		}
		if (strlen(wrappedEncodingDir)) {
		    Tcl_SetDefaultEncodingDir(wrappedEncodingDir);
		}

	    	retVal = 1;
	    }

	    /*
	     * 'free' is used as the memory deallocation procedure, because
	     * the Unzip library uses 'malloc' to do it's allocation.
	     */

	    free(uzpBuffer.strptr);
	}
    }

    return (retVal);
}

/*
 *----------------------------------------------------------------------
 *
 * Pro_WrapPrependArgs --
 *
 * 	This routine will take a string, prependArgs, that represents
 *	additional arguments and prepends them into the arguments array
 *	given by 'argc' & 'argv' (e.g., inserts them between the
 *	the exectuable argument, 'argv[0]' and the first real argument,
 *	'argv[1]').
 *
 * Results
 *	There is no return value, but a panic will occur if the
 *	variable prependArgs does't have a proper list structure.
 *
 *	*newArgvPtr will be filled in with the address of an array
 *	whose elements point to the new command line argument array.
 *	*newArgcPtr will get filled in with the number of elements
 *	in the new argument array.  Neither of these will be modified
 *	if 'prependArgString' is NULL or an empty string.
 *
 * Side effects:
 *	Memory is allocated for the 'newArgvPtr' in the exactly the same
 *	fashion as Tcl_SplitList().  The pointer values from the 'argv'
 *	variable are simply copied into the new arguments array; there-
 *	fore the memory they point to should be left intact until
 *	'newArgvPtr' is freed using 'ckfree()'.
 *
 *----------------------------------------------------------------------
 */

void
Pro_WrapPrependArgs(prependArgs, argc, argv,
	newArgcPtr, newArgvPtr)
    char *prependArgs;
    int argc;
    char **argv;
    int *newArgcPtr;		/* Total number of arguments. */
    char ***newArgvPtr;		/* Array pointing to new args */
{
    char **prependArgv;
    int prependArgc;

    if (prependArgs && *prependArgs) {
	if (Tcl_SplitList(NULL, prependArgs, &prependArgc, &prependArgv)
		== TCL_ERROR) {
	    panic("Pro_WrapPrependArgs: arguments have bad list structure");
	} else if (prependArgc != 0) {
	    int i, j, size, newArgc, buffSize = 0;
	    char *buff, **newArgv;

	    /*
	     * A "packed" argument array is created below with:
	     *   - the 0th pointer assigned to the 0th argument
	     *	   of the original argument array (argv[0]);
	     *   - the next few pointers will point to the prepend
	     *	   arguments and copied into the allocated area;
	     *   - the last few pointers will be assigned to the
	     *     1st to last set of original argument array
	     *     (arg[1]...arg[argc - 1]);
	     *   - finally a NULL terminator is added to the array.
	     * This operation has the effect of creating an argument
	     * that has the prepend arguments inserted between the
	     * original 0th and 1st arguments.
	     */

	    /*
	     * Calculate space for all the argument pointers, including a
	     * terminating NULL, and enough space for all prepend string
	     * element, including terminating '\0' for each string.
	     */

	    newArgc = argc + prependArgc;

	    size = (newArgc + 1) * sizeof(char *);

	    for (i = 0; i < prependArgc; i++) {
		buffSize += strlen(prependArgv[i]) + 1;
	    }

	    newArgv = (char **)ckalloc((unsigned)(size + buffSize));

	    newArgv[0] = argv[0];

	    buff = (char *)(newArgv) + size;

	    for (i = 0; i < prependArgc; i++) {
		int copyLength = strlen(prependArgv[i]) + 1;
		memcpy((VOID *)buff, (VOID *)prependArgv[i],
			(size_t)copyLength);
		newArgv[i + 1] = buff;
		buff += copyLength;
	    }

	    for (j = 1; j < argc; j++) {
		newArgv[i + j] = argv[j];
	    }

	    newArgv[newArgc] = NULL;

	    ckfree((char *)prependArgv);

	    *newArgvPtr = newArgv;
	    *newArgcPtr = newArgc;
	}
    }
}
