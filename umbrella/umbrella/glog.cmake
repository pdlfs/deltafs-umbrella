#
# glog.cmake  umbrella for google log package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  GLOG_REPO - url of git repository
#  GLOG_TAG  - tag to checkout of git
#  GLOG_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET glog)

#
# umbrella option variables
#
umbrella_defineopt (GLOG_REPO "https://github.com/google/glog.git"
     STRING "glog GIT repository")
umbrella_defineopt (GLOG_TAG "master" STRING "glog GIT tag")
umbrella_defineopt (GLOG_TAR "glog-${GLOG_TAG}.tar.gz"
     STRING "glog cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (GLOG_DOWNLOAD glog ${GLOG_TAR}
                   GIT_REPOSITORY ${GLOG_REPO}
                   GIT_TAG ${GLOG_TAG})
umbrella_patchcheck (GLOG_PATCHCMD glog)

#
# create glog target
#
ExternalProject_Add (glog
    ${GLOG_DOWNLOAD} ${GLOG_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET glog)
