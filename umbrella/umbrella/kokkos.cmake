#
# kokkos.cmake  umbrella for kokkos
# 10-May-2023  ankushj@andrew.cmu.edu
#

#
# config:
#  KOKKOS_REPO - url of git repository
#  KOKKOS_TAG  - tag to checkout of git
#  KOKKOS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET kokkos)

umbrella_defineopt (KOKKOS_REPO "https://github.com/kokkos/kokkos.git"
     STRING "KOKKOS GIT repository")
umbrella_defineopt (KOKKOS_TAG "4.0.01" STRING "KOKKOS GIT tag")
umbrella_defineopt (KOKKOS_TAR "kokkos-${KOKKOS_TAG}.tar.gz"
     STRING "KOKKOS cache tar file")
#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (KOKKOS_DOWNLOAD kokkos
                   ${KOKKOS_TAR}
                   GIT_REPOSITORY ${KOKKOS_REPO}
                   GIT_TAG ${KOKKOS_TAG})
umbrella_patchcheck (KOKKOS_PATCHCMD kokkos)
# TODO: hook up tests (also add to ExternalProject_Add)
# umbrella_testcommand (kokkos KOKKOS_TESTCMD
#                       ctest -R preload -V )

#
# create kokkos target
#
ExternalProject_Add (kokkos
    ${KOKKOS_DOWNLOAD} ${KOKKOS_PATCHCMD}
    CMAKE_ARGS -DKokkos_ENABLE_AGGRESSIVE_VECTORIZATION=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET kokkos)
