/*---------------------------------------------------------------------------

  api.c

  This module supplies an UnZip engine for use directly from C/C++
  programs.  The functions are:

    UzpVer *UzpVersion(void);
    int UzpMain(int argc, char *argv[]);
    int UzpAltMain(int argc, char *argv[], UzpInit *init);
    int UzpUnzipToMemory(char *zip, char *file, UzpBuffer *retstr);

    int UzpStat(char* zip, char* file, void* statptr)

  OS/2 only (for now):

    int UzpFileTree(char *name, cbList(callBack), char *cpInclude[],
          char *cpExclude[]);

  You must define `DLL' in order to include the API extensions.

  ---------------------------------------------------------------------------*/


#ifdef OS2
#  define  INCL_DOSMEMMGR
#  include <os2.h>
#endif

#define UNZIP_INTERNAL
#include "unzip.h"
#include "version.h"
#ifdef USE_ZLIB
#  include "zlib.h"
#endif



/*---------------------------------------------------------------------------
    Documented API entry points
  ---------------------------------------------------------------------------*/


UzpVer * UZ_EXP UzpVersion()   /* should be pointer to const struct */
{
    static UzpVer version;     /* doesn't change between calls */


    version.structlen = UZPVER_LEN;

#ifdef BETA
    version.flag = 1;
#else
    version.flag = 0;
#endif
    version.betalevel = BETALEVEL;
    version.date = VERSION_DATE;

#ifdef ZLIB_VERSION
    version.zlib_version = ZLIB_VERSION;
    version.flag |= 2;
#else
    version.zlib_version = NULL;
#endif

    /* someday each of these may have a separate patchlevel: */
    version.unzip.major = UZ_MAJORVER;
    version.unzip.minor = UZ_MINORVER;
    version.unzip.patchlevel = PATCHLEVEL;

    version.zipinfo.major = ZI_MAJORVER;
    version.zipinfo.minor = ZI_MINORVER;
    version.zipinfo.patchlevel = PATCHLEVEL;

    /* these are retained for backward compatibility only: */
    version.os2dll.major = UZ_MAJORVER;
    version.os2dll.minor = UZ_MINORVER;
    version.os2dll.patchlevel = PATCHLEVEL;

    version.windll.major = UZ_MAJORVER;
    version.windll.minor = UZ_MINORVER;
    version.windll.patchlevel = PATCHLEVEL;

    return &version;
}



#ifndef WINDLL

int UZ_EXP UzpAltMain(int argc, char *argv[], UzpInit *init)
{
    int r, (*dummyfn)() = NULL;

    CONSTRUCTGLOBALS();

    if (init->structlen >= (sizeof(ulg) + sizeof(dummyfn)) && init->msgfn)
        G.message = init->msgfn;

    if (init->structlen >= (sizeof(ulg) + 2*sizeof(dummyfn)) && init->inputfn)
        G.input = init->inputfn;

    if (init->structlen >= (sizeof(ulg) + 3*sizeof(dummyfn)) && init->pausefn)
        G.mpause = init->pausefn;

    if (init->structlen >= (sizeof(ulg) + 4*sizeof(dummyfn)) && init->userfn)
        (*init->userfn)();    /* allow void* arg? */

    r = unzip(__G__ argc, argv);
    DESTROYGLOBALS()
    RETURN(r);
}

#endif


int UZ_EXP UzpUnzipToMemory(char *zip,char *file,UzpBuffer *retstr)
{
    int r;

    CONSTRUCTGLOBALS();
    G.redirect_data = 1;
    r = unzipToMemory(__G__ zip,file,retstr)==0;
    DESTROYGLOBALS()
    return r;
}



#ifdef OS2DLL

int UZ_EXP UzpFileTree(char *name, cbList(callBack), char *cpInclude[],
                char *cpExclude[])
{
    int r;

    CONSTRUCTGLOBALS();
    G.qflag = 2;
    G.vflag = 1;
    G.C_flag = 1;
    G.wildzipfn = name;
    G.process_all_files = TRUE;
    if (cpInclude)
        G.pfnames = cpInclude, G.process_all_files = FALSE;
    if (cpExclude)
        G.pxnames = cpExclude, G.process_all_files = FALSE;
  
    G.processExternally = callBack;
    r = process_zipfiles(__G)==0;
    DESTROYGLOBALS()
    return r;
}

#endif /* OS2DLL */


#ifdef UZPFILETREE2

int UZ_EXP UzpFileTree2(char *name, cbList(callBack), char *cpInclude[],
                char *cpExclude[], UzpInit *init)
{
    int r, (*dummyfn)() = NULL;

    CONSTRUCTGLOBALS();
    G.qflag = 2;
    G.vflag = 1;
    G.C_flag = 1;

    if (init->structlen >= (sizeof(ulg) + sizeof(dummyfn)) && init->msgfn)
        G.message = init->msgfn;

    if (init->structlen >= (sizeof(ulg) + 2*sizeof(dummyfn)) && init->inputfn)
        G.input = init->inputfn;

    if (init->structlen >= (sizeof(ulg) + 3*sizeof(dummyfn)) && init->pausefn)
        G.mpause = init->pausefn;

    if (init->structlen >= (sizeof(ulg) + 4*sizeof(dummyfn)) && init->userfn)
        (*init->userfn)();    /* allow void* arg? */

    G.wildzipfn = name;
    G.process_all_files = TRUE;
    G.processExternally = callBack;
    r = process_zipfiles(__G)==0;
    DESTROYGLOBALS();

    return r;
}

#endif /* UZPFILETREE */


int UzpStat(char* zip, const char* file, void* statptr, UzpInit *init)
{
    int r, (*dummyfn)() = NULL;
    char *incname[3];

    CONSTRUCTGLOBALS();
    G.process_all_files = FALSE;
    G.extract_flag = FALSE;
    G.C_flag = 1;
    G.wildzipfn = zip;
    G.stat_flag = 1;
    G.statptr = (void *)statptr;

    G.pfnames = incname;
    incname[0] = (char *)file;
    incname[1] = NULL;
    G.filespecs = 1;

    if (init->structlen >= (sizeof(ulg) + sizeof(dummyfn)) && init->msgfn)
        G.message = init->msgfn;

    if (init->structlen >= (sizeof(ulg) + 2*sizeof(dummyfn)) && init->inputfn)
        G.input = init->inputfn;

    if (init->structlen >= (sizeof(ulg) + 3*sizeof(dummyfn)) && init->pausefn)
        G.mpause = init->pausefn;

    if (init->structlen >= (sizeof(ulg) + 4*sizeof(dummyfn)) && init->userfn)
        (*init->userfn)();    /* allow void* arg? */

    r = process_zipfiles(__G);

    DESTROYGLOBALS()

    return r;
}


int zip_stat(__G)    /* return PK-type error code */
    __GDEF
{
    int error, error_in_archive=PK_COOL;
    int date_format;
    struct stat * statptr = (struct stat *)G.statptr;
#ifdef USE_EF_UT_TIME
    iztimes z_utime;
#endif
    ush j, yr, mo, dy, hh, mm, members=0;
    ulg csiz;
    min_info info;
    static char dtype[]="NXFS";   /* see zi_short() */

    G.pInfo = &info;
    date_format = DATE_FORMAT;

    for (j = 0; j < G.ecrec.total_entries_central_dir; ++j) {
	if (readbuf(__G__ G.sig, 4) == 0)
            return PK_EOF;
        if (strncmp(G.sig, G.central_hdr_sig, 4)) {  /* just to make sure */
            Info(slide, 0x401, ((char *)slide, LoadFarString(CentSigMsg), j));
            Info(slide, 0x401, ((char *)slide, LoadFarString(ReportMsg)));
            return PK_BADERR;
        }
        /* process_cdir_file_hdr() sets pInfo->lcflag: */
        if ((error = process_cdir_file_hdr(__G)) != PK_COOL)
            return error;       /* only PK_EOF defined */

        if ((error = do_string(__G__ G.crec.filename_length, DS_FN)) !=
             PK_COOL)   /*  ^--(uses pInfo->lcflag) */
        {
            error_in_archive = error;
            if (error > PK_WARN)   /* fatal:  can't continue */
                return error;
        }
        if (G.extra_field != (uch *)NULL) {
            free(G.extra_field);
            G.extra_field = (uch *)NULL;
        }
        if ((error = do_string(__G__ G.crec.extra_field_length, EXTRA_FIELD))
            != 0)
        {
            error_in_archive = error;
            if (error > PK_WARN)      /* fatal */
                return error;
        }
if (!members) {
	if (match(G.filename, G.pfnames[0], G.C_flag)) {
members++;
#ifdef USE_EF_UT_TIME
	    if (G.extra_field &&
		(ef_scan_for_izux(G.extra_field, G.crec.extra_field_length, 1,
				  &z_utime, NULL) & EB_UT_FL_MTIME))
	    {
		struct tm *t;

		TIMET_TO_NATIVE(z_utime.mtime)   /* NOP unless MSC 7.0, Mac */
		t = localtime(&(z_utime.mtime));
		switch (date_format) {
		    case DF_YMD:
			mo = (ush)(t->tm_year);
			dy = (ush)(t->tm_mon + 1);
			yr = (ush)(t->tm_mday);
			break;
		    case DF_DMY:
			mo = (ush)(t->tm_mday);
			dy = (ush)(t->tm_mon + 1);
			yr = (ush)(t->tm_year);
			break;
		    default:
			mo = (ush)(t->tm_mon + 1);
			dy = (ush)(t->tm_mday);
			yr = (ush)(t->tm_year);
		}
		hh = (ush)(t->tm_hour);
		mm = (ush)(t->tm_min);
	    } else
#endif /* USE_EF_UT_TIME */
	    {
		yr = (ush)((((G.crec.last_mod_file_date >> 9) & 0x7f) + 80) %
			   (unsigned)100);
		mo = (ush)((G.crec.last_mod_file_date >> 5) & 0x0f);
		dy = (ush)(G.crec.last_mod_file_date & 0x1f);

		/* permute date so it displays according to nat'l convention */
		switch (date_format) {
		    case DF_YMD:
			hh = mo; mo = yr; yr = dy; dy = hh;
			break;
		    case DF_DMY:
			hh = mo; mo = dy; dy = hh;
		}

		hh = (ush)((G.crec.last_mod_file_time >> 11) & 0x1f);
		mm = (ush)((G.crec.last_mod_file_time >> 5) & 0x3f);
	    }

	    csiz = G.crec.csize;
	    if (G.crec.general_purpose_bit_flag & 1)
		csiz -= 12;   /* if encrypted, don't count encryption header */

	    statptr->st_size = G.crec.ucsize;

#if 0 /* THE_INFORMATION_WE_NEED_FOR_STAT */
		Info(slide, 0, ((char *)slide, LoadFarString(LongHdrStats),
		  G.crec.ucsize, methbuf, csiz, cfactorstr, mo, dy,
		  yr, hh, mm, G.crec.crc32, (G.pInfo->lcflag? '^':' ')));
#endif

	    if ((error = do_string(__G__ G.crec.file_comment_length,
				   QCOND? DISPL_8 : SKIP)) != 0)
	    {
		error_in_archive = error;  /* might be just warning */
		if (error > PK_WARN)       /* fatal */
		    return error;
	    }

		/*break;*/       /* found match, so stop looping */
	}

	SKIP_(G.crec.file_comment_length)
    } /* end for-loop (j: files in central directory) */
}
/*---------------------------------------------------------------------------
    Double check that we're back at the end-of-central-directory record.
  ---------------------------------------------------------------------------*/

    if (readbuf(__G__ G.sig, 4) == 0)
        return PK_EOF;
    if (strncmp(G.sig, G.end_central_sig, 4)) {   /* just to make sure again */
        Info(slide, 0x401, ((char *)slide, LoadFarString(EndSigMsg)));
        error_in_archive = PK_WARN;
    }
    if (members == 0 && error_in_archive <= PK_WARN)
        error_in_archive = PK_FIND;

    return error_in_archive;

} /* end function zip_stat() */



/*---------------------------------------------------------------------------
    Helper functions
  ---------------------------------------------------------------------------*/


void setFileNotFound(__G)
    __GDEF
{
    G.filenotfound++;
}



int unzipToMemory(__GPRO__ char *zip, char *file, UzpBuffer *retstr)
{
    int r;
    char *incname[2];

    G.process_all_files = FALSE;
    G.extract_flag = TRUE;
    G.qflag = 2;
    G.C_flag = 1;
    G.wildzipfn = zip;

    G.pfnames = incname;
    incname[0] = file;
    incname[1] = NULL;
    G.filespecs = 1;

    r = process_zipfiles(__G);
    if (retstr) {
        retstr->strptr = (char *)G.redirect_buffer;
        retstr->strlength = G.redirect_size;
    }
    r |= G.filenotfound;
    if (r)
        return r;   /* GRR:  these two lines don't make much sense... */
    return r;
}



int redirect_outfile(__G)
     __GDEF
{
    G.redirect_size = G.lrec.ucsize;
#ifdef OS2
    DosAllocMem((void **)&G.redirect_buffer, G.redirect_size+1,
      PAG_READ|PAG_WRITE|PAG_COMMIT);
    G.redirect_pointer = G.redirect_buffer;
#else
    G.redirect_pointer = G.redirect_buffer = malloc(G.redirect_size+1);
#endif
    if (!G.redirect_buffer)
        return FALSE;
    G.redirect_pointer[G.redirect_size] = 0;
    return TRUE;
}



int writeToMemory(__GPRO__ uch *rawbuf, ulg size)
{
    if (rawbuf != G.redirect_pointer)
        memcpy(G.redirect_pointer,rawbuf,size);
    G.redirect_pointer += size;
    return 0;
}
