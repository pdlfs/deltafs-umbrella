#
# libzmq3x.cmake  umbrella for libzmq3x package
# 08-Oct-2017  chuck@ece.cmu.edu
#

# libzmq.cmake has the newer version (v4), this is the old version

#
# config:
#  LIBZMQ3X_BASEURL - base url of libzmq3x
#  LIBZMQ3X_URLDIR  - subdir in base where libzmq3x lives (e.g. v3.2.5)
#  LIBZMQ3X_URLFILE - tar file within urldir (e.g zeromq-3.2.5.tar.gz)
#  LIBZMQ3X_URLMD5  - md5 of tar file
#

if (NOT TARGET libzmq3x)

#
# umbrella option variables
#
umbrella_defineopt (LIBZMQ3X_BASEURL
    "https://github.com/zeromq/zeromq3-x/releases/download" STRING
    "base url for libzmq3x")
umbrella_defineopt (LIBZMQ3X_URLDIR "v3.2.5" STRING "libzmq3x subdir")
umbrella_defineopt (LIBZMQ3X_URLFILE "zeromq-3.2.5.tar.gz"
    STRING "libzmq3x tar file name")
umbrella_defineopt (LIBZMQ3X_URLMD5 "d4189c152fbdc45b376a30bd643f67fd"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (LIBZMQ3X_DOWNLOAD libzmq3x ${LIBZMQ3X_URLFILE}
    URL "${LIBZMQ3X_BASEURL}/${LIBZMQ3X_URLDIR}/${LIBZMQ3X_URLFILE}"
    URL_MD5 ${LIBZMQ3X_URLMD5})
umbrella_patchcheck (LIBZMQ3X_PATCHCMD libzmq3x)

#
# create libzmq3x target
#
ExternalProject_Add (libzmq3x ${LIBZMQ3X_DOWNLOAD} ${LIBZMQ3X_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      UPDATE_COMMAND "")

endif (NOT TARGET libzmq3x)
