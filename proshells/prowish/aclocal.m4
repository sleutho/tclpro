builtin(include,../config/tcl.m4)

#------------------------------------------------------------------------
# SC_LIB_SPEC_SUFFIX --
#
#	Compute the name of an existing object library located in libdir
#	from the given base name and produce the appropriate linker flags.
#       Adds the suffix to the end of the name, after the version number,
#       before the extension (.lib, .so, etc.).
#
# Arguments:
#	basename	The base name of the library without version
#			numbers, extensions, or "lib" prefixes.
#       suffix          A suffix tacked onto the end of the lib name,
#                       usually "", "d", "s", "sd", "x", or "xd".
#	extra_dir	Extra directory in which to search for the
#			library.  This location is used first, then
#			$prefix/$exec-prefix, then some defaults.
#
# Requires:
#	CYGPATH		command used to generate native style paths
#
# Results:
#
#	Defines the following vars:
#		${basename}_LIB_NAME	The computed library name.
#		${basename}_LIB_SPEC_SUFFIX	The computed linker flags.
#------------------------------------------------------------------------

AC_DEFUN(SC_LIB_SPEC_SUFFIX, [
    AC_MSG_CHECKING(for $1 library)

    # Look in exec-prefix and prefix for the library.  If neither of
    # these were specified, look in libdir.  It doesn't matter if libdir
    # wasn't specified since a search in the unspecified directory will
    # fail (NONE/lib)

    if test x"${exec_prefix}" != x"NONE" ; then
	sc_lib_name_dir="${exec_prefix}/lib"
    elif test x"${prefix}" != "NONE" ; then
	sc_lib_name_dir="${prefix}/lib"
    else
	eval "sc_lib_name_dir=${libdir}"
    fi

    if test x"$3" != x ; then
	sc_extra_lib_dir=$3
    else
	sc_extra_lib_dir=NONE
    fi

    for i in \
	    `ls -dr ${sc_extra_lib_dir}/$1[[0-9]]*$2.lib 2>/dev/null ` \
	    `ls -dr ${sc_extra_lib_dir}/$1$2.lib 2>/dev/null ` \
	    `ls -dr ${sc_extra_lib_dir}/lib$1[[0-9]]*$2* 2>/dev/null ` \
	    `ls -dr ${sc_extra_lib_dir}/lib$1$2.* 2>/dev/null ` \
	    `ls -dr ${sc_lib_name_dir}/$1[[0-9]]*$2.lib 2>/dev/null ` \
	    `ls -dr ${sc_lib_name_dir}/$1$2.lib 2>/dev/null ` \
	    `ls -dr ${sc_lib_name_dir}/lib$1[[0-9]]*$2* 2>/dev/null ` \
	    `ls -dr ${sc_lib_name_dir}/lib$1$2.* 2>/dev/null ` \
	    `ls -dr /usr/lib/$1[[0-9]]*$2.lib 2>/dev/null ` \
	    `ls -dr /usr/lib/$1$2.lib 2>/dev/null ` \
	    `ls -dr /usr/lib/lib$1[[0-9]]*$2* 2>/dev/null ` \
	    `ls -dr /usr/lib/lib$1$2.* 2>/dev/null ` \
	    `ls -dr /usr/local/lib/$1[[0-9]]*$2.lib 2>/dev/null ` \
	    `ls -dr /usr/local/lib/$1$2.lib 2>/dev/null ` \
	    `ls -dr /usr/local/lib/lib$1[[0-9]]*$2* 2>/dev/null ` \
	    `ls -dr /usr/local/lib/lib$1$2.* 2>/dev/null ` ; do
	if test -f "$i" ; then

	    sc_lib_name_dir=`dirname $i`
	    $1_LIB_NAME=`basename $i`
	    $1_LIB_PATH_NAME=$i
	    break
	fi
    done

    case "`uname -s`" in
	*win32* | *WIN32* | *CYGWIN_NT* |*CYGWIN_98*|*CYGWIN_95*)
	    if test "x${$1_LIB_PATH_NAME}" = x
	    then
		$1_LIB_SPEC=\"\"
	    else
		$1_LIB_SPEC=\"`${CYGPATH} ${$1_LIB_PATH_NAME}`\"
	    fi
	    ;;
	*)
	    # Strip off the leading "lib" and trailing ".a" or ".so"

	    sc_lib_name_lib=`echo ${$1_LIB_NAME}|sed -e 's/^lib//' -e 's/\.[[^.]]*$//' -e 's/\.so.*//'`
	    $1_LIB_SPEC="-L${sc_lib_name_dir} -l${sc_lib_name_lib}"
	    ;;
    esac

    if test "x${$1_LIB_NAME}" = x ; then
	AC_MSG_ERROR(not found)
    else
	AC_MSG_RESULT(${$1_LIB_SPEC})
    fi
])

