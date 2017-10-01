#
# ssg.cmake  umbrella for SSG groups package
# 29-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  SSG_REPO - url of git repository
#  SSG_TAG  - tag to checkout of git
#  SSG_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET ssg)

#
# umbrella option variables
#
umbrella_defineopt (SSG_REPO "https://github.com/pdlfs/ssg.git"
     STRING "SSG GIT repository")
umbrella_defineopt (SSG_TAG "master" STRING "SSG GIT tag")
umbrella_defineopt (SSG_TAR "ssg-${SSG_TAG}.tar.gz" STRING "SSG cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (SSG_DOWNLOAD ssg ${SSG_TAR}
                   GIT_REPOSITORY ${SSG_REPO}
                   GIT_TAG ${SSG_TAG})
umbrella_patchcheck (SSG_PATCHCMD ssg)

# ssg requirements
include (umbrella/mercury)

#
# create ssg target
#
ExternalProject_Add (ssg DEPENDS mercury
    ${SSG_DOWNLOAD} ${SSG_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_MPICOMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (ssg prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/prepare.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET ssg)
