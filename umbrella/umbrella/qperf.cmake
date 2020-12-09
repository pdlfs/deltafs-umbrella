#
# qperf.cmake  umbrella for qperf package
# 17-Jul-2020  chuck@ece.cmu.edu
#

#
# config:
#  QPERF_REPO - url of git repository
#  QPERF_TAG  - tag to checkout of git
#  QPERF_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET qperf)

#
# umbrella option variables
#
umbrella_defineopt (QPERF_REPO "https://github.com/linux-rdma/qperf"
                    STRING "QPERF GIT repository")
umbrella_defineopt (QPERF_TAG "master" STRING "QPERF GIT tag")
umbrella_defineopt (QPERF_TAR "qperf-${QPERF_TAG}.tar.gz"
                                STRING "QPERF cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (QPERF_DOWNLOAD qperf ${QPERF_TAR}
                   GIT_REPOSITORY ${QPERF_REPO}
                   GIT_TAG ${QPERF_TAG})
umbrella_patchcheck (QPERF_PATCHCMD qperf)

#
# depends
#
include (umbrella/rdma-core)

#
# create qperf target
# XXX: set MAKEINFO=true, or it will fail without makeinfo cmd
#
ExternalProject_Add (qperf DEPENDS rdma-core
    ${QPERF_DOWNLOAD} ${QPERF_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    BUILD_IN_SOURCE 1
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (qperf prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)


endif (NOT TARGET qperf)
