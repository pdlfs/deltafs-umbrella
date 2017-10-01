#
# deltafs-common.cmake  umbrella for pdlfs-common config'd as deltafs-common
# 29-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  DELTAFS_COMMON_REPO - url of git repository
#  DELTAFS_COMMON_TAG  - tag to checkout of git
#  DELTAFS_COMMON_TAR  - cache tar file name (default should be ok)
#  PDLFS_OPTIONS       - common pdlfs options
#

if (NOT TARGET deltafs-common)

#
# umbrella option variables
#
umbrella_defineopt (DELTAFS_COMMON_REPO
     "https://github.com/pdlfs/pdlfs-common.git"
     STRING "deltafs-common GIT repository")
umbrella_defineopt (DELTAFS_COMMON_TAG "master" STRING "deltafs-common GIT tag")
umbrella_defineopt (DELTAFS_COMMON_TAR
     "deltafs-common-${DELTAFS_COMMON_TAG}.tar.gz"
     STRING "deltafs-common cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (DELTAFS_COMMON_DOWNLOAD deltafs-common ${DELTAFS_COMMON_TAR}
                   GIT_REPOSITORY ${DELTAFS_COMMON_REPO}
                   GIT_TAG ${DELTAFS_COMMON_TAG})
umbrella_patchcheck (DELTAFS_COMMON_PATCHCMD deltafs-common)
umbrella_testcommand (DELTAFS_COMMON_TESTCMD TEST_COMMAND
      ctest -E "gigaplus_test|autocompact_test|db_test|index_block_test" )

#
# depends
#
include (umbrella/mercury)

#
# create deltafs-common target
#
ExternalProject_Add (deltafs-common DEPENDS mercury
    ${DELTAFS_COMMON_DOWNLOAD} ${DELTAFS_COMMON_PATCHCMD}
    CMAKE_ARGS ${PDLFS_OPTIONS} -DBUILD_SHARED_LIBS=ON
        -DBUILD_TESTS=${UMBRELLA_BUILD_TESTS}
        -DPDLFS_COMMON_LIBNAME=deltafs-common
        -DPDLFS_COMMON_DEFINES=DELTAFS
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
    ${DELTAFS_COMMON_TESTCMD}
)

endif (NOT TARGET deltafs-common)
