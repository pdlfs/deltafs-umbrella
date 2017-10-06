#
# popt.cmake  umbrella for popt comand line parsing package
# 05-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  POPT_BASEURL - base url of popt
#  POPT_URLFILE - tar file within baseurl (e.g popt-1.16.tar.gz)
#  POPT_URLMD5  - md5 of tar file
#

if (NOT TARGET popt)

#
# umbrella option variables
#
umbrella_defineopt (POPT_BASEURL
    "http://rpm5.org/files/popt" STRING "base url for util-linux")
umbrella_defineopt (POPT_URLFILE "popt-1.16.tar.gz"
    STRING "popt tar file name")
umbrella_defineopt (POPT_URLMD5 "3743beefa3dd6247a73f8f7a32c14c33"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (POPT_DOWNLOAD popt ${POPT_URLFILE}
    URL "${POPT_BASEURL}/${POPT_URLFILE}"
    URL_MD5 ${POPT_URLMD5})
umbrella_patchcheck (POPT_PATCHCMD popt)

#
# create popt target
#
ExternalProject_Add (popt ${POPT_DOWNLOAD} ${POPT_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      UPDATE_COMMAND "")

endif (NOT TARGET popt)
