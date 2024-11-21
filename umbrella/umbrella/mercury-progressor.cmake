#
# mercury-progressor.cmake  umbrella for mercury-progressor
# 15-Nov-2019  chuck@ece.cmu.edu
#

#
# config:
#  MERCURY_PROGRESSOR_REPO - url of git repository
#  MERCURY_PROGRESSOR_TAG  - tag to checkout of git
#  MERCURY_PROGRESSOR_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET mercury-progressor)

#
# umbrella option variables
#
umbrella_defineopt (MERCURY_PROGRESSOR_REPO
    "https://github.com/pdlfs/mercury-progressor.git"
     STRING "mercury-progressor GIT repository")
umbrella_defineopt (MERCURY_PROGRESSOR_TAG "master" STRING
                    "mercury-progressor GIT tag")
umbrella_defineopt (MERCURY_PROGRESSOR_TAR
     "mercury-progressor-${MERCURY_PROGRESSOR_TAG}.tar.gz"
     STRING "mercury-progressor cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (MERCURY_PROGRESSOR_DOWNLOAD
                   mercury-progressor ${MERCURY_PROGRESSOR_TAR}
                   GIT_REPOSITORY ${MERCURY_PROGRESSOR_REPO}
                   GIT_TAG ${MERCURY_PROGRESSOR_TAG})
umbrella_patchcheck (MERCURY_PROGRESSOR_PATCHCMD mercury-progressor)
umbrella_testcommand (mercury-progressor MERCURY_PROGRESSOR_TESTCMD
    ctest )

#
# depends
#
include (umbrella/mercury)

#
# create deltafs-nexus target
#
ExternalProject_Add (mercury-progressor DEPENDS mercury
    ${MERCURY_PROGRESSOR_DOWNLOAD} ${MERCURY_PROGRESSOR_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
    ${MERCURY_PROGRESSOR_TESTCMD}
)

endif (NOT TARGET mercury-progressor)
