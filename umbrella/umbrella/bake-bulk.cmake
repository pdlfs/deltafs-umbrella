#
# bake-bulk.cmake  umbrella for bake-bulk store package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  BAKE_BULK_REPO - url of git repository
#  BAKE_BULK_TAG  - tag to checkout of git
#  BAKE_BULK_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET bake-bulk)

#
# umbrella option variables
#
umbrella_defineopt (BAKE_BULK_REPO
     "https://xgitlab.cels.anl.gov/sds/bake-bulk.git"
     STRING "bake-bulk GIT repository")
umbrella_defineopt (BAKE_BULK_TAG "master" STRING "bake-bulk GIT tag")
umbrella_defineopt (BAKE_BULK_TAR "bake-bulk-${BAKE_BULK_TAG}.tar.gz"
     STRING "bake-bulk cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (BAKE_BULK_DOWNLOAD bake-bulk ${BAKE_BULK_TAR}
                   GIT_REPOSITORY ${BAKE_BULK_REPO}
                   GIT_TAG ${BAKE_BULK_TAG})
umbrella_patchcheck (BAKE_BULK_PATCHCMD bake-bulk)

#
# depends
#
include (umbrella/margo)
include (umbrella/nvml)
include (umbrella/libuuid)

#
# create bake-bulk target
#
ExternalProject_Add (bake-bulk DEPENDS margo nvml libuuid
    ${BAKE_BULK_DOWNLOAD} ${BAKE_BULK_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX}
    UPDATE_COMMAND ""
)

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (bake-bulk prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/prepare.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET bake-bulk)
