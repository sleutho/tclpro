/*
 * tclMemChan.c --
 *
 *      Channel driver for memory based file I/O.
 *
 * Copyright (c) 1998-1999 by Scriptics, Corp.
 * All rights reserved.
 *
 * RCS: @(#) $Id: tclMemChan.c,v 1.4 2000/07/23 04:43:24 welch Exp $
 */
 
#include <tcl.h>
#include <tclInt.h>
#include <tclPort.h>

/*
 * This is the size of the channel name for Memory based channels
 */

#define CHANNEL_NAME_SIZE	64
static char channelName[CHANNEL_NAME_SIZE+1];

/*
 * The following structure contains per-instance data for a memory based channel.
 */

typedef struct MemoryInfo {
    Tcl_Channel channel;	/* Pointer to channel structure. */
    char *memPtr;		/* Input/output memory. */
    int validMask;		/* OR'ed combination of TCL_READABLE,
				 * TCL_WRITABLE, or TCL_EXCEPTION: indicates
				 * which operations are valid on the file. */
    int watchMask;		/* OR'ed combination of TCL_READABLE,
				 * TCL_WRITABLE, or TCL_EXCEPTION: indicates
				 * which events should be reported. */
    Tcl_FreeProc *memFreeProc;	/* The procedure to free memory assoc'd w/chnnel. */
    long currOffset;		/* Current offset from the start of the memory block. */
    long size;			/* Size of the memory block. */
    struct MemoryInfo *nextPtr;	/* Pointer to next registered memory. */
} MemoryInfo;

/*
 * List of all memory channels currently open.
 */

static MemoryInfo *firstMemoryPtr;

/*
 * Static routines for this memory:
 */

static int		MemoryCloseProc _ANSI_ARGS_((ClientData instanceData,
		            Tcl_Interp *interp));
static int		MemoryGetHandleProc _ANSI_ARGS_((
    			    ClientData instanceData,
		            int direction, ClientData *handlePtr));
static int		MemoryInputProc _ANSI_ARGS_((ClientData instanceData,
	            	    char *buf, int toRead, int *errorCode));
static int		MemoryOutputProc _ANSI_ARGS_((ClientData instanceData,
			    char *buf, int toWrite, int *errorCode));
static int		MemorySeekProc _ANSI_ARGS_((ClientData instanceData,
			    long offset, int mode, int *errorCode));
static void		MemoryWatchProc _ANSI_ARGS_((ClientData instanceData,
		            int mask));
static int		MemoryGetHandleProc _ANSI_ARGS_((
    			    ClientData instanceData,
			    int direction, ClientData *handlePtr));

/*
 * This structure describes the channel type structure for memory based IO.
 */

static Tcl_ChannelType memoryChannelType = {
    "mem",			/* Type name. */
    NULL,			/* Set blocking or non-blocking mode.*/
    MemoryCloseProc,		/* Close proc. */
    MemoryInputProc,		/* Input proc. */
    MemoryOutputProc,		/* Output proc. */
    MemorySeekProc,		/* Seek proc. */
    NULL,			/* Set option proc. */
    NULL,			/* Get option proc. */
    MemoryWatchProc,		/* Set up the notifier to watch the channel. */
    MemoryGetHandleProc,	/* Get an OS handle from channel. */
};

/*
 *----------------------------------------------------------------------
 *
 * MemoryCloseProc --
 *
 *	Closes the IO channel.
 *
 * Results:
 *	0 if successful, the value of errno if failed.
 *
 * Side effects:
 *	Closes the physical channel
 *
 *----------------------------------------------------------------------
 */

static int
MemoryCloseProc(instanceData, interp)
    ClientData instanceData;	/* Pointer to MemoryInfo structure. */
    Tcl_Interp *interp;		/* Not used. */
{
    MemoryInfo *memoryInfoPtr = (MemoryInfo *) instanceData;
    MemoryInfo **nextPtrPtr;

    if (memoryInfoPtr->memFreeProc != NULL) {
	(*(memoryInfoPtr->memFreeProc))(memoryInfoPtr->memPtr);
    }

    /*
     * Remove the memory from the watch list.
     */

    for (nextPtrPtr = &firstMemoryPtr; (*nextPtrPtr) != NULL;
	 nextPtrPtr = &((*nextPtrPtr)->nextPtr)) {
	if ((*nextPtrPtr) == memoryInfoPtr) {
	    (*nextPtrPtr) = memoryInfoPtr->nextPtr;
	    break;
	}
    }
    ckfree((char *)memoryInfoPtr);

    return 0;
}

/*
 *----------------------------------------------------------------------
 *
 * MemorySeekProc --
 *
 *	Seeks on a memory-based channel. Returns the new position.
 *
 * Results:
 *	-1 if failed, the new position if successful. If failed, it
 *	also sets *errorCodePtr to the error code.
 *
 * Side effects:
 *	Moves the location at which the channel will be accessed in
 *	future operations.
 *
 *----------------------------------------------------------------------
 */

static int
MemorySeekProc(instanceData, offset, mode, errorCodePtr)
    ClientData instanceData;			/* Memory state. */
    long offset;				/* Offset to seek to. */
    int mode;					/* Relative to where
                                                 * should we seek? */
    int *errorCodePtr;				/* To store error code. */
{
    MemoryInfo *infoPtr = (MemoryInfo *) instanceData;

    *errorCodePtr = 0;

    if (mode == SEEK_SET) {
	if (offset < infoPtr->size) {
            infoPtr->currOffset = offset;
	} else {
	    /* @@@ Can't seek beyond end-of-memory block. 
	           Realloc perhaps? Is this reasonable? */
            infoPtr->currOffset = infoPtr->size;
	}
    } else if (mode == SEEK_CUR) {
	if (infoPtr->currOffset + offset < infoPtr->size) {
            infoPtr->currOffset += offset;
	} else {
	    /* @@@ Can't seek beyond end-of-memory block. 
	           Realloc perhaps? Is this reasonable? */
            infoPtr->currOffset = offset;
	}
    } else if (mode == SEEK_END) {
	if (infoPtr->size - offset >= 0) {
            infoPtr->currOffset = infoPtr->size - offset;
	} else {
            infoPtr->currOffset = 0;
	}
    }

    return infoPtr->currOffset;
}

/*
 *----------------------------------------------------------------------
 *
 * MemoryInputProc --
 *
 *	Reads input from the IO channel into the buffer given. Returns
 *	count of how many bytes were actually read, and an error indication.
 *
 * Results:
 *	A count of how many bytes were read is returned and an error
 *	indication is returned in an output argument.
 *
 * Side effects:
 *	Reads input from the actual channel.
 *
 *----------------------------------------------------------------------
 */

static int
MemoryInputProc(instanceData, buf, bufSize, errorCode)
    ClientData instanceData;		/* Memory state. */
    char *buf;				/* Where to store data read. */
    int bufSize;			/* How much space is available
                                         * in the buffer? */
    int *errorCode;			/* Where to store error code. */
{
    MemoryInfo *infoPtr;
    int bytesRead = 0;

    *errorCode = 0;

    infoPtr = (MemoryInfo *) instanceData;

    if (infoPtr->currOffset + bufSize <= infoPtr->size) {
	bytesRead = bufSize;
    } else if (infoPtr->currOffset + bufSize > infoPtr->size) {
	bytesRead = infoPtr->size - infoPtr->currOffset;
    }

    if (bytesRead) {
	memcpy((void*)buf, (infoPtr->memPtr + infoPtr->currOffset), bytesRead);

        infoPtr->currOffset += bytesRead;
    }
    
    return bytesRead;
}

/*
 *----------------------------------------------------------------------
 *
 * MemoryOutputProc --
 *
 *	Writes the given output on the IO channel. Returns count of how
 *	many characters were actually written, and an error indication.
 *
 * Results:
 *	A count of how many characters were written is returned and an
 *	error indication is returned in an output argument.
 *
 * Side effects:
 *	Writes output on the actual channel.
 *
 *----------------------------------------------------------------------
 */

static int
MemoryOutputProc(instanceData, buf, toWrite, errorCode)
    ClientData instanceData;		/* Memory state. */
    char *buf;				/* The data buffer. */
    int toWrite;			/* How many bytes to write? */
    int *errorCode;			/* Where to store error code. */
{
#if 0
    MemoryInfo *infoPtr = (MemoryInfo *) instanceData;
    DWORD bytesWritten;
    
    *errorCode = 0;

    /*
     * If we are writing to a memory that was opened with O_APPEND, we need to
     * seek to the end of the memory before writing the current buffer.
     */

    if (infoPtr->flags & FILE_APPEND) {
        SetMemoryPointer(infoPtr->handle, 0, NULL, FILE_END);
    }

    if (WriteMemory(infoPtr->handle, (LPVOID) buf, (DWORD) toWrite, &bytesWritten,
            (LPOVERLAPPED) NULL) == FALSE) {
        TclWinConvertError(GetLastError());
        *errorCode = errno;
        return -1;
    }
    FlushMemoryBuffers(infoPtr->handle);
    return bytesWritten;
#endif
    return toWrite;
}

/*
 *----------------------------------------------------------------------
 *
 * MemoryWatchProc --
 *
 *	Called by the notifier to set up to watch for events on this
 *	channel.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
MemoryWatchProc(instanceData, mask)
    ClientData instanceData;		/* Memory state. */
    int mask;				/* What events to watch for; OR-ed
                                         * combination of TCL_READABLE,
                                         * TCL_WRITABLE and TCL_EXCEPTION. */
{
    MemoryInfo *infoPtr = (MemoryInfo *) instanceData;
    Tcl_Time blockTime = { 0, 0 };

    /*
     * Since the memory is always ready for events, we set the block time
     * to zero so we will poll.
     */

    infoPtr->watchMask = mask & infoPtr->validMask;
    if (infoPtr->watchMask) {
	Tcl_SetMaxBlockTime(&blockTime);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * MemoryGetHandleProc --
 *
 *	Called from Tcl_GetChannelFile to retrieve OS handles from
 *	a file based channel.
 *
 * Results:
 *	Returns TCL_OK with the fd in handlePtr, or TCL_ERROR if
 *	there is no handle for the specified direction. 
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
MemoryGetHandleProc(instanceData, direction, handlePtr)
    ClientData instanceData;	/* The file state. */
    int direction;		/* TCL_READABLE or TCL_WRITABLE */
    ClientData *handlePtr;	/* Where to store the handle.  */
{
    MemoryInfo *infoPtr = (MemoryInfo *) instanceData;

    if (direction & infoPtr->validMask) {
	*handlePtr = (ClientData) infoPtr->memPtr;
	return TCL_OK;
    } else {
	return TCL_ERROR;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TclCreateMemoryChannel --
 *
 *	Opens a memory channel to the memory buffer given by 'memPtr'.
 *	The memory associated with the open channel is freed using the
 *	procedure pointed to by 'freeProcPtr' when the channel is
 *	ultimately closed.
 *
 * Results:
 *	The new channel.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

Tcl_Channel
TclCreateMemoryChannel(interp, memPtr, mode, permissions, memSize, freeProcPtr,
		       encoding)
    Tcl_Interp *interp;			/* Interpreter for error reporting;
                                         * can be NULL. */
    char *memPtr;			/* Name of file to open. */
    int mode;				/* A list of POSIX open modes or
                                         * a string such as "rw". */
    int permissions;			/* Unused at this time. */
    long memSize;			/* The size of the memory block. */
    Tcl_FreeProc *freeProcPtr;		/* Routine to free 'memPtr' when
					   the channel is ultimately closed */
    char *encoding;                     /* encoding to use for the channel */
{
    Tcl_Channel retVal = NULL;
    int channelPermissions = TCL_READABLE;
    Tcl_ChannelType *channelTypePtr;
    MemoryInfo *infoPtr;

    channelTypePtr = &memoryChannelType;

    switch (mode & (O_RDONLY | O_WRONLY | O_RDWR)) {
	case O_RDONLY:
	    channelPermissions = TCL_READABLE;
	    break;
	case O_WRONLY:
	    channelPermissions = TCL_WRITABLE;
	    break;
	case O_RDWR:
	    channelPermissions = (TCL_READABLE | TCL_WRITABLE);
	    break;
	default:
	    panic("TclCreateMemoryChannel: invalid mode value");
	    break;
    }
    if (channelPermissions & TCL_WRITABLE) {
	Tcl_AppendResult(interp, "Wriable memChan not supported", NULL);
	return (Tcl_Channel) NULL;
    }

    infoPtr = (MemoryInfo *) ckalloc((unsigned) sizeof(MemoryInfo));
    infoPtr->nextPtr = firstMemoryPtr;
    firstMemoryPtr = infoPtr;
    infoPtr->watchMask = 0;
    infoPtr->validMask = mode;
    infoPtr->memPtr = memPtr;
    infoPtr->currOffset = 0;
    infoPtr->memFreeProc = freeProcPtr;
    infoPtr->size = memSize;

    sprintf(channelName, "memory%ud", (unsigned int) infoPtr->memPtr);

    infoPtr->channel = Tcl_CreateChannel(channelTypePtr, channelName,
	    (ClientData) infoPtr, channelPermissions);

    /*
     * This is a temporary hack. Should store the encoding in the
     * info file and retrieve it.
     */
    
    Tcl_SetChannelOption(NULL, infoPtr->channel, "-encoding", encoding);

    retVal = infoPtr->channel;

    return retVal;
}

