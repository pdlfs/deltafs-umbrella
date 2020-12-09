#
# iperf3.cmake  umbrella for iperf3 benchmark package
# 16-Jul-2020  chuck@ece.cmu.edu
#

#
# config:
#  IPERF3_REPO - url of git repository
#  IPERF3_TAG  - tag to checkout of git
#  IPERF3_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET iperf3)

#
# umbrella option variables
#
umbrella_defineopt (IPERF3_REPO "https://github.com/esnet/iperf"
                    STRING "IPERF3 GIT repository")
umbrella_defineopt (IPERF3_TAG "master" STRING "IPERF3 GIT tag")
umbrella_defineopt (IPERF3_TAR "iperf3-${IPERF3_TAG}.tar.gz"
                                STRING "IPERF3 cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (IPERF3_DOWNLOAD iperf3 ${IPERF3_TAR}
                   GIT_REPOSITORY ${IPERF3_REPO}
                   GIT_TAG ${IPERF3_TAG})
umbrella_patchcheck (IPERF3_PATCHCMD iperf3)

#
# create iperf3 target
#
ExternalProject_Add (iperf3 ${IPERF3_DOWNLOAD} ${IPERF3_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND "")

endif (NOT TARGET iperf3)
