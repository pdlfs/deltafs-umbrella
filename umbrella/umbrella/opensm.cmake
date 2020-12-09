#
# opensm.cmake  umbrella for opensm package
# 17-Jul-2020  chuck@ece.cmu.edu
#

#
# config:
#  OPENSM_REPO - url of git repository
#  OPENSM_TAG  - tag to checkout of git
#  OPENSM_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET opensm)

#
# umbrella option variables
#
umbrella_defineopt (OPENSM_REPO "https://github.com/linux-rdma/opensm"
                    STRING "OPENSM GIT repository")
umbrella_defineopt (OPENSM_TAG "master" STRING "OPENSM GIT tag")
umbrella_defineopt (OPENSM_TAR "opensm-${OPENSM_TAG}.tar.gz"
                                STRING "OPENSM cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (OPENSM_DOWNLOAD opensm ${OPENSM_TAR}
                   GIT_REPOSITORY ${OPENSM_REPO}
                   GIT_TAG ${OPENSM_TAG})
umbrella_patchcheck (OPENSM_PATCHCMD opensm)

#
# depends
#
include (umbrella/rdma-core)

#
# create opensm target
#
ExternalProject_Add (opensm DEPENDS rdma-core
    ${OPENSM_DOWNLOAD} ${OPENSM_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (opensm prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)


endif (NOT TARGET opensm)
