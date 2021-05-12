#
# onetbb.cmake  umbrella for thread building blocks
# 12-Mar-2021  chuck@ece.cmu.edu
#

#
# config:
#  ONETBB_REPO - url of git repository
#  ONETBB_TAG  - tag to checkout of git
#  ONETBB_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET onetbb)

#
# umbrella option variables
#
umbrella_defineopt (ONETBB_REPO "https://github.com/oneapi-src/oneTBB"
     STRING "onetbb GIT repository")
umbrella_defineopt (ONETBB_TAG "master" STRING "onetbb GIT tag")
umbrella_defineopt (ONETBB_TAR "onetbb-${ONETBB_TAG}.tar.gz"
     STRING "onetbb cache tar file")
umbrella_buildtests(onetbb ONETBB_BUILDTESTS)

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (ONETBB_DOWNLOAD onetbb ${ONETBB_TAR}
                   GIT_REPOSITORY ${ONETBB_REPO}
                   GIT_TAG ${ONETBB_TAG})
umbrella_patchcheck (ONETBB_PATCHCMD onetbb)

#
# create onetbb target
#
ExternalProject_Add (onetbb ${ONETBB_DOWNLOAD} ${ONETBB_PATCHCMD}
    CMAKE_ARGS -DTBB_TEST=${ONETBB_BUILDTESTS}
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET onetbb)
