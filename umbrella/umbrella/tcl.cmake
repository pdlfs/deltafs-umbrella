#
# tcl.cmake  umbrella for tcl package
# 04-Aug-2020  chuck@ece.cmu.edu
#

#
# config:
#  TCL_BASEURL - base url of tcl
#  TCL_URLFILE - tar file within urldir
#  TCL_URLMD5  - md5 of tar file
#

if (NOT TARGET tcl)

#
# umbrella option variables
#
umbrella_defineopt (TCL_BASEURL
    "https://prdownloads.sourceforge.net/tcl" STRING "base url for tcl")
umbrella_defineopt (TCL_URLFILE "tcl8.6.10-src.tar.gz"
    STRING "tcl tar file name")
umbrella_defineopt (TCL_URLMD5 "97c55573f8520bcab74e21bfd8d0aadc"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (TCL_DOWNLOAD tcl ${TCL_URLFILE}
    URL "${TCL_BASEURL}/${TCL_URLDIR}/${TCL_URLFILE}"
    URL_MD5 ${TCL_URLMD5})
umbrella_patchcheck (TCL_PATCHCMD tcl)

#
# create tcl target
#
ExternalProject_Add (tcl DEPENDS opensm rdma-core
    ${TCL_DOWNLOAD} ${TCL_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/unix/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
                      UPDATE_COMMAND "")

endif (NOT TARGET tcl)
