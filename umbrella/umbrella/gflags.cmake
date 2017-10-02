#
# gflags.cmake  umbrella for gflags package
# 01-Oct-2017  gamvrosi@cs.cmu.edu
#

#
# config:
#  GFLAGS_REPO - url of git repository
#  GFLAGS_TAG  - tag to checkout of git
#  GFLAGS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET gflags)

#
# umbrella option variables
#
umbrella_defineopt (GFLAGS_REPO
     "https://github.com/gflags/gflags.git"
     STRING "gflags GIT repository")
umbrella_defineopt (GFLAGS_TAG "master" STRING "gflags GIT tag")
umbrella_defineopt (GFLAGS_TAR "gflags-${GFLAGS_TAG}.tar.gz"
     STRING "gflags cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (GFLAGS_DOWNLOAD gflags ${GFLAGS_TAR}
                   GIT_REPOSITORY ${GFLAGS_REPO}
                   GIT_TAG ${GFLAGS_TAG})
umbrella_patchcheck (GFLAGS_PATCHCMD gflags)
umbrella_testcommand (GFLAGS_TESTCMD TEST_COMMAND make test)

#
# create gflags target
#
ExternalProject_Add (gflags
    ${GFLAGS_DOWNLOAD} ${GFLAGS_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
               -DBUILD_TESTING=${UMBRELLA_BUILD_TESTS}
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
    ${GFLAGS_TESTCMD}
)

endif (NOT TARGET gflags)
