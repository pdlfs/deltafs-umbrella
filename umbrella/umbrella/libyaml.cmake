#
# libyaml.cmake  umbrella for yaml parser lib
# 29-Sep-2019  chuck@ece.cmu.edu
#

#
# config:
#  LIBYAML_REPO - url of git repository
#  LIBYAML_TAG  - tag to checkout of git
#  LIBYAML_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET libyaml)

#
# umbrella option variables
#
umbrella_defineopt (LIBYAML_REPO "https://github.com/yaml/libyaml"
                    STRING "LIBYAML GIT repository")
umbrella_defineopt (LIBYAML_TAG "master" STRING "LIBYAML GIT tag")
umbrella_defineopt (LIBYAML_TAR "libyaml-${LIBYAML_TAG}.tar.gz"
                    STRING "LIBYAML cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (LIBYAML_DOWNLOAD libyaml ${LIBYAML_TAR}
                   GIT_REPOSITORY ${LIBYAML_REPO}
                   GIT_TAG ${LIBYAML_TAG})
umbrella_patchcheck (LIBYAML_PATCHCMD libyaml)

#
# create libyaml target
#
ExternalProject_Add (libyaml ${LIBYAML_DOWNLOAD} ${LIBYAML_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (libyaml prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/bootstrap
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET libyaml)
