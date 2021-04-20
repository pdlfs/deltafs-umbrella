#
# abt-io.cmake  umbrella for ABT-IO package
# 06-Nov-2017  chuck@ece.cmu.edu
#

#
# config:
#  ABT_IO_REPO - url of git repository
#  ABT_IO_TAG  - tag to checkout of git
#  ABT_IO_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET abt-io)

#
# umbrella option variables
#
umbrella_defineopt (ABT_IO_REPO "https://github.com/mochi-hpc/mochi-abt-io.git"
     STRING "ABT_IO GIT repository")
umbrella_defineopt (ABT_IO_TAG "main" STRING "ABT_IO GIT tag")
umbrella_defineopt (ABT_IO_TAR "abt-io-${ABT_IO_TAG}.tar.gz"
                    STRING "ABT_IO cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (ABT_IO_DOWNLOAD abt-io ${ABT_IO_TAR}
                   GIT_REPOSITORY ${ABT_IO_REPO}
                   GIT_TAG ${ABT_IO_TAG})
umbrella_patchcheck (ABT_IO_PATCHCMD abt-io)

# abt-io requirements
include (umbrella/argobots)
include (umbrella/json-c)

#
# create abt-io target
#
ExternalProject_Add (abt-io DEPENDS argobots json-c
    ${ABT_IO_DOWNLOAD} ${ABT_IO_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_MPICOMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (abt-io prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/prepare.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET abt-io)
