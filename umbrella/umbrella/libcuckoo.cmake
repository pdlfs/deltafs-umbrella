#
# libcuckoo.cmake  umbrella for libcuckoo hash
# 05-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  LIBCUCKOO_REPO - url of git repository
#  LIBCUCKOO_TAG  - tag to checkout of git
#  LIBCUCKOO_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET libcuckoo)

#
# umbrella option variables
#
umbrella_defineopt (LIBCUCKOO_REPO "https://github.com/efficient/libcuckoo.git"
     STRING "libcuckoo GIT repository")
umbrella_defineopt (LIBCUCKOO_TAG "master" STRING "libcuckoo GIT tag")
umbrella_defineopt (LIBCUCKOO_TAR "libcuckoo-${LIBCUCKOO_TAG}.tar.gz"
     STRING "libcuckoo cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (LIBCUCKOO_DOWNLOAD libcuckoo ${LIBCUCKOO_TAR}
                   GIT_REPOSITORY ${LIBCUCKOO_REPO}
                   GIT_TAG ${LIBCUCKOO_TAG})
umbrella_patchcheck (LIBCUCKOO_PATCHCMD libcuckoo)

#
# create libcuckoo target
#
ExternalProject_Add (libcuckoo 
    ${LIBCUCKOO_DOWNLOAD} ${LIBCUCKOO_PATCHCMD}
    CMAKE_ARGS ${PDLFS_OPTIONS}
        -DBUILD_TESTS=${UMBRELLA_BUILD_TESTS}
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET libcuckoo)
