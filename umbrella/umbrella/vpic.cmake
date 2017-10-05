#
# vpic.cmake  umbrella for vpic simulator
# 27-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  VPIC_REPO - url of git repository
#  VPIC_TAG  - tag to checkout of git
#  VPIC_TAR  - cache tar file name (default should be ok)
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

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (VPIC_DOWNLOAD vpic ${VPIC_TAR}
                   GIT_REPOSITORY ${VPIC_REPO}
                   GIT_TAG ${VPIC_TAG})
umbrella_patchcheck (VPIC_PATCHCMD vpic)

# XXX: doesn't really depend on deltafs, but we want to build that first
include (umbrella/deltafs)

#
# create vpic target
#
ExternalProject_Add (vpic DEPENDS deltafs
    ${VPIC_DOWNLOAD} ${VPIC_PATCHCMD}

    #
    # TODO: This code makes me sad, but then again this VPIC version
    #       also makes me sad. Feel free to fix.

    CONFIGURE_COMMAND cd <SOURCE_DIR> && ./config/bootstrap
        COMMAND <SOURCE_DIR>/prep_conf.sh <SOURCE_DIR>
        COMMAND <SOURCE_DIR>/configure ${UMBRELLA_MPICOMP}
                --prefix=${CMAKE_INSTALL_PREFIX}
                --with-machine=<SOURCE_DIR>/machine.conf

    # We only compile a sample deck here to ensure build.op was properly
    # put together.

    BUILD_COMMAND make
        COMMAND cd <SOURCE_DIR> &&
        <BINARY_DIR>/build.op decks/trecon-part/turbulence.cxx &&
        <BINARY_DIR>/build.op decks/fan-run/turbulence-sheet-tracer2spec.cxx

    INSTALL_COMMAND make install
        COMMAND rm -rf ${CMAKE_INSTALL_PREFIX}/decks
        COMMAND cp -r <SOURCE_DIR>/decks ${CMAKE_INSTALL_PREFIX}
        COMMAND cp -r <SOURCE_DIR>/src/deck_wrapper.cxx
                                  ${CMAKE_INSTALL_PREFIX}/decks
        COMMAND cp -r <SOURCE_DIR>/src/main.cxx ${CMAKE_INSTALL_PREFIX}/decks
        COMMAND cp -r <BINARY_DIR>/vpic-build.op ${CMAKE_INSTALL_PREFIX}/bin
    UPDATE_COMMAND ""
)

endif (NOT TARGET vpic)
