#
# mvapich.cmake  umbrella for mvapich package
# 30-Jul-2020  chuck@ece.cmu.edu
#

#
# config:
#  MVAPICH_BASEURL - base url of mvapich
#  MVAPICH_URLDIR  - subdir in base where it lives
#  MVAPICH_URLFILE - tar file within urldir
#  MVAPICH_URLMD5  - md5 of tar file
#
#  MVAPICH_DEVICE - optional --with-device option
#

if (NOT TARGET mvapich)

#
# umbrella option variables
#
umbrella_defineopt (MVAPICH_BASEURL
    "http://mvapich.cse.ohio-state.edu/download/mvapich"
    STRING "base url for mvapich")
umbrella_defineopt (MVAPICH_URLDIR "mv2" STRING "mvapich subdir")
umbrella_defineopt (MVAPICH_URLFILE "mvapich2-2.3.4.tar.gz"
    STRING "mvapich tar file name")
umbrella_defineopt (MVAPICH_URLMD5 "5010211c7aa6349e6308593145763d9f"
    STRING "MD5 of tar file")
#
# XXX: default dev is ch3:mrail
umbrella_defineopt(MVAPICH_DEVICE "" STRING "--with-device option")

#
# local vars
#
unset(mvapich_withdev)
unset(mvapich_xtradeps)

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (MVAPICH_DOWNLOAD mvapich ${MVAPICH_URLFILE}
    URL "${MVAPICH_BASEURL}/${MVAPICH_URLDIR}/${MVAPICH_URLFILE}"
    URL_MD5 ${MVAPICH_URLMD5})
umbrella_patchcheck (MVAPICH_PATCHCMD mvapich)

#
# depends
#
# XXX: required?  (yes by default, maybe not for ch3:psm?)
include (umbrella/rdma-core)

#
# device options
#
if ("${MVAPICH_DEVICE}" STREQUAL "")
    message(STATUS "  MVAPICH default device selected")
elseif ("${MVAPICH_DEVICE}" STREQUAL "ch3:psm" OR
    "${MVAPICH_DEVICE}" STREQUAL "psm")
    message(STATUS "  MVAPICH psm device selected")
    include (umbrella/psm)
    set (mvapich_xtradeps "psm")
    set (mvapich_withdev "--with-device=ch3:psm")
else ()
     message(FATAL_ERROR "MVAPICH unknown device ${MVAPICH_DEVICE}")
endif ()

#
# create mvapich target
#
ExternalProject_Add (mvapich DEPENDS rdma-core ${mvapich_xtradeps}
    ${MVAPICH_DOWNLOAD} ${MVAPICH_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      ${mvapich_withdev}
                      BUILD_IN_SOURCE 1  # XXX: bug. fails w/o this.
                      UPDATE_COMMAND "")

endif (NOT TARGET mvapich)
