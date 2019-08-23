#
# vpic.cmake  umbrella for vpic simulator
# 12-Jul-2019  chuck@ece.cmu.edu
#

#
# config:
#  VPIC_REPO - url of git repository
#  VPIC_TAG  - tag to checkout of git
#  VPIC_TAR  - cache tar file name (default should be ok)
#  VPIC_CFG  - cache config script
#

if (NOT TARGET vpic)

#
# umbrella option variables
#
umbrella_defineopt (VPIC_REPO "https://github.com/pdlfs/vpic.git"
     STRING "VPIC GIT repository")
umbrella_defineopt (VPIC_TAG "master" STRING "VPIC GIT tag")
umbrella_defineopt (VPIC_TAR "vpic-${VPIC_TAG}.tar.gz"
     STRING "VPIC cache tar file")
umbrella_defineopt (VPIC_CFG "gcc/v4-sse" STRING "VPIC cache config script")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (VPIC_DOWNLOAD vpic ${VPIC_TAR}
                   GIT_REPOSITORY ${VPIC_REPO}
                   GIT_TAG ${VPIC_TAG})
umbrella_patchcheck (VPIC_PATCHCMD vpic)

#
# create vpic target
#
ExternalProject_Add (vpic ${VPIC_DOWNLOAD} ${VPIC_PATCHCMD}
    CMAKE_ARGS -C ./vpic-init-cache.cmake -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS "${UMBRELLA_CMAKECACHE};-DENABLE_PARTICLE_TAG:BOOL=ON"
    UPDATE_COMMAND ""
)

#
# add extra cache config step
#
ExternalProject_Add_Step (vpic prepare
    COMMAND <SOURCE_DIR>/arch/${VPIC_CFG} initcache
    COMMENT "generating initial cmake cache for configure ${VPIC_CFG}"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <BINARY_DIR>)

endif (NOT TARGET vpic)
