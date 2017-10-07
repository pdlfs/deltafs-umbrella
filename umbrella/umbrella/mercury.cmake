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
#  MERCURY_OPA - force use of OPA atomic lib
#  MERCURY_POST_LIMIT - enable post limit
#  MERCURY_SELF_FORWARD - enable self forward thread
#  MERCURY_CHECKSUM - enable checksuming
#
#  MERCURY_NA_INITIALLY_ON - cmake list of NAs that are initally enabled
#                            the first time cmake is run
#  MERCURY_BMI, MERCURY_CCI, MERCURY_OFI, MERCURY_SM - settings for each NA
#     (they will override MERCURY_NA_INITIALLY_ON)
#

if (NOT TARGET mercury)

#
# umbrella option variables
#
umbrella_defineopt (MERCURY_REPO "https://github.com/mercury-hpc/mercury.git"
     STRING "MERCURY GIT repository")
umbrella_defineopt (MERCURY_TAG "master" STRING "mercury GIT tag")
umbrella_defineopt (MERCURY_TAR "mercury-${MERCURY_TAG}.tar.gz"
     STRING "MERCURY cache tar file")

#
# non-na options
#
umbrella_defineopt (MERCURY_OPA "OFF" BOOL "Force use of OPA atomic lib")
umbrella_defineopt (MERCURY_POST_LIMIT "ON" BOOL "Enable post limit")
umbrella_defineopt (MERCURY_SELF_FORWARD "OFF" BOOL "Enable self forward thread")
umbrella_defineopt (MERCURY_CHECKSUM "OFF" BOOL "Enable checksuming")

#
# XXXCDC: bmi always installs under .so, cci uses ${suf} (below)
#
set (MERCURY_SUFF "${CMAKE_SHARED_LIBRARY_SUFFIX}")  # ".so" / ".dylib"

#
# na options
#
umbrella_defineopt (MERCURY_NA_INITIALLY_ON "bmi;cci;ofi;sm" STRING
     "List of default-enabled NAs")

# use MERCURY_NA_INITIALLY_ON to select initial defaults for each NA
umbrella_onlist (MERCURY_NA_INITIALLY_ON bmi MERCURY_DEFBMI)
umbrella_onlist (MERCURY_NA_INITIALLY_ON cci MERCURY_DEFCCI)
umbrella_onlist (MERCURY_NA_INITIALLY_ON ofi MERCURY_DEFOFI)
umbrella_onlist (MERCURY_NA_INITIALLY_ON sm  MERCURY_DEFSM)

umbrella_defineopt (MERCURY_BMI ${MERCURY_DEFBMI} BOOL "Enable Mercury bmi na")
umbrella_defineopt (MERCURY_CCI ${MERCURY_DEFCCI} BOOL "Enable Mercury cci na")
umbrella_defineopt (MERCURY_OFI ${MERCURY_DEFOFI} BOOL "Enable Mercury ofi na")
umbrella_defineopt (MERCURY_SM  ${MERCURY_DEFSM}  BOOL "Enable Mercury sm na")

# generic mercury cmake options
set (MERCURY_CMAKE_ARGS -DNA_USE_MPI=OFF -DNA_USE_SM=${MERCURY_SM}
     -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=${UMBRELLA_BUILD_TESTS}
     -DMERCURY_USE_OPA:BOOL=${MERCURY_OPA}
     -DMERCURY_USE_SELF_FORWARD:BOOL=${MERCURY_SELF_FORWARD}
     -DMERCURY_ENABLE_POST_LIMIT:BOOL=${MERCURY_POST_LIMIT}
     -DMERCURY_USE_BOOST_PP=ON -DMERCURY_USE_CHECKSUMS:BOOL=${MERCURY_CHECKSUM}
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
