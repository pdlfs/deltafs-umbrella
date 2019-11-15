#
# pmix.cmake  umbrella for pmix package
# 28-Aug-2019  chuck@ece.cmu.edu
#

#
# config:
#  PMIX_REPO - url of git repository
#  PMIX_TAG  - tag to checkout of git
#  PMIX_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET pmix)

#
# umbrella option variables
#
umbrella_defineopt (PMIX_REPO "https://github.com/pmix/pmix.git"
                    STRING "pmix GIT repository")
umbrella_defineopt (PMIX_TAG "master" STRING "pmix GIT tag")
umbrella_defineopt (PMIX_TAR "pmix-${PMIX_TAG}.tar.gz"
     STRING "pmix cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (PMIX_DOWNLOAD pmix ${PMIX_TAR}
                   GIT_REPOSITORY ${PMIX_REPO}
                   GIT_TAG ${PMIX_TAG})
umbrella_patchcheck (PMIX_PATCHCMD pmix)

#
# depends
#
include (umbrella/hwloc)
include (umbrella/libevent)

#
# build optimized version unless the build type is Debug
#
if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    set (PMIX_EXTRA_CFG "")
else ()
    set (PMIX_EXTRA_CFG "--with-platform=optimized")
endif ()

#
# create pmix target
#
ExternalProject_Add (pmix DEPENDS hwloc libevent
    ${PMIX_DOWNLOAD} ${PMIX_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX} ${PMIX_EXTRA_CFG}
    UPDATE_COMMAND ""
)

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (pmix prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.pl
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET pmix)
