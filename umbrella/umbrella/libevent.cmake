#
# libevent.cmake  umbrella for libevent
# 28-Aug-2019  chuck@ece.cmu.edu
#

#
# config:
#  LIBEVENT_REPO - url of git repository
#  LIBEVENT_TAG  - tag to checkout of git
#  LIBEVENT_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET libevent)

#
# umbrella option variables
#
umbrella_defineopt (LIBEVENT_REPO "https://github.com/libevent/libevent.git"
     STRING "libevent GIT repository")
umbrella_defineopt (LIBEVENT_TAG "master" STRING "libevent GIT tag")
umbrella_defineopt (LIBEVENT_TAR
     "libevent-${LIBEVENT_TAG}.tar.gz"
     STRING "libevent cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (LIBEVENT_DOWNLOAD libevent ${LIBEVENT_TAR}
                   GIT_REPOSITORY ${LIBEVENT_REPO}
                   GIT_TAG ${LIBEVENT_TAG})
umbrella_patchcheck (LIBEVENT_PATCHCMD libevent)

#
# create deltafs-nexus target
#
ExternalProject_Add (libevent ${LIBEVENT_DOWNLOAD} ${LIBEVENT_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET libevent)
