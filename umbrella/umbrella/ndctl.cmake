#
# ndctl.cmake  umbrella for libnvdimm sub-sytem mgt library
# 19-Apr-2021  chuck@ece.cmu.edu
#

#
# config:
#  NDCTL_REPO - url of git repository
#  NDCTL_TAG  - tag to checkout of git
#  NDCTL_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET ndctl)

#
# umbrella option variables
#
umbrella_defineopt (NDCTL_REPO "https://github.com/pmem/ndctl.git"
                    STRING "NDCTL GIT repository")
umbrella_defineopt (NDCTL_TAG "master" STRING "NDCTL GIT tag")
umbrella_defineopt (NDCTL_TAR "ndctl-${NDCTL_TAG}.tar.gz" STRING "NDCTL cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (NDCTL_DOWNLOAD ndctl ${NDCTL_TAR}
                   GIT_REPOSITORY ${NDCTL_REPO}
                   GIT_TAG ${NDCTL_TAG})
umbrella_patchcheck (NDCTL_PATCHCMD ndctl)

#
# depends
#
include (umbrella/json-c)
include (umbrella/keyutils)
include (umbrella/kmod)
include (umbrella/libuuid)

#
# create ndctl target
#
ExternalProject_Add (ndctl DEPENDS json-c keyutils kmod libuuid
    ${NDCTL_DOWNLOAD} ${NDCTL_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --disable-docs --without-bash --without-systemd
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (ndctl prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET ndctl)
