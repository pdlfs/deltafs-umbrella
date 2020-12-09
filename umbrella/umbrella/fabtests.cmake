#
# fabtests.cmake  umbrella fabtests (lives in ofi)
# 17-Jul-2020  chuck@ece.cmu.edu
#

#
# config:
#  FABTEST_OFISRC - ofi source dir override
#

if (NOT TARGET fabtests)

#
# umbrella option variables
#
umbrella_defineopt (FABTEST_OFISRC
     "${CMAKE_BINARY_DIR}/ofi-prefix/src/ofi"
     STRING "ofi source directory")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_patchcheck (FABTESTS_PATCHCMD fabtests)

#
# depends
#
include (umbrella/ofi)

#
# create fabtests target
#
ExternalProject_Add (fabtests DEPENDS ofi
    DOWNLOAD_COMMAND true  # no need to download, comes with ofi
    ${FABTESTS_PATCHCMD}
    SOURCE_DIR ${FABTEST_OFISRC}/fabtests
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND ""
)

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (fabtests prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET fabtests)
