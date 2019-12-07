#
# deltafs-shuffle.cmake  umbrella for deltafs-shuffle 3 hop shuffle
# 06-Dec-2019  chuck@ece.cmu.edu
#

#
# config:
#  DELTAFS_SHUFFLE_REPO - url of git repository
#  DELTAFS_SHUFFLE_TAG  - tag to checkout of git
#  DELTAFS_SHUFFLE_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET deltafs-shuffle)

#
# umbrella option variables
#
umbrella_defineopt (DELTAFS_SHUFFLE_REPO
     "https://github.com/pdlfs/deltafs-shuffle.git"
     STRING "deltafs-shuffle GIT repository")
umbrella_defineopt (DELTAFS_SHUFFLE_TAG "master"
                    STRING "deltafs-shuffle GIT tag")
umbrella_defineopt (DELTAFS_SHUFFLE_TAR 
     "deltafs-shuffle-${DELTAFS_SHUFFLE_TAG}.tar.gz"
     STRING "deltafs-shuffle cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (DELTAFS_SHUFFLE_DOWNLOAD deltafs-shuffle
                   ${DELTAFS_SHUFFLE_TAR}
                   GIT_REPOSITORY ${DELTAFS_SHUFFLE_REPO}
                   GIT_TAG ${DELTAFS_SHUFFLE_TAG})
umbrella_patchcheck (DELTAFS_SHUFFLE_PATCHCMD deltafs-shuffle)

#
# depends
#
include (umbrella/deltafs-nexus)
include (umbrella/mercury-progressor)

#
# create deltafs-shuffle target
#
ExternalProject_Add (deltafs-shuffle DEPENDS mercury-progressor deltafs-nexus
    ${DELTAFS_SHUFFLE_DOWNLOAD} ${DELTAFS_SHUFFLE_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET deltafs-shuffle)
