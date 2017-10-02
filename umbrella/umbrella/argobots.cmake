#
# argobots.cmake  umbrella for argobots user-level threading package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  ARGOBOTS_REPO - url of git repository
#  ARGOBOTS_TAG  - tag to checkout of git
#  ARGOBOTS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET argobots)

#
# umbrella option variables
#

### real REPO is --> https://github.com/pmodels/argobots
# XXX: this is TMP until argobots issue #26 is fixed
# https://xgitlab.cels.anl.gov/sds/abt-snoozer#dependencies
# https://github.com/pmodels/argobots/issues/26
# --> use branch dev-get-dev-basic instead of master
###
umbrella_defineopt (ARGOBOTS_REPO
     "https://github.com/carns/argobots.git"
     STRING "argobots GIT repository")
umbrella_defineopt (ARGOBOTS_TAG "dev-get-dev-basic" STRING "argobots GIT tag")
umbrella_defineopt (ARGOBOTS_TAR "argobots-${ARGOBOTS_TAG}.tar.gz"
     STRING "argobots cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (ARGOBOTS_DOWNLOAD argobots ${ARGOBOTS_TAR}
                   GIT_REPOSITORY ${ARGOBOTS_REPO}
                   GIT_TAG ${ARGOBOTS_TAG})
umbrella_patchcheck (ARGOBOTS_PATCHCMD argobots)
umbrella_testcommand (ARGOBOTS_TESTCMD TEST_COMMAND make -C test check)

#
# create argobots target
#
ExternalProject_Add (argobots
    ${ARGOBOTS_DOWNLOAD} ${ARGOBOTS_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}
    UPDATE_COMMAND ""
    ${ARGOBOTS_TESTCMD}
)

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (argobots prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET argobots)
