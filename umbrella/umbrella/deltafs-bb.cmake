#
# deltafs-bb.cmake  umbrella for deltafs burst buffer object store
# 29-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  DELTAFS_BB_REPO - url of git repository
#  DELTAFS_BB_TAG  - tag to checkout of git
#  DELTAFS_BB_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET deltafs-bb)

#
# umbrella option variables
#
umbrella_defineopt (DELTAFS_BB_REPO "https://github.com/pdlfs/deltafs-bb.git"
     STRING "deltafs-bb GIT repository")
umbrella_defineopt (DELTAFS_BB_TAG "master" STRING "deltafs-bb GIT tag")
umbrella_defineopt (DELTAFS_BB_TAR "deltafs-bb-${DELTAFS_BB_TAG}.tar.gz"
     STRING "deltafs-bb cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (DELTAFS_BB_DOWNLOAD deltafs-bb ${DELTAFS_BB_TAR}
                   GIT_REPOSITORY ${DELTAFS_BB_REPO}
                   GIT_TAG ${DELTAFS_BB_TAG})
umbrella_patchcheck (DELTAFS_BB_PATCHCMD deltafs-bb)

#
# depends
#
include (umbrella/mercury)

#
# create deltafs-bb target
#
ExternalProject_Add (deltafs-bb DEPENDS mercury
    ${DELTAFS_BB_DOWNLOAD} ${DELTAFS_BB_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET deltafs-bb)
