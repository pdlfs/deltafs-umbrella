#
# hg-bulk-pool.cmake  umbrella for hg-bulk-pool package
# 06-Nov-2017  chuck@ece.cmu.edu
#

#
# config:
#  HG_BULK_POOL_REPO - url of git repository
#  HG_BULK_POOL_TAG  - tag to checkout of git
#  HG_BULK_POOL_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET hg-bulk-pool)

#
# umbrella option variables
#
umbrella_defineopt (HG_BULK_POOL_REPO 
                    "https://xgitlab.cels.anl.gov/sds/hg-bulk-pool.git"
                    STRING "HG_BULK_POOL GIT repository")
umbrella_defineopt (HG_BULK_POOL_TAG "master" STRING "HG_BULK_POOL GIT tag")
umbrella_defineopt (HG_BULK_POOL_TAR "hg-bulk-pool-${HG_BULK_POOL_TAG}.tar.gz"
                    STRING "HG_BULK_POOL cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (HG_BULK_POOL_DOWNLOAD hg-bulk-pool ${HG_BULK_POOL_TAR}
                   GIT_REPOSITORY ${HG_BULK_POOL_REPO}
                   GIT_TAG ${HG_BULK_POOL_TAG})
umbrella_patchcheck (HG_BULK_POOL_PATCHCMD hg-bulk-pool)

# hg-bulk-pool requirements
include (umbrella/argobots)
include (umbrella/mercury)   # XXX: margo?

#
# create hg-bulk-pool target
#
ExternalProject_Add (hg-bulk-pool DEPENDS argobots mercury
    ${HG_BULK_POOL_DOWNLOAD} ${HG_BULK_POOL_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_MPICOMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (hg-bulk-pool prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/prepare.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET hg-bulk-pool)
