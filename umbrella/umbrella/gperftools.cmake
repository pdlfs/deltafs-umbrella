#
# gperftools.cmake  umbrella for GPERFTOOLS communications package
# 04-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  GPERFTOOLS_REPO - url of git repository
#  GPERFTOOLS_TAG  - tag to checkout of git
#  GPERFTOOLS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET gperftools)

#
# umbrella option variables
#
umbrella_defineopt (GPERFTOOLS_REPO
    "https://github.com/gperftools/gperftools.git"
   STRING "GPERFTOOLS GIT repository")
umbrella_defineopt (GPERFTOOLS_TAG "master" STRING "GPERFTOOLS GIT tag")
umbrella_defineopt (GPERFTOOLS_TAR "gperftools-${GPERFTOOLS_TAG}.tar.gz"
    STRING "GPERFTOOLS cache tar file")

umbrella_defineopt (GPERFTOOLS_FRAMEPOINTER "off"
                    BOOLEAN "enable frame pointer")

if (GPERFTOOLS_FRAMEPOINTER)
    set (GPERFTOOLS_FPFLAGS "--enable-frame-pointers")
    message (STATUS "  gperftools: frame pointers on")
else ()
    set (GPERFTOOLS_FPFLAGS "")
    message (STATUS "  gperftools: frame pointers off")
endif ()



#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (GPERFTOOLS_DOWNLOAD gperftools ${GPERFTOOLS_TAR}
                   GIT_REPOSITORY ${GPERFTOOLS_REPO}
                   GIT_TAG ${GPERFTOOLS_TAG})
umbrella_patchcheck (GPERFTOOLS_PATCHCMD gperftools)

#
# create gperftools target
#
ExternalProject_Add (gperftools ${GPERFTOOLS_DOWNLOAD} ${GPERFTOOLS_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      ${GPERFTOOLS_FPFLAGS}
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (gperftools prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET gperftools)
