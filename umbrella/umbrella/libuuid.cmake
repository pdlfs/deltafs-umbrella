#
# libuuid.cmake  umbrella for libuuid package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  LIBUUID_BASEURL - base url of util-linux
#  LIBUUID_URLDIR  - subdir in base where util-linux lives (e.g. v2.28)
#  LIBUUID_URLFILE - tar file within urldir (e.g util-linux-2.28.2.tar.gz)
#  LIBUUID_URLMD5  - md5 of tar file
#

if (NOT TARGET libuuid)

#
# umbrella option variables
#
umbrella_defineopt (LIBUUID_BASEURL
    "https://www.kernel.org/pub/linux/utils/util-linux" STRING 
    "base url for util-linux")
umbrella_defineopt (LIBUUID_URLDIR "v2.30" STRING "util-linux subdir")
umbrella_defineopt (LIBUUID_URLFILE "util-linux-2.30.2.tar.gz"
    STRING "util-linux tar file name")
umbrella_defineopt (LIBUUID_URLMD5 "c33268ece95a8f3924d417b7d266a294"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (LIBUUID_DOWNLOAD libuuid ${LIBUUID_URLFILE}
    URL "${LIBUUID_BASEURL}/${LIBUUID_URLDIR}/${LIBUUID_URLFILE}"
    URL_MD5 ${LIBUUID_URLMD5})
umbrella_patchcheck (LIBUUID_PATCHCMD libuuid)

#
# create libuuid target
#
ExternalProject_Add (libuuid ${LIBUUID_DOWNLOAD} ${LIBUUID_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --without-ncurses --disable-all-programs --enable-libuuid
                      --disable-bash-completion --disable-colors-default 
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      UPDATE_COMMAND "")

endif (NOT TARGET libuuid)
