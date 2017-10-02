#
# nvml.cmake  umbrella for deltafs burst buffer object store
# 29-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  NVML_REPO - url of git repository
#  NVML_TAG  - tag to checkout of git
#  NVML_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET nvml)

#
# umbrella option variables
#
umbrella_defineopt (NVML_REPO "https://github.com/pmem/nvml"
     STRING "nvml GIT repository")
umbrella_defineopt (NVML_TAG "master" STRING "nvml GIT tag")
umbrella_defineopt (NVML_TAR "nvml-${NVML_TAG}.tar.gz"
     STRING "nvml cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (NVML_DOWNLOAD nvml ${NVML_TAR}
                   GIT_REPOSITORY ${NVML_REPO}
                   GIT_TAG ${NVML_TAG})
umbrella_patchcheck (NVML_PATCHCMD nvml)

#
# create nvml target
#
ExternalProject_Add (nvml ${NVML_DOWNLOAD} ${NVML_PATCHCMD}
    CONFIGURE_COMMAND ""
    BUILD_IN_SOURCE 1
    BUILD_COMMAND make prefix=${CMAKE_INSTALL_PREFIX}
        COMMAND make prefix=${CMAKE_INSTALL_PREFIX} test
    INSTALL_COMMAND make prefix=${CMAKE_INSTALL_PREFIX} install
    ### TEST_COMMAND make prefix=${CMAKE_INSTALL_PREFIX} check
    UPDATE_COMMAND ""
)

endif (NOT TARGET nvml)
