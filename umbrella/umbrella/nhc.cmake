#
# nhc.cmake  umbrella for node health check
# 28-Sep-2021  chuck@ece.cmu.edu
#

#
# config:
#  NHC_REPO - url of git repository
#  NHC_TAG  - tag to checkout of git
#  NHC_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET nhc)

#
# umbrella option variables
#
umbrella_defineopt (NHC_REPO "https://github.com/mej/nhc.git"
                    STRING "NHC GIT repository")
umbrella_defineopt (NHC_TAG "master" STRING "NHC GIT tag")
umbrella_defineopt (NHC_TAR "nhc-${NHC_TAG}.tar.gz" STRING "NHC cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (NHC_DOWNLOAD nhc ${NHC_TAR}
                   GIT_REPOSITORY ${NHC_REPO}
                   GIT_TAG ${NHC_TAG})
umbrella_patchcheck (NHC_PATCHCMD nhc)

#
# create nhc target
#
ExternalProject_Add (nhc ${NHC_DOWNLOAD} ${NHC_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (nhc prepare
    COMMAND env NO_CONFIGURE=1 
                 ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET nhc)
