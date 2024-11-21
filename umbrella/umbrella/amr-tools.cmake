#
# amr-tools.cmake  umbrella for amr-tools
# 10-May-2023  ankushj@andrew.cmu.edu
#

#
# config:
#  AMR_TOOLS_REPO - url of git repository
#  AMR_TOOLS_TAG  - tag to checkout of git
#  AMR_TOOLS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET amr-tools)

umbrella_defineopt (AMR_TOOLS_REPO "https://github.com/anku94/amr.git"
     STRING "AMR_TOOLS GIT repository")
umbrella_defineopt (AMR_TOOLS_TAG "main" STRING "AMR_TOOLS GIT tag")
umbrella_defineopt (AMR_TOOLS_TAR "amr-tools-${AMR_TOOLS_TAG}.tar.gz"
     STRING "AMR_TOOLS cache tar file")

umbrella_defineopt(AMR_TOOLS_GUROBI OFF BOOL "Build amr-tools with Gurobi")
umbrella_defineopt(AMR_TOOLS_TAU OFF BOOL "Build amr-tools with TAU")

umbrella_defineopt (AMR_TOOLS_OWNMPI OFF BOOL "Use mpirun in install tree")
#
# depends
#

set (AMR_CMCACHE "${UMBRELLA_CMAKECACHE}")

set(AMR_TOOLS_DEPENDS glog kokkos pdlfs-common)

include (umbrella/glog)
include (umbrella/kokkos)
include (umbrella/pdlfs-common)

if (UMBRELLA_MPI_DEPS)
  include (umbrella/${UMBRELLA_MPI_DEPS})
  list(APPEND AMR_TOOLS_DEPENDS ${UMBRELLA_MPI_DEPS})
  list (APPEND AMR_CMCACHE -DAMR_TOOLS_OWNMPI:STRING=1)
endif()

if (AMR_TOOLS_GUROBI)
  include (umbrella/gurobi)
  list(APPEND AMR_TOOLS_DEPENDS gurobi)
endif (AMR_TOOLS_GUROBI)

if (AMR_TOOLS_TAU)
  include (umbrella/tau)
  list(APPEND AMR_TOOLS_DEPENDS tau)
  list (APPEND AMR_CMCACHE -DTAU_ROOT:STRING=${CMAKE_INSTALL_PREFIX})
endif (AMR_TOOLS_TAU)

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (AMR_TOOLS_DOWNLOAD amr-tools
                   ${AMR_TOOLS_TAR}
                   GIT_REPOSITORY ${AMR_TOOLS_REPO}
                   GIT_TAG ${AMR_TOOLS_TAG})
umbrella_patchcheck (AMR_TOOLS_PATCHCMD amr-tools)
# TODO: hook up tests (also add to ExternalProject_Add)
# umbrella_testcommand (amr-tools AMR_TOOLS_TESTCMD
#                       ctest -R preload -V )


#
# create amr-tools target
#
ExternalProject_Add (amr-tools
    DEPENDS ${AMR_TOOLS_DEPENDS}
    ${AMR_TOOLS_DOWNLOAD} ${AMR_TOOLS_PATCHCMD}
    CMAKE_CACHE_ARGS ${AMR_CMCACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET amr-tools)
