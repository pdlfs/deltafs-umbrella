#
# sds-utils.cmake  umbrella for sds-utils package
# 09-Mar-2018  chuck@ece.cmu.edu
#

#
# config:
#  SDS_UTILS_REPO - url of git repository
#  SDS_UTILS_TAG  - tag to checkout of git
#  SDS_UTILS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET sds-utils)

#
# umbrella option variables
#
umbrella_defineopt (SDS_UTILS_REPO "https://xgitlab.cels.anl.gov/sds/utils.git"
     STRING "SDS_UTILS GIT repository")
umbrella_defineopt (SDS_UTILS_TAG "master" STRING "SDS_UTILS GIT tag")
umbrella_defineopt (SDS_UTILS_TAR "sds-utils-${SDS_UTILS_TAG}.tar.gz"
                    STRING "SDS_UTILS cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (SDS_UTILS_DOWNLOAD sds-utils ${SDS_UTILS_TAR}
                   GIT_REPOSITORY ${SDS_UTILS_REPO}
                   GIT_TAG ${SDS_UTILS_TAG})
umbrella_patchcheck (SDS_UTILS_PATCHCMD sds-utils)

# sds-utils requirements

#
# create sds-utils target
#
ExternalProject_Add (sds-utils ${SDS_UTILS_DOWNLOAD} ${SDS_UTILS_PATCHCMD}
    CONFIGURE_COMMAND ""
    BUILD_IN_SOURCE 1
    BUILD_COMMAND ""
    INSTALL_COMMAND make prefix=${CMAKE_INSTALL_PREFIX} install
    UPDATE_COMMAND "")

endif (NOT TARGET sds-utils)
