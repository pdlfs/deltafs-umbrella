#
# libev.cmake  umbrella for libev package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  LIBEV_BASEURL - base url of libev
#  LIBEV_URLDIR  - subdir in base where libev lives
#  LIBEV_URLFILE - tar file within urldir
#  LIBEV_URLMD5  - md5 of tar file
#

if (NOT TARGET libev)

#
# umbrella option variables
#
umbrella_defineopt (LIBEV_BASEURL
    "http://dist.schmorp.de" STRING "base url for libev")
umbrella_defineopt (LIBEV_URLDIR "libev/Attic" STRING "libev subdir")
umbrella_defineopt (LIBEV_URLFILE "libev-4.24.tar.gz"
    STRING "libev tar file name")
umbrella_defineopt (LIBEV_URLMD5 "94459a5a22db041dec6f98424d6efe54"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (LIBEV_DOWNLOAD libev ${LIBEV_URLFILE}
    URL "${LIBEV_BASEURL}/${LIBEV_URLDIR}/${LIBEV_URLFILE}"
    URL_MD5 ${LIBEV_URLMD5})
umbrella_patchcheck (LIBEV_PATCHCMD libev)

#
# create libev target
#
ExternalProject_Add (libev ${LIBEV_DOWNLOAD} ${LIBEV_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      UPDATE_COMMAND "")

endif (NOT TARGET libev)
