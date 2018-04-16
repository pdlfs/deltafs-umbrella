#
# mdcs.cmake  umbrella for mdcs package
# 09-Mar-2018  chuck@ece.cmu.edu
#

#
# config:
#  MDCS_REPO - url of git repository
#  MDCS_TAG  - tag to checkout of git
#  MDCS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET mdcs)

#
# umbrella option variables
#
umbrella_defineopt (MDCS_REPO
     "https://xgitlab.cels.anl.gov/sds/mdcs.git"
     STRING "mdcs GIT repository")
umbrella_defineopt (MDCS_TAG "master" STRING "mdcs GIT tag")
umbrella_defineopt (MDCS_TAR "mdcs-${MDCS_TAG}.tar.gz"
     STRING "mdcs cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (MDCS_DOWNLOAD mdcs ${MDCS_TAR}
                   GIT_REPOSITORY ${MDCS_REPO}
                   GIT_TAG ${MDCS_TAG})
umbrella_patchcheck (MDCS_PATCHCMD mdcs)

#
# depends
#
include (umbrella/margo)

#
# create mdcs target
#
ExternalProject_Add (mdcs DEPENDS margo
    ${MDCS_DOWNLOAD} ${MDCS_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET mdcs)
