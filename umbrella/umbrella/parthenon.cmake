#
# parthenon.cmake  umbrella for parthenon
# 10-May-2023  ankushj@andrew.cmu.edu
#

#
# config:
#  PARTHENON_REPO - url of git repository
#  PARTHENON_TAG  - tag to checkout of git
#  PARTHENON_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET parthenon)

umbrella_defineopt (PARTHENON_REPO "https://github.com/anku94/parthenon.git"
     STRING "PARTHENON GIT repository")
umbrella_defineopt (PARTHENON_TAG "develop" STRING "PARTHENON GIT tag")
umbrella_defineopt (PARTHENON_TAR "parthenon-${PARTHENON_TAG}.tar.gz"
     STRING "PARTHENON cache tar file")
#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (PARTHENON_DOWNLOAD parthenon
                   ${PARTHENON_TAR}
                   GIT_REPOSITORY ${PARTHENON_REPO}
                   GIT_TAG ${PARTHENON_TAG})
umbrella_patchcheck (PARTHENON_PATCHCMD parthenon)
# TODO: hook up tests (also add to ExternalProject_Add)
# umbrella_testcommand (parthenon PARTHENON_TESTCMD
#                       ctest -R preload -V )

#
# depends
#
set (PARTHENON_DEPENDS amr-tools)
include (umbrella/amr-tools)

if (NOT PARTHENON_DISABLE_HDF5)
    set (PARTHENON_DEPENDS ${PARTHENON_DEPENDS} hdf5)
endif()

if (PARTHENON_DISABLE_OPENMP) 
  set (KOKKOS_ENABLE_OPENMP OFF)
else()
  set (KOKKOS_ENABLE_OPENMP ON)
endif()

set (PARTHENON_CMAKE_ARGS 
  -DBUILD_SHARED_LIBS=ON 
  -DTAU_ROOT=${CMAKE_INSTALL_PREFIX}
  -DPARTHENON_DISABLE_HDF5=${PARTHENON_DISABLE_HDF5} 
  -DPARTHENON_DISABLE_OPENMP=${PARTHENON_DISABLE_OPENMP}
  -DPARTHENON_ENABLE_TESTING=OFF
  -DKokkos_ENABLE_OPENMP=${Kokkos_ENABLE_OPENMP})

if (UMBRELLA_MPI_DEPS)
    include (umbrella/${UMBRELLA_MPI_DEPS})
endif()

#
# create parthenon target
#
ExternalProject_Add (parthenon
    DEPENDS ${PARTHENON_DEPENDS}
    ${PARTHENON_DOWNLOAD} ${PARTHENON_PATCHCMD}
    CMAKE_ARGS ${PARTHENON_CMAKE_ARGS}
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET parthenon)
