#
# abt-snoozer.cmake  umbrella for abt-snoozer argobots scheduler package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  ABT_SNOOZER_REPO - url of git repository
#  ABT_SNOOZER_TAG  - tag to checkout of git
#  ABT_SNOOZER_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET abt-snoozer)

#
# umbrella option variables
#
umbrella_defineopt (ABT_SNOOZER_REPO
     "https://xgitlab.cels.anl.gov/sds/abt-snoozer.git"
     STRING "abt-snoozer GIT repository")
umbrella_defineopt (ABT_SNOOZER_TAG "master" STRING "abt-snoozer GIT tag")
umbrella_defineopt (ABT_SNOOZER_TAR "abt-snoozer-${ABT_SNOOZER_TAG}.tar.gz"
     STRING "abt-snoozer cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (ABT_SNOOZER_DOWNLOAD abt-snoozer ${ABT_SNOOZER_TAR}
                   GIT_REPOSITORY ${ABT_SNOOZER_REPO}
                   GIT_TAG ${ABT_SNOOZER_TAG})
umbrella_patchcheck (ABT_SNOOZER_PATCHCMD abt-snoozer)
umbrella_testcommand (ABT_SNOOZER_TESTCMD TEST_COMMAND make check)

#
# depends
#
include (umbrella/argobots)
include (umbrella/libev)

#
# create abt-snoozer target
#
ExternalProject_Add (abt-snoozer DEPENDS argobots libev
    ${ABT_SNOOZER_DOWNLOAD} ${ABT_SNOOZER_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --with-libev=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND ""
    ${ABT_SNOOZER_TESTCMD}
)

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (abt-snoozer prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/prepare.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET abt-snoozer)
