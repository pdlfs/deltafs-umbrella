#
# deltafs.cmake  umbrella for deltafs filesystem
# 29-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  DELTAFS_REPO - url of git repository
#  DELTAFS_TAG  - tag to checkout of git
#  DELTAFS_TAR  - cache tar file name (default should be ok)
#  PDLFS_OPTIONS       - common pdlfs options
#

if (NOT TARGET deltafs)

#
# umbrella option variables
#
umbrella_defineopt (DELTAFS_REPO "https://github.com/pdlfs/deltafs.git"
     STRING "deltafs GIT repository")
umbrella_defineopt (DELTAFS_TAG "master" STRING "deltafs GIT tag")
umbrella_defineopt (DELTAFS_TAR "deltafs-${DELTAFS_TAG}.tar.gz"
     STRING "deltafs cache tar file")
umbrella_buildtests(deltafs DELTAFS_BUILDTESTS)

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (DELTAFS_DOWNLOAD deltafs ${DELTAFS_TAR}
                   GIT_REPOSITORY ${DELTAFS_REPO}
                   GIT_TAG ${DELTAFS_TAG})
umbrella_patchcheck (DELTAFS_PATCHCMD deltafs)
umbrella_testcommand (deltafs DELTAFS_TESTCMD TEST_COMMAND
      ctest -E "gigaplus_test|autocompact_test|db_test|index_block_test" )

#
# depends
#
include (umbrella/mercury)
include (umbrella/deltafs-common)

#
# create deltafs target
#
ExternalProject_Add (deltafs DEPENDS mercury deltafs-common
    ${DELTAFS_DOWNLOAD} ${DELTAFS_PATCHCMD}
    CMAKE_ARGS ${PDLFS_OPTIONS} -DBUILD_SHARED_LIBS=ON
        -DBUILD_TESTS=${DELTAFS_BUILDTESTS}
        -DDELTAFS_COMMON_INTREE=OFF
        -DMPI_CXX_COMPILER=${MPI_CXX_COMPILER}
        -DMPI_C_COMPILER=${MPI_C_COMPILER}
        -DDELTAFS_MPI:BOOL=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
    ${DELTAFS_TESTCMD}
)

endif (NOT TARGET deltafs)
