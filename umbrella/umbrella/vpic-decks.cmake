#
# vpic-decks.cmake  vpic master decks and related apps
# 20-Aug-2019  chuck@ece.cmu.edu
#

#
# config:
#  VPIC_DECKS_REPO - url of git repository
#  VPIC_DECKS_TAG  - tag to checkout of git
#  VPIC_DECKS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET vpic-decks)

#
# umbrella option variables
#
umbrella_defineopt (VPIC_DECKS_REPO "https://github.com/pdlfs/vpic-decks.git"
     STRING "vpic-decks GIT repository")
umbrella_defineopt (VPIC_DECKS_TAG "master" STRING "vpic-decks GIT tag")
umbrella_defineopt (VPIC_DECKS_TAR "vpic-decks-${VPIC_DECKS_TAG}.tar.gz"
     STRING "vpic-decks cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (VPIC_DECKS_DOWNLOAD vpic-decks ${VPIC_DECKS_TAR}
                   GIT_REPOSITORY ${VPIC_DECKS_REPO}
                   GIT_TAG ${VPIC_DECKS_TAG})
umbrella_patchcheck (VPIC_DECKS_PATCHCMD vpic-decks)

#
# depends
#
include (umbrella/vpic)

#
# create vpic-decks target
#
ExternalProject_Add (vpic-decks DEPENDS vpic
    ${VPIC_DECKS_DOWNLOAD} ${VPIC_DECKS_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET vpic-decks)
