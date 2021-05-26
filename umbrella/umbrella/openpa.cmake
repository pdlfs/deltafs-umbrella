#
# openpa.cmake  umbrella for openpa atomic ops package
# 26-Sep-2021  chuck@ece.cmu.edu
#

#
# config:
#  OPENPA_REPO - url of git repository
#  OPENPA_TAG  - tag to checkout of git
#  OPENPA_TAR  - cache tar file name (default should be ok)
#

umbrella_prebuilt_check(openpa FILE opa_primitives.h)

if (NOT TARGET openpa)

#
# umbrella option variables
#
umbrella_defineopt (OPENPA_REPO "https://github.com/pmodels/openpa.git"
                    STRING "OPENPA GIT repository")
umbrella_defineopt (OPENPA_TAG "master" STRING "OPENPA GIT tag")
umbrella_defineopt (OPENPA_TAR "openpa-${OPENPA_TAG}.tar.gz" STRING 
                    "OPENPA cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (OPENPA_DOWNLOAD openpa ${OPENPA_TAR}
                   GIT_REPOSITORY ${OPENPA_REPO}
                   GIT_TAG ${OPENPA_TAG})
umbrella_patchcheck (OPENPA_PATCHCMD openpa)

#
# create openpa target
#
ExternalProject_Add (openpa ${OPENPA_DOWNLOAD} ${OPENPA_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (openpa prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET openpa)
