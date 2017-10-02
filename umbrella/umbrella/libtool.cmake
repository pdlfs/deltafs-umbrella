#
# libtool.cmake  umbrella for libtool package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  LIBTOOL_BASEURL - base url of libtool
#  LIBTOOL_URLFILE - tar file within urldir
#  LIBTOOL_URLMD5  - md5 of tar file
#

if (NOT TARGET libtool)

#
# umbrella option variables
#
umbrella_defineopt (LIBTOOL_BASEURL
    "http://ftp.gnu.org/gnu/libtool" STRING "base url for libtool")
umbrella_defineopt (LIBTOOL_URLFILE "libtool-2.4.6.tar.gz"
    STRING "libtool tar file name")
umbrella_defineopt (LIBTOOL_URLMD5 "addf44b646ddb4e3919805aa88fa7c5e"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (LIBTOOL_DOWNLOAD libtool ${LIBTOOL_URLFILE}
    URL "${LIBTOOL_BASEURL}/${LIBTOOL_URLFILE}"
    URL_MD5 ${LIBTOOL_URLMD5})
umbrella_patchcheck (LIBTOOL_PATCHCMD libtool)

#
# create libtool target
#
ExternalProject_Add (libtool ${LIBTOOL_DOWNLOAD} ${LIBTOOL_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      UPDATE_COMMAND "")

endif (NOT TARGET libtool)
