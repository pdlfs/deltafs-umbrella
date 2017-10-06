#
# oprofile.cmake  umbrella for OPROFILE profiler package
# 05-Oct-2017  chuck@ece.cmu.edu
#

#
# this is going to be ugly, as oprofile requires libiberty and libbfd
# from binutils (but we don't want to have install the full binutils).
# so we are going to hack it...
#

#
# config:
#  OPROFILE_REPO - url of git repository
#  OPROFILE_TAG  - tag to checkout of git
#  OPROFILE_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET oprofile)

#
# umbrella option variables
#
umbrella_defineopt (OPROFILE_REPO "https://git.code.sf.net/p/oprofile/oprofile"
                    STRING "OPROFILE GIT repository")
umbrella_defineopt (OPROFILE_TAG "master" STRING "OPROFILE GIT tag")
umbrella_defineopt (OPROFILE_TAR "oprofile-${OPROFILE_TAG}.tar.gz"
                    STRING "OPROFILE cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (OPROFILE_DOWNLOAD oprofile ${OPROFILE_TAR}
                   GIT_REPOSITORY ${OPROFILE_REPO}
                   GIT_TAG ${OPROFILE_TAG})
umbrella_patchcheck (OPROFILE_PATCHCMD oprofile)

#
# this wants popt
#
include (umbrella/popt)

##############################################################################
#
# binutils subset for oprofile
#

umbrella_defineopt (OPBINUTILS_BASEURL
    "http://ftp.gnu.org/gnu/binutils" STRING "base url for binutils")
umbrella_defineopt (OPBINUTILS_URLFILE "binutils-2.29.tar.gz"
    STRING "binutils tar file name")
umbrella_defineopt (OPBINUTILS_URLMD5 "77a8b99de0481589a871062702df4e59"
    STRING "MD5 of tar file")

umbrella_download (OPBINUTILS_DOWNLOAD opbinutils ${OPBINUTILS_URLFILE}
                   URL "${OPBINUTILS_BASEURL}/${OPBINUTILS_URLFILE}"
                   URL_MD5 ${OPBINUTILS_URLMD5})
umbrella_patchcheck (OPBINUTILS_PATCHCMD opbinutils)

# XXX: we just build the .a files, but don't bother installing them
ExternalProject_Add (opbinutils ${OPBINUTILS_DOWNLOAD} ${OPBINUTILS_PATCHCMD}
    CONFIGURE_COMMAND cd <SOURCE_DIR>/libiberty && ./configure
        COMMAND cd <SOURCE_DIR>/bfd && ./configure --disable-shared
    BUILD_COMMAND cd <SOURCE_DIR>/libiberty && make
        COMMAND cd <SOURCE_DIR>/bfd && make
    INSTALL_COMMAND ""
    UPDATE_COMMAND ""
)

# XXX: using this instead of UMBRELLA_CPPFLAGS/UMBRELLA_LDFLAGS
# we need CMAKE_INSTALL_PREFIX for popt lib... that's the other depend
set (OPBINUTILS_COMPDIR "${CMAKE_BINARY_DIR}/opbinutils-prefix/src/opbinutils")
set (OPBINUTILS_CPPFLAGS
    "-I${OPBINUTILS_COMPDIR}/libiberty -I${OPBINUTILS_COMPDIR}/bfd")
set (OPBINUTILS_CPPFLAGS
    "-I${OPBINUTILS_COMPDIR}/include ${OPBINUTILS_CPPFLAGS}")
set (OPBINUTILS_CPPFLAGS
    "-I${CMAKE_INSTALL_PREFIX}/include ${OPBINUTILS_CPPFLAGS}")

set (OPBINUTILS_LDFLAGS
    "-L${OPBINUTILS_COMPDIR}/libiberty -L${OPBINUTILS_COMPDIR}/bfd")
set (OPBINUTILS_LDFLAGS
    "-L${CMAKE_INSTALL_PREFIX}/lib ${OPBINUTILS_LDFLAGS}")
#
##############################################################################

#
# create oprofile target
#
ExternalProject_Add (oprofile DEPENDS popt opbinutils
    ${OPROFILE_DOWNLOAD} ${OPROFILE_PATCHCMD}
    CONFIGURE_COMMAND echo <BINARY_DIR> ${CMAKE_BINARY_DIR}
        COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      CPPFLAGS=${OPBINUTILS_CPPFLAGS}
                      LDFLAGS=${OPBINUTILS_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --disable-shared
    UPDATE_COMMAND "")

#
# add extra autogen prepare step

ExternalProject_Add_Step (oprofile prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET oprofile)
