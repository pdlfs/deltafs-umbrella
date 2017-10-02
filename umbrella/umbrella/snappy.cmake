#
# snappy.cmake  umbrella for snappy compressor package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  SNAPPY_REPO    - url of git repository
#  SNAPPY_TAG     - tag to checkout of git
#  SNAPPY_TAR     - cache tar file name (default should be ok)
#


if (NOT TARGET snappy)

#
# umbrella option variables
#
umbrella_defineopt (SNAPPY_REPO "https://github.com/google/snappy"
                    STRING "SNAPPY GIT repository")
umbrella_defineopt (SNAPPY_TAG "master" STRING "SNAPPY GIT tag")
umbrella_defineopt (SNAPPY_TAR "snappy-${SNAPPY_TAG}.tar.gz" 
                    STRING "SNAPPY cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (SNAPPY_DOWNLOAD snappy ${SNAPPY_TAR}
                   GIT_REPOSITORY ${SNAPPY_REPO} GIT_TAG ${SNAPPY_TAG})
umbrella_patchcheck (SNAPPY_PATCHCMD snappy)

#
# create snappy target
#
ExternalProject_Add (snappy ${SNAPPY_DOWNLOAD} ${SNAPPY_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND "" )

endif (NOT TARGET snappy)
