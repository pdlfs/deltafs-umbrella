#
# mercury.cmake  umbrella for mercury HPC RPC package
# 28-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  MERCURY_REPO - url of git repository
#  MERCURY_TAG  - tag to checkout of git
#  MERCURY_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET mercury)

#
# variables that users can set
#
set (MERCURY_REPO "https://github.com/mercury-hpc/mercury.git" CACHE
     STRING "MERCURY GIT repository")
set (MERCURY_TAG "0e810a91" CACHE STRING "BMI GIT tag")  # Sep 2017
set (MERCURY_TAR "mercury-${MERCURY_TAG}.tar.gz"
     CACHE STRING "MERCURY cache tar file")

#
# non-na options
#
set (MERCURY_OPA "OFF" CACHE BOOL "Force use of OPA atomic lib")
set (MERCURY_POST_LIMIT "ON" CACHE BOOL "Enable post limit")
set (MERCURY_SELF_FORWARD "OFF" CACHE BOOL "Enable self forward thread")

#
# XXXCDC: bmi always installs under .so, cci uses ${suf} (below)
#
set (MERCURY_SUFF "${CMAKE_SHARED_LIBRARY_SUFFIX}")  # ".so" / ".dylib"

# NA's -- this allows us to select initial defaults with MERCURY_NALIST
umbrella_onlist (MERCURY_NALIST bmi MERCURY_DEFBMI)
umbrella_onlist (MERCURY_NALIST cci MERCURY_DEFCCI)
umbrella_onlist (MERCURY_NALIST ofi MERCURY_DEFOFI)
umbrella_onlist (MERCURY_NALIST sm  MERCURY_DEFSM)

set (MERCURY_BMI ${MERCURY_DEFBMI} CACHE BOOL "Enable Mercury bmi na")
set (MERCURY_CCI ${MERCURY_DEFCCI} CACHE BOOL "Enable Mercury cci na")
set (MERCURY_OFI ${MERCURY_DEFOFI} CACHE BOOL "Enable Mercury ofi na")
set (MERCURY_SM  ${MERCURY_DEFSM}  CACHE BOOL "Enable Mercury sm na")

# generic mercury cmake options
set (MERCURY_CMAKE_ARGS -DNA_USE_MPI=OFF -DNA_USE_SM=${MERCURY_SM}
     -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=${UMBRELLA_BUILD_TESTS}
     -DMERCURY_USE_OPA:BOOL=${MERCURY_OPA}
     -DMERCURY_USE_SELF_FORWARD:BOOL=${MERCURY_SELF_FORWARD}
     -DMERCURY_ENABLE_POST_LIMIT:BOOL=${MERCURY_POST_LIMIT}
     -DMERCURY_USE_BOOST_PP=ON -DMERCURY_USE_CHECKSUMS:BOOL=OFF
     -DNA_USE_BMI=${MERCURY_BMI} -DNA_USE_CCI=${MERCURY_CCI}
     -DNA_USE_OFI=${MERCURY_OFI})

# now handle the NAs
if (MERCURY_BMI)
    list (APPEND MERCURY_DEPENDS bmi)
    list (APPEND MERCURY_CMAKE_ARGS
          -DBMI_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include
          -DBMI_LIBRARY=${CMAKE_INSTALL_PREFIX}/lib/libbmi.so )
    include (umbrella/bmi)
endif (MERCURY_BMI)

if (MERCURY_CCI)
    list (APPEND MERCURY_DEPENDS cci)
    list (APPEND MERCURY_CMAKE_ARGS
          -DNA_CCI_USE_POLL:BOOL=ON
          -DCCI_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include
          -DCCI_LIBRARY=${CMAKE_INSTALL_PREFIX}/lib/libcci${MERCURY_SUFF} )
    include (umbrella/cci)
endif (MERCURY_CCI)

if (MERCURY_OFI)
    list (APPEND MERCURY_DEPENDS ofi)
    include (umbrella/ofi)
endif (MERCURY_OFI)

#
# report config to user
#
message (STATUS "  Mercury config:")
message (STATUS "    HG self-forward: ${MERCURY_SELF_FORWARD}")
message (STATUS "    HG post limit: ${MERCURY_POST_LIMIT}")
message (STATUS "    HG force OPA: ${MERCURY_OPA}")
message (STATUS "    NAs: bmi=${MERCURY_BMI} cci=${MERCURY_CCI}")
message (STATUS "    NAs: ofi=${MERCURY_OFI} sm=${MERCURY_SM}")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (MERCURY_DOWNLOAD mercury ${MERCURY_TAR}
                   GIT_REPOSITORY ${MERCURY_REPO}
                   GIT_TAG ${MERCURY_TAG})
umbrella_patchcheck (MERCURY_PATCHCMD mercury)

#
# create mercury target
#
ExternalProject_Add (mercury
    DEPENDS ${MERCURY_DEPENDS}
    ${MERCURY_DOWNLOAD} ${MERCURY_PATCHCMD}
    CMAKE_ARGS ${MERCURY_CMAKE_ARGS}
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""

  # XXX: not all tests run, so no TEST_COMMAND for now
  #ctest -E 'mercury_bulk_cci_tcp|mercury_bulk_seg_cci_tcp|mercury_posix_cci_tcp'
  # some issues with cci/tcp transport
)

endif (NOT TARGET mercury)
