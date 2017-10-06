#
# googletest.cmake  umbrella for google test package
# 04-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  GOOGLETEST_REPO - url of git repository
#  GOOGLETEST_TAG  - tag to checkout of git
#  GOOGLETEST_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET googletest)

#
# umbrella option variables
#
umbrella_defineopt (GOOGLETEST_REPO "https://github.com/google/googletest.git"
     STRING "googletest GIT repository")
umbrella_defineopt (GOOGLETEST_TAG "master" STRING "googletest GIT tag")
umbrella_defineopt (GOOGLETEST_TAR "googletest-${GOOGLETEST_TAG}.tar.gz"
     STRING "googletest cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (GOOGLETEST_DOWNLOAD googletest ${GOOGLETEST_TAR}
                   GIT_REPOSITORY ${GOOGLETEST_REPO}
                   GIT_TAG ${GOOGLETEST_TAG})
umbrella_patchcheck (GOOGLETEST_PATCHCMD googletest)

#
# create googletest target
#
ExternalProject_Add (googletest
    ${GOOGLETEST_DOWNLOAD} ${GOOGLETEST_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET googletest)
