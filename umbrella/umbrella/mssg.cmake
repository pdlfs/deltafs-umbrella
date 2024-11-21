#
# mssg.cmake  umbrella for modified/mpi ssg
# 06-Feb-2018  chuck@ece.cmu.edu
#

#
# config:
#  MSSG_REPO - url of git repository
#  MSSG_TAG  - tag to checkout of git
#  MSSG_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET mssg)

#
# umbrella option variables
#
umbrella_defineopt (MSSG_REPO
    "https://github.com/pdlfs/mssg.git"
     STRING "mssg GIT repository")
umbrella_defineopt (MSSG_TAG "master" STRING "mssg GIT tag")
umbrella_defineopt (MSSG_TAR
     "mssg-${MSSG_TAG}.tar.gz"
     STRING "mssg cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (MSSG_DOWNLOAD mssg ${MSSG_TAR}
                   GIT_REPOSITORY ${MSSG_REPO}
                   GIT_TAG ${MSSG_TAG})
umbrella_patchcheck (MSSG_PATCHCMD mssg)
umbrella_testcommand (mssg MSSG_TESTCMD
    ### "ctest -R mssg -V"
    "" )

#
# depends
#
include (umbrella/mercury)

#
# create deltafs-nexus target
#
ExternalProject_Add (mssg DEPENDS mercury
    ${MSSG_DOWNLOAD} ${MSSG_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
    ${MSSG_TESTCMD}
)

endif (NOT TARGET mssg)
