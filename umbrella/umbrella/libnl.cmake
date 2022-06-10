#
# libnl.cmake  umbrella for libnl package
# 16-Jul-2020  chuck@ece.cmu.edu
#

#
# config:
#  LIBNL_REPO - url of git repository
#  LIBNL_TAG  - tag to checkout of git
#  LIBNL_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET libnl)

#
# umbrella option variables
#
umbrella_defineopt (LIBNL_REPO "https://github.com/thom311/libnl"
                    STRING "LIBNL GIT repository")
umbrella_defineopt (LIBNL_TAG "main" STRING "LIBNL GIT tag")
umbrella_defineopt (LIBNL_TAR "libnl-${LIBNL_TAG}.tar.gz"
                                STRING "LIBNL cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (LIBNL_DOWNLOAD libnl ${LIBNL_TAR}
                   GIT_REPOSITORY ${LIBNL_REPO}
                   GIT_TAG ${LIBNL_TAG})
umbrella_patchcheck (LIBNL_PATCHCMD libnl)

#
# create libnl target
# XXX: set MAKEINFO=true, or it will fail without makeinfo cmd
#
ExternalProject_Add (libnl ${LIBNL_DOWNLOAD} ${LIBNL_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      MAKEINFO=true
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (libnl prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)


endif (NOT TARGET libnl)
