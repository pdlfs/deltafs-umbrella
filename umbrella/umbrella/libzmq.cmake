#
# libzmq.cmake  umbrella for zeromq package
# 04-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  LIBZMQ_REPO - url of git repository
#  LIBZMQ_TAG  - tag to checkout of git
#  LIBZMQ_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET libzmq)

#
# umbrella option variables
#
umbrella_defineopt (LIBZMQ_REPO "https://github.com/zeromq/libzmq.git"
     STRING "libzmq GIT repository")
umbrella_defineopt (LIBZMQ_TAG "master" STRING "libzmq GIT tag")
umbrella_defineopt (LIBZMQ_TAR "libzmq-${LIBZMQ_TAG}.tar.gz"
     STRING "libzmq cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (LIBZMQ_DOWNLOAD libzmq ${LIBZMQ_TAR}
                   GIT_REPOSITORY ${LIBZMQ_REPO}
                   GIT_TAG ${LIBZMQ_TAG})
umbrella_patchcheck (LIBZMQ_PATCHCMD libzmq)

#
# create libzmq target
#
ExternalProject_Add (libzmq
    ${LIBZMQ_DOWNLOAD} ${LIBZMQ_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET libzmq)
