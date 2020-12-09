#
# ibutils.cmake  umbrella for ibutils package
# 04-Aug-2020  chuck@ece.cmu.edu
#

# XXX: not complete...  requires both tk and tcl. tk requires X11.
# assumes you've got tk already installed.

#
# config:
#  IBUTILS_BASEURL - base url of ibutils
#  IBUTILS_URLFILE - tar file within urldir
#  IBUTILS_URLMD5  - md5 of tar file
#

if (NOT TARGET ibutils)

#
# umbrella option variables
#
umbrella_defineopt (IBUTILS_BASEURL
    "https://www.openfabrics.org/downloads/ibutils"
    STRING "base url for ibutils")
umbrella_defineopt (IBUTILS_URLFILE "ibutils-1.5.7-0.2.gbd7e502.tar.gz"
    STRING "ibutils tar file name")
umbrella_defineopt (IBUTILS_URLMD5 "8c296a4262a91078d61f20dc58adee9d"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (IBUTILS_DOWNLOAD ibutils ${IBUTILS_URLFILE}
    URL "${IBUTILS_BASEURL}/${IBUTILS_URLFILE}"
    URL_MD5 ${IBUTILS_URLMD5})
umbrella_patchcheck (IBUTILS_PATCHCMD ibutils)

#
# depends
#
include (umbrella/opensm)
include (umbrella/rdma-core)
include (umbrella/tcl)

#
# create ibutils target
#
ExternalProject_Add (ibutils DEPENDS opensm rdma-core tcl
    ${IBUTILS_DOWNLOAD} ${IBUTILS_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --with-osm=${CMAKE_INSTALL_PREFIX}
                      --with-tclconfig=${CMAKE_INSTALL_PREFIX}/lib
                      UPDATE_COMMAND "")

endif (NOT TARGET ibutils)
