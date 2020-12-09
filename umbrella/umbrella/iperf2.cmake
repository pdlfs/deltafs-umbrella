#
# iperf2.cmake  umbrella for iperf2 package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  IPERF2_BASEURL - base url of iperf2
#  IPERF2_URLFILE - tar file within basedir
#  IPERF2_URLMD5  - md5 of tar file
#

if (NOT TARGET iperf2)

#
# umbrella option variables
#
umbrella_defineopt (IPERF2_BASEURL
    "http://downloads.sourceforge.net/sourceforge/iperf2"
    STRING "base url for iperf2")
umbrella_defineopt (IPERF2_URLFILE "iperf-2.0.13.tar.gz"
    STRING "iperf2 tar file name")
umbrella_defineopt (IPERF2_URLMD5 "31ea1c6d5cbf80b16ff3abe4288dad5e"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (IPERF2_DOWNLOAD iperf2 ${IPERF2_URLFILE}
    URL "${IPERF2_BASEURL}/${IPERF2_URLFILE}"
    URL_MD5 ${IPERF2_URLMD5})
umbrella_patchcheck (IPERF2_PATCHCMD iperf2)

#
# create iperf2 target -- this is fairly customized for our usage
#
ExternalProject_Add (iperf2 ${IPERF2_DOWNLOAD} ${IPERF2_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
                      UPDATE_COMMAND "")

endif (NOT TARGET iperf2)
