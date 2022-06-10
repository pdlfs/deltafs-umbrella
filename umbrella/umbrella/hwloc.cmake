#
# hwloc.cmake  umbrella for hwloc package
# 28-Aug-2019  chuck@ece.cmu.edu
#

#
# config:
#  HWLOC_REPO - url of git repository
#  HWLOC_TAG  - tag to checkout of git
#  HWLOC_TAR  - cache tar file name (default should be ok)
#

umbrella_prebuilt_check(hwloc FILE hwloc.h)

if (NOT TARGET hwloc)

#
# umbrella option variables
#
umbrella_defineopt (HWLOC_REPO "https://github.com/open-mpi/hwloc.git"
                    STRING "hwloc GIT repository")
umbrella_defineopt (HWLOC_TAG "master" STRING "hwloc GIT tag")
umbrella_defineopt (HWLOC_TAR "hwloc-${HWLOC_TAG}.tar.gz"
     STRING "hwloc cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (HWLOC_DOWNLOAD hwloc ${HWLOC_TAR}
                   GIT_REPOSITORY ${HWLOC_REPO}
                   GIT_TAG ${HWLOC_TAG})
umbrella_patchcheck (HWLOC_PATCHCMD hwloc)

#
# create hwloc target
#
ExternalProject_Add (hwloc ${HWLOC_DOWNLOAD} ${HWLOC_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX}
    UPDATE_COMMAND ""
)

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (hwloc prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET hwloc)
