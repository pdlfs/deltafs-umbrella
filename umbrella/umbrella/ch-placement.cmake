#
# ch-placement.cmake  umbrella for ch-placement consistant hashing package
# 29-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  CH_PLACEMENT_REPO - url of git repository
#  CH_PLACEMENT_TAG  - tag to checkout of git
#  CH_PLACEMENT_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET ch-placement)

#
# umbrella option variables
#
umbrella_defineopt (CH_PLACEMENT_REPO
     "http://xgitlab.cels.anl.gov/codes/ch-placement.git"
     STRING "ch-placement GIT repository")
umbrella_defineopt (CH_PLACEMENT_TAG "master" STRING "ch-placement GIT tag")
umbrella_defineopt (CH_PLACEMENT_TAR "ch-placement-${CH_PLACEMENT_TAG}.tar.gz"
     STRING "ch-placement cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (CH_PLACEMENT_DOWNLOAD ch-placement ${CH_PLACEMENT_TAR}
                   GIT_REPOSITORY ${CH_PLACEMENT_REPO}
                   GIT_TAG ${CH_PLACEMENT_TAG})
umbrella_patchcheck (CH_PLACEMENT_PATCHCMD ch-placement)
umbrella_testcommand (CH_PLACEMENT_TESTCMD TEST_COMMAND make check)

#
# create ch-placement target
#
ExternalProject_Add (ch-placement
    ${CH_PLACEMENT_DOWNLOAD} ${CH_PLACEMENT_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND ""
    ${CH_PLACEMENT_TESTCMD}
)

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (ch-placement prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/prepare
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET ch-placement)
