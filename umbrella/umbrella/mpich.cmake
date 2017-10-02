#
# mpich.cmake  umbrella for mpich package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  MPICH_BASEURL - base url of mpich
#  MPICH_URLDIR  - subdir in base where util-linux lives
#  MPICH_URLFILE - tar file within urldir
#  MPICH_URLMD5  - md5 of tar file
#

if (NOT TARGET mpich)

#
# umbrella option variables
#
umbrella_defineopt (MPICH_BASEURL
    "http://www.mpich.org/static/downloads" STRING "base url for mpich")
umbrella_defineopt (MPICH_URLDIR "3.2" STRING "mpich subdir")
umbrella_defineopt (MPICH_URLFILE "mpich-3.2.tar.gz"
    STRING "mpich tar file name")
umbrella_defineopt (MPICH_URLMD5 "f414cfa77099cd1fa1a5ae4e22db508a"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (MPICH_DOWNLOAD mpich ${MPICH_URLFILE}
    URL "${MPICH_BASEURL}/${MPICH_URLDIR}/${MPICH_URLFILE}"
    URL_MD5 ${MPICH_URLMD5})
umbrella_patchcheck (MPICH_PATCHCMD mpich)

#
# create mpich target
#
ExternalProject_Add (mpich ${MPICH_DOWNLOAD} ${MPICH_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --disable-fortran
                      UPDATE_COMMAND "")

endif (NOT TARGET mpich)
