#
# deltafs-nexus.cmake  umbrella for deltafs-nexus routing/addr lib
# 29-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  DELTAFS_NEXUS_REPO - url of git repository
#  DELTAFS_NEXUS_TAG  - tag to checkout of git
#  DELTAFS_NEXUS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET deltafs-nexus)

#
# umbrella option variables
#
umbrella_defineopt (DELTAFS_NEXUS_REPO
    "https://github.com/pdlfs/deltafs-nexus.git"
     STRING "deltafs-nexus GIT repository")
umbrella_defineopt (DELTAFS_NEXUS_TAG "master" STRING "deltafs-nexus GIT tag")
umbrella_defineopt (DELTAFS_NEXUS_TAR
     "deltafs-nexus-${DELTAFS_NEXUS_TAG}.tar.gz"
     STRING "deltafs-nexus cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (DELTAFS_NEXUS_DOWNLOAD deltafs-nexus ${DELTAFS_NEXUS_TAR}
                   GIT_REPOSITORY ${DELTAFS_NEXUS_REPO}
                   GIT_TAG ${DELTAFS_NEXUS_TAG})
umbrella_patchcheck (DELTAFS_NEXUS_PATCHCMD deltafs-nexus)
umbrella_testcommand (DELTAFS_NEXUS_TESTCMD
    ### TEST_COMMAND "ctest -R nexus -V"
    TEST_COMMAND "" )

#
# depends
#
include (umbrella/mercury)

#
# create deltafs-nexus target
#
ExternalProject_Add (deltafs-nexus DEPENDS mercury
    ${DELTAFS_NEXUS_DOWNLOAD} ${DELTAFS_NEXUS_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
    ${DELTAFS_NEXUS_TESTCMD}
)

endif (NOT TARGET deltafs-nexus)
