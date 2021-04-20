#
# kmod.cmake  umbrella for Linux kernel module handling
# 20-Apr-2021  chuck@ece.cmu.edu
#

#
# config:
#  KMOD_REPO - url of git repository
#  KMOD_TAG  - tag to checkout of git
#  KMOD_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET kmod)

#
# umbrella option variables
#
umbrella_defineopt (KMOD_REPO 
    "https://git.kernel.org/pub/scm/utils/kernel/kmod/kmod.git"
    STRING "KMOD GIT repository")
umbrella_defineopt (KMOD_TAG "master" STRING "KMOD GIT tag")
umbrella_defineopt (KMOD_TAR "kmod-${KMOD_TAG}.tar.gz" 
    STRING "KMOD cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (KMOD_DOWNLOAD kmod ${KMOD_TAR}
                   GIT_REPOSITORY ${KMOD_REPO}
                   GIT_TAG ${KMOD_TAG})
umbrella_patchcheck (KMOD_PATCHCMD kmod)

#
# create kmod target
#
ExternalProject_Add (kmod ${KMOD_DOWNLOAD} ${KMOD_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --disable-manpages --without-bashcompletiondir
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (kmod prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET kmod)
