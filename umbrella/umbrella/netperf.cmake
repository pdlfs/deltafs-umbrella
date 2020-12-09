#
# netperf.cmake  umbrella for netperf benchmark package
# 16-Jul-2020  chuck@ece.cmu.edu
#

#
# config:
#  NETPERF_REPO - url of git repository
#  NETPERF_TAG  - tag to checkout of git
#  NETPERF_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET netperf)

#
# umbrella option variables
#
umbrella_defineopt (NETPERF_REPO "https://github.com/HewlettPackard/netperf"
                    STRING "NETPERF GIT repository")
umbrella_defineopt (NETPERF_TAG "master" STRING "NETPERF GIT tag")
umbrella_defineopt (NETPERF_TAR "netperf-${NETPERF_TAG}.tar.gz"
                                STRING "NETPERF cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (NETPERF_DOWNLOAD netperf ${NETPERF_TAR}
                   GIT_REPOSITORY ${NETPERF_REPO}
                   GIT_TAG ${NETPERF_TAG})
umbrella_patchcheck (NETPERF_PATCHCMD netperf)

#
# create netperf target
# XXX: set MAKEINFO=true, or it will fail without makeinfo cmd
#
ExternalProject_Add (netperf ${NETPERF_DOWNLOAD} ${NETPERF_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      MAKEINFO=true
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (netperf prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)


endif (NOT TARGET netperf)
