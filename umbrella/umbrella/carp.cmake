#
# carp.cmake  umbrella for carp
# 17-Feb-2022  chuck@ece.cmu.edu
#

#
# config:
#  CARP_REPO - url of git repository
#  CARP_TAG  - tag to checkout of git
#  CARP_TAR  - cache tar file name (default should be ok)
#  CARP_H5PART - build H5Part-based vpicwriter_runner tool
#  CARP_PARALLEL_SORT - enable/disable parallel sort
#

if (NOT TARGET carp)

#
# umbrella option variables
#
umbrella_defineopt (CARP_REPO "https://github.com/pdlfs/carp.git"
                    STRING "carp GIT repository")
umbrella_defineopt (CARP_TAG "master"
                    STRING "carp GIT tag")
umbrella_defineopt (CARP_TAR "carp-${CARP_TAG}.tar.gz"
                    STRING "carp cache tar file")
umbrella_defineopt (CARP_H5PART "OFF"
                    BOOL "build H5Part-based vpicwriter_runner tool")
umbrella_defineopt (CARP_PARALLEL_SORT "ON" 
                    BOOL "Use parallel sort")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (CARP_DOWNLOAD carp
                   ${CARP_TAR}
                   GIT_REPOSITORY ${CARP_REPO}
                   GIT_TAG ${CARP_TAG})
umbrella_patchcheck (CARP_PATCHCMD carp)

#
# depends
#
set (CARP_DEPENDS deltafs)

include (umbrella/deltafs)
if (CARP_H5PART)
    umbrella_opt_default (HDF5_ENABLE_PARALLEL ON)
    if (NOT HDF5_ENABLE_PARALLEL)
        message(FATAL_ERROR "CARP_H5PART: requires HDF5_ENABLE_PARALLEL=ON")
    endif()
    include (umbrella/h5part)
    list (APPEND CARP_DEPENDS h5part)
endif()
if (CARP_PARALLEL_SORT)
    include (umbrella/onetbb)
    list (APPEND CARP_DEPENDS onetbb)
endif()

#
# create carp target
#
ExternalProject_Add (carp DEPENDS ${CARP_DEPENDS}
    ${CARP_DOWNLOAD} ${CARP_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
               -DCARP_H5PART=${CARP_H5PART}
               -DCARP_PARALLEL_SORT=${CARP_PARALLEL_SORT}
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET carp)
