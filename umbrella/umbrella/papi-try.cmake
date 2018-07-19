#
# papi-try.cmake  umbrella for papi-try
# 19-Jul-2018
#

#
# config:
#  PAPI_TRY_REPO - url of git repository
#  PAPI_TRY_TAG  - tag to checkout of git
#  PAPI_TRY_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET papi-try)

#
# umbrella option variables
#
umbrella_defineopt (PAPI_TRY_REPO
     "https://github.com/pdlfs/papi-try.git"
     STRING "papi-try GIT repository")
umbrella_defineopt (PAPI_TRY_TAG "master" STRING "papi-try GIT tag")
umbrella_defineopt (PAPI_TRY_TAR
     "papi-try-${PAPI_TRY_TAG}.tar.gz"
     STRING "papi-try cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (PAPI_TRY_DOWNLOAD papi-try ${PAPI_TRY_TAR}
                   GIT_REPOSITORY ${PAPI_TRY_REPO}
                   GIT_TAG ${PAPI_TRY_TAG})
umbrella_patchcheck (PAPI_TRY_PATCHCMD papi-try)


#
# create the papi-try target
#
ExternalProject_Add (papi-try ${PAPI_TRY_DOWNLOAD} ${PAPI_TRY_PATCHCMD}
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET papi-try)
