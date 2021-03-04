#
# pdlfs-scripts.cmake  umbrella for pdlfs scripts
# 03-Mar-2021  chuck@ece.cmu.edu
#

#
# config:
#  PDLFS_SCRIPTS_REPO - url of git repository
#  PDLFS_SCRIPTS_TAG  - tag to checkout of git
#  PDLFS_SCRIPTS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET pdlfs-scripts)

#
# umbrella option variables
#
umbrella_defineopt (PDLFS_SCRIPTS_REPO
     "https://github.com/pdlfs/pdlfs-scripts.git"
     STRING "pdlfs-scripts GIT repository")
umbrella_defineopt (PDLFS_SCRIPTS_TAG "main" STRING "pdlfs-scripts GIT tag")
umbrella_defineopt (PDLFS_SCRIPTS_TAR
     "pdlfs-scripts-${PDLFS_SCRIPTS_TAG}.tar.gz"
     STRING "pdlfs-scripts cache tar file")

#
# other options
# XXX: must bounce PDLFS_SCRIPTS_VPIC407 thru VPIC407 until 407 phase out
#
umbrella_defineopt (PDLFS_SCRIPTS_VPIC407 "OFF" BOOL
                    "Configure scripts to use the old vpic407 interface")

#
# handle options
#
set (PDLFS_SCRIPTS_CMCACHE "${UMBRELLA_CMAKECACHE}")
if (PDLFS_SCRIPTS_VPIC407)
    list (APPEND PDLFS_SCRIPTS_CMCACHE -DVPIC407:STRING=1)
else ()
    list (APPEND PDLFS_SCRIPTS_CMCACHE -DVPIC407:STRING=0)
endif ()

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (PDLFS_SCRIPTS_DOWNLOAD pdlfs-scripts ${PDLFS_SCRIPTS_TAR}
                   GIT_REPOSITORY ${PDLFS_SCRIPTS_REPO}
                   GIT_TAG ${PDLFS_SCRIPTS_TAG})
umbrella_patchcheck (PDLFS_SCRIPTS_PATCHCMD pdlfs-scripts)

#
# create pdlfs-scripts target
#
ExternalProject_Add (pdlfs-scripts
    ${PDLFS_SCRIPTS_DOWNLOAD} ${PDLFS_SCRIPTS_PATCHCMD}
    CMAKE_CACHE_ARGS ${PDLFS_SCRIPTS_CMCACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET pdlfs-scripts)
