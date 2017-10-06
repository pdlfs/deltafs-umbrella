#
# sparsehash.cmake  umbrella for sparse hash package
# 04-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  SPARSEHASH_REPO - url of git repository
#  SPARSEHASH_TAG  - tag to checkout of git
#  SPARSEHASH_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET sparsehash)

#
# umbrella option variables
#
umbrella_defineopt (SPARSEHASH_REPO
    "https://github.com/sparsehash/sparsehash.git"
   STRING "SPARSEHASH GIT repository")
umbrella_defineopt (SPARSEHASH_TAG "master" STRING "SPARSEHASH GIT tag")
umbrella_defineopt (SPARSEHASH_TAR "sparsehash-${SPARSEHASH_TAG}.tar.gz"
    STRING "SPARSEHASH cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (SPARSEHASH_DOWNLOAD sparsehash ${SPARSEHASH_TAR}
                   GIT_REPOSITORY ${SPARSEHASH_REPO}
                   GIT_TAG ${SPARSEHASH_TAG})
umbrella_patchcheck (SPARSEHASH_PATCHCMD sparsehash)

#
# create sparsehash target
#
ExternalProject_Add (sparsehash ${SPARSEHASH_DOWNLOAD} ${SPARSEHASH_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}
    UPDATE_COMMAND "")

endif (NOT TARGET sparsehash)
