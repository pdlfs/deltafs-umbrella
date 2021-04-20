#
# bake.cmake  umbrella for bake store package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  BAKE_REPO - url of git repository
#  BAKE_TAG  - tag to checkout of git
#  BAKE_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET bake)

#
# umbrella option variables
#
umbrella_defineopt (BAKE_REPO
     "https://github.com/mochi-hpc/mochi-bake.git"
     STRING "bake GIT repository")
umbrella_defineopt (BAKE_TAG "main" STRING "bake GIT tag")
umbrella_defineopt (BAKE_TAR "bake-${BAKE_TAG}.tar.gz"
     STRING "bake cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (BAKE_DOWNLOAD bake ${BAKE_TAR}
                   GIT_REPOSITORY ${BAKE_REPO}
                   GIT_TAG ${BAKE_TAG})
umbrella_patchcheck (BAKE_PATCHCMD bake)

#
# depends
#
include (umbrella/abt-io)
include (umbrella/libuuid)
include (umbrella/margo)
include (umbrella/pmdk)

#
# create bake target
#
ExternalProject_Add (bake DEPENDS abt-io libuuid margo pmdk
    ${BAKE_DOWNLOAD} ${BAKE_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX}
    UPDATE_COMMAND ""
)

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (bake prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/prepare.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET bake)
