#
# json-c.cmake  umbrella for json-c parser
# 19-Apr-2021  chuck@ece.cmu.edu
#

#
# config:
#  JSON_C_REPO - url of git repository
#  JSON_C_TAG  - tag to checkout of git
#  JSON_C_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET json-c)

#
# umbrella option variables
#
umbrella_defineopt (JSON_C_REPO
    "https://github.com/json-c/json-c.git"
     STRING "json-c GIT repository")
umbrella_defineopt (JSON_C_TAG "master" STRING "json-c GIT tag")
umbrella_defineopt (JSON_C_TAR
     "json-c-${JSON_C_TAG}.tar.gz"
     STRING "json-c cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (JSON_C_DOWNLOAD json-c ${JSON_C_TAR}
                   GIT_REPOSITORY ${JSON_C_REPO}
                   GIT_TAG ${JSON_C_TAG})
umbrella_patchcheck (JSON_C_PATCHCMD json-c)
umbrella_testcommand (json-c JSON_C_TESTCMD
    TEST_COMMAND "" )

#
# create deltafs-nexus target
#
ExternalProject_Add (json-c
    ${JSON_C_DOWNLOAD} ${JSON_C_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
    ${JSON_C_TESTCMD}
)

endif (NOT TARGET json-c)
