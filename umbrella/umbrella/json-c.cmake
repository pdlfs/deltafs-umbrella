#
# json-c.cmake  umbrella for json-c parser
# 19-Apr-2021  chuck@ece.cmu.edu
#

#
# config:
#  JSONC_REPO - url of git repository
#  JSONC_TAG  - tag to checkout of git
#  JSONC_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET json-c)

#
# umbrella option variables
#
umbrella_defineopt (JSONC_REPO
    "https://github.com/json-c/json-c.git"
     STRING "json-c GIT repository")
umbrella_defineopt (JSONC_TAG "master" STRING "json-c GIT tag")
umbrella_defineopt (JSONC_TAR
     "json-c-${JSONC_TAG}.tar.gz"
     STRING "json-c cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (JSONC_DOWNLOAD json-c ${JSONC_TAR}
                   GIT_REPOSITORY ${JSONC_REPO}
                   GIT_TAG ${JSONC_TAG})
umbrella_patchcheck (JSONC_PATCHCMD json-c)
umbrella_testcommand (JSONC_TESTCMD
    TEST_COMMAND "" )

#
# create deltafs-nexus target
#
ExternalProject_Add (json-c
    ${JSONC_DOWNLOAD} ${JSONC_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
    ${JSONC_TESTCMD}
)

endif (NOT TARGET json-c)
