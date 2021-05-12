#
# margo.cmake  umbrella for margo rpc package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  MARGO_REPO - url of git repository
#  MARGO_TAG  - tag to checkout of git
#  MARGO_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET margo)

#
# umbrella option variables
#
umbrella_defineopt (MARGO_REPO
     "https://github.com/mochi-hpc/mochi-margo.git"
     STRING "margo GIT repository")
umbrella_defineopt (MARGO_TAG "main" STRING "margo GIT tag")
umbrella_defineopt (MARGO_TAR "margo-${MARGO_TAG}.tar.gz"
     STRING "margo cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (MARGO_DOWNLOAD margo ${MARGO_TAR}
                   GIT_REPOSITORY ${MARGO_REPO}
                   GIT_TAG ${MARGO_TAG})
umbrella_patchcheck (MARGO_PATCHCMD margo)
umbrella_testcommand (margo MARGO_TESTCMD TEST_COMMAND make check)

#
# depends
#
include (umbrella/argobots)
include (umbrella/json-c)
include (umbrella/mercury)

#
# create margo target
#
ExternalProject_Add (margo DEPENDS argobots json-c mercury
    ${MARGO_DOWNLOAD} ${MARGO_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX}
    UPDATE_COMMAND ""
    ${MARGO_TESTCMD}
)

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (margo prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/prepare.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET margo)
