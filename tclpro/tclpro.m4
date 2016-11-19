#------------------------------------------------------------------------
# SC_FIND_PROWRAP
#	Locate prowrap in the tools directory
#
# Arguments
#	none
#
# Results
#	Subst's the following values:
#		PROWRAP_TOOL
#------------------------------------------------------------------------

AC_DEFUN(SC_FIND_PROWRAP, [
    AC_MSG_CHECKING(for prowrap)

    if test x"${PLATFORM}" = x ; then
        SC_SET_PLATFORM
    fi

    for cmd in `ls -r ${MODULE_DIR_tools}/${PLATFORM}/bin/prowrap* 2>/dev/null` ; do
	if test -f ${cmd} ; then
	    PROWRAP_TOOL=${cmd}
	    break
	fi
    done

    if test x"${PROWRAP_TOOL}" = x ; then
	AC_MSG_ERROR("Could not find prowrap in tools directory ${MODULE_DIR_tools}/${PLATFORM}/bin/")
    fi
    AC_SUBST(PROWRAP_TOOL)
    AC_MSG_RESULT(${PROWRAP_TOOL})
])

#------------------------------------------------------------------------
# SC_SET_BUILDFLAVOR
#	Set the directory used for building
#
# Arguments
#	none
#
# Results
#	Subst's the following values:
#		build_prefix
#------------------------------------------------------------------------

AC_DEFUN(SC_SET_BUILDFLAVOR, [
    AC_ARG_WITH(flavor, [  --with-flavor             type of build to perform (Release or Debug)], build_flavor=${withval}, build_flavor=Debug)

    case ${build_flavor} in
	Release) ;;
	Debug)   ;;
	*)
	    AC_MSG_ERROR("Invalid build flavor \'${build_flavor}\'.  Must be one of Debug or Release")
	    ;;
    esac

    AC_SUBST(build_flavor)
])

#------------------------------------------------------------------------
# SC_SET_BUILDPREFIX
#	Set the directory used for building
#
# Arguments
#	none
#
# Results
#	Subst's the following values:
#		build_prefix
#------------------------------------------------------------------------

AC_DEFUN(SC_SET_BUILDPREFIX, [
    AC_ARG_WITH(build-prefix, [  --with-build-prefix             directory in which to put the temporary build files], build_prefix=${withval}, build_prefix=`pwd`/build/${PLATFORM})

    build_prefix=`${CYGPATH} ${build_prefix}`
    AC_SUBST(build_prefix)
])
