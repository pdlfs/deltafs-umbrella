#
# perftest.cmake  umbrella for perftest package
# 17-Jul-2020  chuck@ece.cmu.edu
#

#
# config:
#  PERFTEST_REPO - url of git repository
#  PERFTEST_TAG  - tag to checkout of git
#  PERFTEST_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET perftest)

#
# umbrella option variables
#
umbrella_defineopt (PERFTEST_REPO "https://github.com/linux-rdma/perftest"
                    STRING "PERFTEST GIT repository")
umbrella_defineopt (PERFTEST_TAG "master" STRING "PERFTEST GIT tag")
umbrella_defineopt (PERFTEST_TAR "perftest-${PERFTEST_TAG}.tar.gz"
                                STRING "PERFTEST cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (PERFTEST_DOWNLOAD perftest ${PERFTEST_TAR}
                   GIT_REPOSITORY ${PERFTEST_REPO}
                   GIT_TAG ${PERFTEST_TAG})
umbrella_patchcheck (PERFTEST_PATCHCMD perftest)

#
# depends
#
include (umbrella/rdma-core)

#
# create perftest target
# XXX: set MAKEINFO=true, or it will fail without makeinfo cmd
#
ExternalProject_Add (perftest DEPENDS rdma-core
    ${PERFTEST_DOWNLOAD} ${PERFTEST_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (perftest prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)


endif (NOT TARGET perftest)
