#
# sds-keyval.cmake  umbrella for sds-keyval package
# 06-Nov-2017  chuck@ece.cmu.edu
#

#
# config:
#  SDS_KEYVAL_REPO - url of git repository
#  SDS_KEYVAL_TAG  - tag to checkout of git
#  SDS_KEYVAL_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET sds-keyval)

#
# umbrella option variables
#
umbrella_defineopt (SDS_KEYVAL_REPO
     "https://github.com/mochi-hpc/mochi-sdskv.git"
     STRING "SDS_KEYVAL GIT repository")
umbrella_defineopt (SDS_KEYVAL_TAG "main" STRING "SDS_KEYVAL GIT tag")
umbrella_defineopt (SDS_KEYVAL_TAR "sds-keyval-${SDS_KEYVAL_TAG}.tar.gz"
                    STRING "SDS_KEYVAL cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (SDS_KEYVAL_DOWNLOAD sds-keyval ${SDS_KEYVAL_TAR}
                   GIT_REPOSITORY ${SDS_KEYVAL_REPO}
                   GIT_TAG ${SDS_KEYVAL_TAG})
umbrella_patchcheck (SDS_KEYVAL_PATCHCMD sds-keyval)

# sds-keyval requirements
include (umbrella/ch-placement)
include (umbrella/margo)
include (umbrella/ssg)

#
# create sds-keyval target
#
ExternalProject_Add (sds-keyval DEPENDS ch-placement margo ssg
    ${SDS_KEYVAL_DOWNLOAD} ${SDS_KEYVAL_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_MPICOMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (sds-keyval prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/prepare.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET sds-keyval)
