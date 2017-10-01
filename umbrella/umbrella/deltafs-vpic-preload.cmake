#
# deltafs-vpic-preload.cmake  umbrella for deltafs-vpic-preload lib
# 29-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  DELTAFS_VPIC_PRELOAD_REPO - url of git repository
#  DELTAFS_VPIC_PRELOAD_TAG  - tag to checkout of git
#  DELTAFS_VPIC_PRELOAD_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET deltafs-vpic-preload)

#
# umbrella option variables
#
umbrella_defineopt (DELTAFS_VPIC_PRELOAD_REPO
     "https://github.com/pdlfs/deltafs-vpic-preload.git"
     STRING "deltafs-vpic-preload GIT repository")
umbrella_defineopt (DELTAFS_VPIC_PRELOAD_TAG "master"
     STRING "deltafs-vpic-preload GIT tag")
umbrella_defineopt (DELTAFS_VPIC_PRELOAD_TAR
     "deltafs-vpic-preload-${DELTAFS_VPIC_PRELOAD_TAG}.tar.gz"
     STRING "deltafs-vpic-preload cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (DELTAFS_VPIC_PRELOAD_DOWNLOAD deltafs-vpic-preload
                   ${DELTAFS_VPIC_PRELOAD_TAR}
                   GIT_REPOSITORY ${DELTAFS_VPIC_PRELOAD_REPO}
                   GIT_TAG ${DELTAFS_VPIC_PRELOAD_TAG})
umbrella_patchcheck (DELTAFS_VPIC_PRELOAD_PATCHCMD deltafs-vpic-preload)
umbrella_testcommand (DELTAFS_VPIC_PRELOAD_TESTCMD
    TEST_COMMAND ctest -R preload -V )

#
# depends
#
include (umbrella/ch-placement)
include (umbrella/deltafs)
include (umbrella/deltafs-nexus)
include (umbrella/ssg)

#
# create deltafs-vpic-preload target
#
ExternalProject_Add (deltafs-vpic-preload
    DEPENDS deltafs deltafs-nexus ch-placement ssg
    ${DELTAFS_VPIC_PRELOAD_DOWNLOAD} ${DELTAFS_VPIC_PRELOAD_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
    ${DELTAFS_VPIC_PRELOAD_TESTCMD}
)

endif (NOT TARGET deltafs-vpic-preload)
