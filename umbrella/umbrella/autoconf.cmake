#
# autoconf.cmake  umbrella for autoconf package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  AUTOCONF_BASEURL - base url of autoconf
#  AUTOCONF_URLFILE - tar file within urldir
#  AUTOCONF_URLMD5  - md5 of tar file
#

if (NOT TARGET autoconf)

#
# umbrella option variables
#
umbrella_defineopt (AUTOCONF_BASEURL
    "http://ftp.gnu.org/gnu/autoconf" STRING "base url for autoconf")
umbrella_defineopt (AUTOCONF_URLFILE "autoconf-2.69.tar.gz"
    STRING "autoconf tar file name")
umbrella_defineopt (AUTOCONF_URLMD5 "82d05e03b93e45f5a39b828dc9c6c29b"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (AUTOCONF_DOWNLOAD autoconf ${AUTOCONF_URLFILE}
    URL "${AUTOCONF_BASEURL}/${AUTOCONF_URLFILE}"
    URL_MD5 ${AUTOCONF_URLMD5})
umbrella_patchcheck (AUTOCONF_PATCHCMD autoconf)

#
# create autoconf target
#
ExternalProject_Add (autoconf ${AUTOCONF_DOWNLOAD} ${AUTOCONF_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      UPDATE_COMMAND "")

endif (NOT TARGET autoconf)
