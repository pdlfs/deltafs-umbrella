#
# pmdk.cmake  umbrella for persistent memory development kit
# 19-Apr-2021  chuck@ece.cmu.edu
#

#
# config:
#  PMDK_REPO - url of git repository
#  PMDK_TAG  - tag to checkout of git
#  PMDK_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET pmdk)

#
# umbrella option variables
#
umbrella_defineopt (PMDK_REPO "https://github.com/pmem/pmdk.git"
     STRING "pmdk GIT repository")
umbrella_defineopt (PMDK_TAG "master" STRING "pmdk GIT tag")
umbrella_defineopt (PMDK_TAR "pmdk-${PMDK_TAG}.tar.gz"
     STRING "pmdk cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (PMDK_DOWNLOAD pmdk ${PMDK_TAR}
                   GIT_REPOSITORY ${PMDK_REPO}
                   GIT_TAG ${PMDK_TAG})
umbrella_patchcheck (PMDK_PATCHCMD pmdk)

#
# depends
#
include (umbrella/ndctl)
include (umbrella/ofi)      # XXX: optional, make it an option?

#
# settings to make the Makefile do the correct thing for us.
# the hand-built Makefiles in pmdk want LDFLAGS in EXTRA_LDFLAGS
# (otherwise we get linking errors).   so we prepend "EXTRA_" to it
# in pmdk-extra-ldflags.
#
set(pmdk-extra-ldflags "EXTRA_${UMBRELLA_LDFLAGS}")
set(pmdk-makeargs ${UMBRELLA_COMP} ${UMBRELLA_CPPFLAGS} ${pmdk-extra-ldflags}
     prefix=${CMAKE_INSTALL_PREFIX} DOC=n)

#
# create pmdk target
#
ExternalProject_Add (pmdk DEPENDS ndctl ofi
    ${PMDK_DOWNLOAD} ${PMDK_PATCHCMD}
    CONFIGURE_COMMAND ""
    BUILD_IN_SOURCE 1
    BUILD_COMMAND env "${UMBRELLA_PKGCFGPATH}" 
                    make ${pmdk-makeargs}
    INSTALL_COMMAND env "${UMBRELLA_PKGCFGPATH}"
                    make ${pmdk-makeargs} install
    ### TEST_COMMAND make prefix=${CMAKE_INSTALL_PREFIX} check
    UPDATE_COMMAND ""
)

endif (NOT TARGET pmdk)
