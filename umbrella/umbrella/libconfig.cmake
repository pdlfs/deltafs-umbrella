#
# libconfig.cmake  umbrella for libconfig file package
# 04-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  LIBCONFIG_REPO - url of git repository
#  LIBCONFIG_TAG  - tag to checkout of git
#  LIBCONFIG_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET libconfig)

#
# umbrella option variables
#
umbrella_defineopt (LIBCONFIG_REPO "https://github.com/hyperrealm/libconfig.git"
   STRING "LIBCONFIG GIT repository")
umbrella_defineopt (LIBCONFIG_TAG "master" STRING "LIBCONFIG GIT tag")
umbrella_defineopt (LIBCONFIG_TAR "libconfig-${LIBCONFIG_TAG}.tar.gz"
    STRING "LIBCONFIG cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (LIBCONFIG_DOWNLOAD libconfig ${LIBCONFIG_TAR}
                   GIT_REPOSITORY ${LIBCONFIG_REPO}
                   GIT_TAG ${LIBCONFIG_TAG})
umbrella_patchcheck (LIBCONFIG_PATCHCMD libconfig)

# XXX: fails with out makeinfo, but we don't care about info pages, so...
find_program (LIBCONFIG_MAKEINFO makeinfo)
if (NOT LIBCONFIG_MAKEINFO)
    set (LIBCONFIG_INFOINFO "MAKEINFO=true")
    message (STATUS "  libconfig: makeinfo disabled!")
endif ()

#
# create libconfig target
#
ExternalProject_Add (libconfig ${LIBCONFIG_DOWNLOAD} ${LIBCONFIG_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      ${LIBCONFIG_INFOINFO}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      ${LIBCONFIG_FPFLAGS}
    UPDATE_COMMAND "")

endif (NOT TARGET libconfig)
