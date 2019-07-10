#
# vpic407.cmake  umbrella for old vpic version 407 simulator
# 10-Jul-2019  chuck@ece.cmu.edu
#

#
# config:
#  VPIC407_REPO - url of git repository
#  VPIC407_TAG  - tag to checkout of git
#  VPIC407_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET vpic407)

#
# umbrella option variables
#
umbrella_defineopt (VPIC407_REPO "https://github.com/pdlfs/vpic407.git"
     STRING "VPIC407 GIT repository")
umbrella_defineopt (VPIC407_TAG "master" STRING "VPIC407 GIT tag")
umbrella_defineopt (VPIC407_TAR "vpic407-${VPIC407_TAG}.tar.gz"
     STRING "VPIC407 cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (VPIC407_DOWNLOAD vpic407 ${VPIC407_TAR}
                   GIT_REPOSITORY ${VPIC407_REPO}
                   GIT_TAG ${VPIC407_TAG})
umbrella_patchcheck (VPIC407_PATCHCMD vpic407)

# XXX: doesn't really depend on deltafs, but we want to build that first
include (umbrella/deltafs)

#
# create vpic407 target
#
ExternalProject_Add (vpic407 ${VPIC407_DOWNLOAD} ${VPIC407_PATCHCMD}

    #
    # TODO: This code makes me sad, but then again this VPIC407 version
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

endif (NOT TARGET vpic407)
