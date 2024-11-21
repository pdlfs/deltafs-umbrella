#
# pdlfs-common.cmake  umbrella for pdlfs-common
# 25-Mar-2024  chuck@ece.cmu.edu
#

#
# config:
#  PDLFS_COMMON_REPO - url of git repository
#  PDLFS_COMMON_TAG  - tag to checkout of git
#  PDLFS_COMMON_TAR  - cache tar file name (default should be ok)
#  PDLFS_OPTIONS     - common pdlfs options
#

if (NOT TARGET pdlfs-common)

#
# umbrella option variables
#
umbrella_defineopt (PDLFS_COMMON_REPO
     "https://github.com/pdlfs/pdlfs-common.git"
     STRING "pdlfs-common GIT repository")
umbrella_defineopt (PDLFS_COMMON_TAG "master" STRING "pdlfs-common GIT tag")
umbrella_defineopt (PDLFS_COMMON_TAR
     "pdlfs-common-${PDLFS_COMMON_TAG}.tar.gz"
     STRING "pdlfs-common cache tar file")
umbrella_buildtests(pdlfs-common PDLFS_COMMON_BUILDTESTS)


#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (PDLFS_COMMON_DOWNLOAD pdlfs-common ${PDLFS_COMMON_TAR}
                   GIT_REPOSITORY ${PDLFS_COMMON_REPO}
                   GIT_TAG ${PDLFS_COMMON_TAG})
umbrella_patchcheck (PDLFS_COMMON_PATCHCMD pdlfs-common)
umbrella_testcommand (pdlfs-common PDLFS_COMMON_TESTCMD
      ctest -E "gigaplus_test|autocompact_test|db_test|index_block_test" )

#
# depends
#
set(PDLFS_COMMON_DEPENDS )

# check if list PDLFS_OPTIONS has value -DABCD=ON
# XXX: assumes using 'ON' (e.g. vs '1')
if (DEFINED PDLFS_OPTIONS)

  list (FIND PDLFS_OPTIONS "-DPDLFS_GFLAGS=ON" PDLFS_USE_GFLAGS)
  if (PDLFS_USE_GFLAGS GREATER -1)
    include (umbrella/gflags)
    list(APPEND PDLFS_COMMON_DEPENDS gflags)
  endif (PDLFS_USE_GFLAGS GREATER -1)

  list (FIND PDLFS_OPTIONS "-DPDLFS_GLOG=ON" PDLFS_USE_GLOG)
  if (PDLFS_USE_GLOG GREATER -1)
    include (umbrella/glog)
    list(APPEND PDLFS_COMMON_DEPENDS glog)
  endif (PDLFS_USE_GLOG GREATER -1)

  list (FIND PDLFS_OPTIONS "-DPDLFS_MERCURY_RPC=ON" PDLFS_USE_MERCURY)
  if (PDLFS_USE_MERCURY GREATER -1)
    include (umbrella/mercury)
    list(APPEND PDLFS_COMMON_DEPENDS mercury)
  endif (PDLFS_USE_MERCURY GREATER -1)

  list (FIND PDLFS_OPTIONS "-DPDLFS_SNAPPY=ON" PDLFS_USE_SNAPPY)
  if (PDLFS_USE_SNAPPY GREATER -1)
    include (umbrella/snappy)
    list(APPEND PDLFS_COMMON_DEPENDS snappy)
  endif (PDLFS_USE_SNAPPY GREATER -1)

endif (DEFINED PDLFS_OPTIONS)

#
# create pdlfs-common target
#
ExternalProject_Add (pdlfs-common
    DEPENDS ${PDLFS_COMMON_DEPENDS}
    ${PDLFS_COMMON_DOWNLOAD} ${PDLFS_COMMON_PATCHCMD}
    CMAKE_ARGS ${PDLFS_OPTIONS} -DBUILD_SHARED_LIBS=ON
        -DBUILD_TESTS=${PDLFS_COMMON_BUILDTESTS}
        -DPDLFS_COMMON_LIBNAME=pdlfs-common
        -DPDLFS_COMMON_DEFINES=PDLFS
        -DPDLFS_DFS_COMMON=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
    ${PDLFS_COMMON_TESTCMD}
)

endif (NOT TARGET pdlfs-common)
