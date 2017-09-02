#
# CMakeLists.txt  build deltafs and its environment
# 20-Sep-2016  chuck@ece.cmu.edu
#

# command line config:
#
# -DCMAKE_INSTALL_PREFIX=/tmp/delta       # where to install
#                                         # defaults to /usr/local
#

#
# [optional config vars]
#
# -DCMAKE_BUILD_TYPE=RelWithDebInfo       # or Release, Debug, etc.
#     (this only gets reflected to cmake-based external builds,
#      it isn't applied to autotools-based builds...)
#
# -DSKIP_TESTS=OFF                    # skip running unit tests
# -DDELTAFS_VERBOSE=0                 # how verbose deltafs will be
#     (set to zero to disable verbose prints)
#
# -DVERBS=OFF                         # build with verbs
# -DVERBS_PREFIX=dir                  # prefix path (optional)
# -DVERBS_LIBDIR=dir                  # lib directory override (optional)
# -DGNI=OFF                           # build with GNI
# -DGNI_PREFIX=dir                    # prefix path (optional)
# -DGNI_LIBDIR=dir                    # lib directory override (optional)
#
# finding dependencies:
#
# -DCMAKE_PREFIX_PATH='/pkg'              # look for additional installs here
#
# the following also applies for configure scripts:
# -DCMAKE_INCLUDE_PATH='/pkg/include'     # extra include directories
# -DCMAKE_LIBRARY_PATH='/pkg/lib'         # extra library path
#
# note these are all cmake lists (so more than one directory can
# be specified).
#
# specifying alternate compilers (overrides CC/CXX environment variables):
# -DCC=/bin/cc
# -DCXX=/bin/cxx
#  (you can also use the long form names CMAKE_C_COMPILER/CMAKE_CXX_COMPILER)
#
# specifying which mpi to use by pointing at the wrappers:
# -DMPI_C_COMPILER=/usr/bin/mpicc
# -DMPI_CXX_COMPILER=/usr/bin/mpicxx
# -DMPIEXEC=/usr/bin/mpiexec
#
cmake_minimum_required (VERSION 3.0)
if(POLICY CMP0054)
    # avoid warn from CMakeDetermineCompilerABI about an "if" with ${CXX}
    # can be removed once cmake 3.1 is required
    cmake_policy(SET CMP0054 NEW)
endif()

#
# if CC/CXX is specified from the command line (vs. environment vars)
# we copy them to CMAKE_{C,CXX}_COMPILER early (before 'project') so
# that we probe the desired compiler.   note that cmake already honors
# ENV{CC}/ENV{CXX} so we don't need to do anything for those vars.
#
if (CC)
    set (CMAKE_C_COMPILER ${CC})
endif ()
if (CXX)
    set (CMAKE_CXX_COMPILER ${CXX})
endif ()

#
# XXX: we are marking the deltafs-umbrella as using C/CXX because we
# need that in order to probe for MPI.  and we need to probe for MPI
# in order to pass the MPI compiler wrapper programs in on configuration
# command lines....   that's why we also find the MPI package.
#
project (deltafs-umbrella C CXX)
include (ExternalProject)
find_package (MPI MODULE REQUIRED)

#
# set default build type and insert it to cache.  add additional options.
#
if (NOT CMAKE_BUILD_TYPE)
    set (CMAKE_BUILD_TYPE RelWithDebInfo
         CACHE STRING "Choose the type of build." FORCE)
    set_property (CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
                  "Debug" "Release" "RelWithDebInfo" "MinSizeRel")
endif ()
set (SKIP_TESTS "OFF" CACHE BOOL "skip running unit tests")
set (BUILD_TESTS "ON" CACHE BOOL "if go build unit tests")
set (DELTAFS_VERBOSE "0" CACHE STRING "deltafs verbose level")
set_property (CACHE DELTAFS_VERBOSE PROPERTY STRINGS "0"
              "1" "2" "3" "4" "5" "6" "7" "8" "9" "10")
set (SELF_FORWARD "OFF" CACHE BOOL "enable mercury to forward rpc to itself")
set (POST_LIMIT "ON" CACHE BOOL "allow mercury to limit incoming rpcs")
set (FORCE_OPA "OFF" CACHE BOOL "force mercury to use OPA atomic primitives")
set (GNI "OFF" CACHE BOOL "build with GNI")
set (GNI_PREFIX "" CACHE PATH "GNI prefix path (optional)")
set (GNI_LIBDIR "" CACHE PATH "GNI lib directory override (optional)")
set (VERBS "OFF" CACHE BOOL "build with verbs")
set (VERBS_PREFIX "" CACHE PATH "VERBS prefix path (optional)")
set (VERBS_LIBDIR "" CACHE PATH "VERBS lib directory override (optional)")

#
# MY_PDLFS_OPTIONS: our deltafs-common (aka pdlfs-common) settings...
# these should match deltafs
#
set (MY_PDLFS_OPTIONS -DPDLFS_MERCURY_RPC=ON -DPDLFS_SNAPPY=OFF
                      -DPDLFS_GFLAGS=OFF -DPDLFS_GLOG=OFF
                      -DPDLFS_VERBOSE=${DELTAFS_VERBOSE} )

#
# print the current config so users are aware of the current settings...
#
message (STATUS "Current Umbrella settings:")
message (STATUS "  target OS: ${CMAKE_SYSTEM_NAME} "
                             "${CMAKE_SYSTEM_VERSION}")
message (STATUS "  host OS: ${CMAKE_HOST_SYSTEM_NAME} "
                           "${CMAKE_HOST_SYSTEM_VERSION}")
message (STATUS "  build type: ${CMAKE_BUILD_TYPE}")
message (STATUS "  CXX compiler: ${CMAKE_CXX_COMPILER} "
                  "(${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION})")
message (STATUS "  MPI CXX wrapper:  ${MPI_CXX_COMPILER}")
message (STATUS "  C compiler: ${CMAKE_C_COMPILER} "
                  "(${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION})")
message (STATUS "  MPI C wrapper:  ${MPI_C_COMPILER}")
message (STATUS "  crosscompiling: ${CMAKE_CROSSCOMPILING}")
message (STATUS "  transport config: verbs=${VERBS}, GNI=${GNI}")
message (STATUS "    gni hints: prefix=${GNI_PREFIX}, libs=${GNI_LIBDIR}")
message (STATUS "    verbs hints: prefix=${VERBS_PREFIX}, libs=${VERBS_LIBDIR}")
message (STATUS "  build tests: ${BUILD_TESTS} (skip running: ${SKIP_TESTS})")
message (STATUS "  HG self-forward rpc: ${SELF_FORWARD}")
message (STATUS "  HG post limit: ${POST_LIMIT}")
message (STATUS "  HG force OPA: ${FORCE_OPA}")

#
# GenDownloadConfig (result target local-file remote-args ...)
#
# get file locally if present, otherwise download it using remote-args.
#
function (GenDownloadConfig result target local)
    if (EXISTS "${CMAKE_SOURCE_DIR}/cache/${local}")
        message (STATUS "${target}: using cache (${local})")
        # assume correct, but set URL_MD5 to quiet warning
        file (MD5 "${CMAKE_SOURCE_DIR}/cache/${local}" localmd5)
        set (${result} URL "${CMAKE_SOURCE_DIR}/cache/${local}"
                       URL_MD5 ${localmd5} PARENT_SCOPE)
    else ()
        set (${result} ${ARGN} PARENT_SCOPE)
    endif ()
endfunction ()

#
# MaybeRunTests (result test-args ...)
#
# generate test-args output only if 1) we are not cross compiling (so we
# can avoid trying to run target crosscompiled binaries on the host),
# and 2) skip_tests are not set.
#
function (MaybeRunTests result)
    if (NOT ${CMAKE_CROSSCOMPILING} AND NOT ${SKIP_TESTS})
        set (${result} ${ARGN} PARENT_SCOPE)
    else ()
        set (${result} "" PARENT_SCOPE)
    endif ()
endfunction ()

#
# set up the prefix path for packaged software that we may want to
# link to (e.g. third party libraries).   this will get added to
# the configure command line (for autotools-based projects).
#
# we also want our install prefix to be in the prefix path too (it
# isn't by default).
#
list (APPEND CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
list (REMOVE_DUPLICATES CMAKE_PREFIX_PATH)
foreach (prefix ${CMAKE_PREFIX_PATH})
    list (APPEND CMAKE_INCLUDE_PATH "${prefix}/include")
    list (APPEND CMAKE_LIBRARY_PATH "${prefix}/lib")
endforeach ()
list (REMOVE_DUPLICATES CMAKE_INCLUDE_PATH)
list (REMOVE_DUPLICATES CMAKE_LIBRARY_PATH)

#
# build command-line variable settings for autotools configure scripts.
# we reflect the cmake settings (including prefixes) down to the
# configure script via CPPFLAGS, LDFLAGS, CC, AND CXX.
#
if (CMAKE_INCLUDE_PATH)
  foreach (inc ${CMAKE_INCLUDE_PATH})
      set (cppflags "${cppflags} -I${inc}")
  endforeach ()
  string (SUBSTRING ${cppflags} 1 -1 cppflags)   # remove leading space
  set (cppflags "CPPFLAGS=${cppflags}")
endif ()
if (CMAKE_LIBRARY_PATH)
  foreach (lib ${CMAKE_LIBRARY_PATH})
      set (ldflags "${ldflags} -L${lib}")
  endforeach ()
  string (SUBSTRING ${ldflags} 1 -1 ldflags)
  set (ldflags "LDFLAGS=${ldflags}")
endif ()
# compiler settings, the second one is to force an mpi wrapper based compile.
set (ac_comp CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER})
set (ac_mpicomp CC=${MPI_C_COMPILER} CXX=${MPI_CXX_COMPILER})

# some systems have this set, so we need to add to it
if (DEFINED ENV{PKG_CONFIG_PATH})
  set (ac_pkgpath
    "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
else ()
  set (ac_pkgpath "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig")
endif ()
set (ac_pkgcfgpath "PKG_CONFIG_PATH=${ac_pkgpath}")

#
# setup variables to init the cache of cmake-based projects.   we want
# these values to propagate from the umbrella on down...
#
set (init_cm_cache
                -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
                -DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}
                -DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}
                -DCMAKE_INSTALL_PREFIX:STRING=${CMAKE_INSTALL_PREFIX}
                -DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}
                -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY:BOOL=1
     )

#
# now we are ready to start building packages
#

#
# CCI.  we used to enable verbs if we found libs and headers, but that
# caused problems on the cray, plus we needed to add gni, so now we just
# let the user specify what do on the command line or via ccmake.
#
if (GNI)
    if (GNI_PREFIX)
        set (cci_gni "--with-gni=${GNI_PREFIX}")
    else ()
        set (cci_gni "--with-gni")
    endif ()
    if (GNI_LIBDIR)
        set (cci_gni "${cci_gni} --with-gni-libdir=${GNI_LIBDIR}")
    endif ()
else ()
    set (cci_gni "--without-gni")
endif ()
if (VERBS)
    if (VERBS_PREFIX)
        set (cci_verbs "--with-verbs=${VERBS_PREFIX}")
    else ()
        set (cci_verbs "--with-verbs")
    endif ()
    if (VERBS_LIBDIR)
        set (cci_verbs "${cci_verbs} --with-verbs-libdir=${VERBS_LIBDIR}")
    endif ()
else ()
    set (cci_verbs "--without-verbs")
endif ()
message (STATUS "CCI transport config: ${cci_gni} ${cci_verbs}")

set (ccipatch "${CMAKE_SOURCE_DIR}/patches/cci-patch")
if (EXISTS ${ccipatch})
    set (ccipatchcmd patch -p1 -i ${ccipatch} -d <SOURCE_DIR>)
endif ()

GenDownloadConfig (cci_download cci cci-3ab663e0.tar.gz
    ### URL http://cci-forum.com/wp-content/uploads/2016/06/cci-2.0.tar.gz
    ### URL_MD5 070b2ba4eca92a846c093f2cd000d3b2
    TIMEOUT 100
    GIT_REPOSITORY "https://github.com/CCI/cci"
    GIT_TAG 3ab663e0   # old
    ###GIT_TAG 4e655d1       # for verbs to kind of work
    ### GIT_TAG master
)

ExternalProject_Add (cci
    ${cci_download}
    PATCH_COMMAND ${ccipatchcmd}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${ac_comp} ${cppflags} ${ldflags}
         --prefix=${CMAKE_INSTALL_PREFIX} ${cci_gni} ${cci_verbs}
    UPDATE_COMMAND ""
)

ExternalProject_Add_Step(cci prepare
    COMMAND ${CMAKE_SOURCE_DIR}/scripts/ensure-autogen <SOURCE_DIR>/autogen.pl
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>
)

#
# BMI
#
set (bmipatch "${CMAKE_SOURCE_DIR}/patches/bmi-${CMAKE_SYSTEM_NAME}-patch")
if (EXISTS ${bmipatch})
    set (bmipatchcmd patch -i ${bmipatch} -d <SOURCE_DIR>)
endif ()

GenDownloadConfig (bmi_download bmi bmi-cb70e870.tar.gz
    GIT_REPOSITORY "http://git.mcs.anl.gov/bmi.git"
    GIT_TAG cb70e870		# Dec 2016
    ### GIT_TAG master
)

ExternalProject_Add (bmi
    ${bmi_download}
    PATCH_COMMAND ${bmipatchcmd}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${ac_comp}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared --enable-bmi-only
    UPDATE_COMMAND ""
)

ExternalProject_Add_Step(bmi prepare
    COMMAND ${CMAKE_SOURCE_DIR}/scripts/ensure-autogen <SOURCE_DIR>/prepare
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>
)

#
# mercury
#
# XXXCDC: bmi always installs under .so, cci uses ${suf} (below)
set (suf "${CMAKE_SHARED_LIBRARY_SUFFIX}")  # ".so" ".dylib"

GenDownloadConfig (mercury_download mercury mercury-4fc4473c.tar.gz
    GIT_REPOSITORY "https://github.com/mercury-hpc/mercury.git"
    GIT_TAG 4fc4473c  # Aug 2017
    ### GIT_TAG master
)

ExternalProject_Add (mercury
    DEPENDS cci bmi
    ${mercury_download}
    CMAKE_ARGS -DNA_USE_MPI=OFF -DNA_USE_BMI=ON -DNA_USE_CCI=ON -DNA_USE_SM=ON
               -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=${BUILD_TESTS}
               -DMERCURY_USE_OPA:BOOL=${FORCE_OPA}
               -DMERCURY_USE_SELF_FORWARD:BOOL=${SELF_FORWARD}
               -DMERCURY_ENABLE_POST_LIMIT:BOOL=${POST_LIMIT}
               -DMERCURY_USE_BOOST_PP=ON -DMERCURY_USE_CHECKSUMS:BOOL=OFF
               -DBMI_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include
               -DBMI_LIBRARY=${CMAKE_INSTALL_PREFIX}/lib/libbmi.so
               -DNA_CCI_USE_POLL:BOOL=ON
               -DCCI_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include
               -DCCI_LIBRARY=${CMAKE_INSTALL_PREFIX}/lib/libcci${suf}
    CMAKE_CACHE_ARGS ${init_cm_cache}
    UPDATE_COMMAND ""

# XXX: to turn back off CCI, remove it from DEPENDS (above), turn back off
# NA_USE_CCI, and then remove flags: NA_CCI_USE_POLL, CCI_*

# XXX: not all tests run, so no TEST_COMMAND for now
#ctest -E 'mercury_bulk_cci_tcp|mercury_bulk_seg_cci_tcp|mercury_posix_cci_tcp'
# some issues with cci/tcp transport

)

#
# ch-placement
#
GenDownloadConfig (chp_download ch-placement ch-placement-0b706ca06.tar.gz
    GIT_REPOSITORY "http://xgitlab.cels.anl.gov/codes/ch-placement.git"
    GIT_TAG 0b706ca06		# Dec 2016
    ### GIT_TAG master
)

MaybeRunTests (chp_test
    TEST_COMMAND make check
)

ExternalProject_Add (ch-placement
    ${chp_download}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${ac_comp}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared
    UPDATE_COMMAND ""
    ${chp_test}
)

ExternalProject_Add_Step(ch-placement prepare
    COMMAND ${CMAKE_SOURCE_DIR}/scripts/ensure-autogen <SOURCE_DIR>/prepare
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>
)

#
# ssg
#
GenDownloadConfig (ssg_download ssg ssg-0164e690.tar.gz
    GIT_REPOSITORY "https://github.com/pdlfs/ssg.git"
    GIT_TAG 0164e690
    ##GIT_TAG master
)

ExternalProject_Add (ssg
    DEPENDS mercury
    ${ssg_download}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${ac_mpicomp} ${ac_pkgcfgpath}
                      --prefix=${CMAKE_INSTALL_PREFIX} --enable-shared
    UPDATE_COMMAND ""
)

ExternalProject_Add_Step (ssg prepare
    COMMAND ${CMAKE_SOURCE_DIR}/scripts/ensure-autogen <SOURCE_DIR>/prepare.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    WORKING_DIRECTORY <SOURCE_DIR>
)

#
# deltafs-common (aka the deltafs version of pdlfs-common)
#
GenDownloadConfig (deltafs-common_download deltafs-common
                   deltafs-common-5b6f919.tar.gz
    GIT_REPOSITORY "https://github.com/pdlfs/pdlfs-common.git"
    GIT_TAG v17.3
    ### GIT_TAG master
)

MaybeRunTests (deltafs-common_test
    TEST_COMMAND ctest -E "gigaplus_test|autocompact_test|db_test|index_block_test"
)

ExternalProject_Add (deltafs-common
    DEPENDS mercury
    ${deltafs-common_download}
    CMAKE_ARGS ${MY_PDLFS_OPTIONS}
               -DBUILD_SHARED_LIBS=ON
               -DBUILD_TESTS=${BUILD_TESTS}
               -DPDLFS_COMMON_LIBNAME=deltafs-common
               -DPDLFS_COMMON_DEFINES=DELTAFS
    CMAKE_CACHE_ARGS ${init_cm_cache}
    UPDATE_COMMAND ""
    ${deltafs-common_test}
)

#
# deltafs-bb
#
GenDownloadConfig (deltafsbb_download deltafs-bb deltafs-bb-f9040bd1.tar.gz
    GIT_REPOSITORY "https://github.com/pdlfs/deltafs-bb.git"
    GIT_TAG f9040bd1  # May 2017
    ### GIT_TAG master
)

ExternalProject_Add (deltafs-bb
    DEPENDS mercury
    ${deltafsbb_download}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${init_cm_cache}

    UPDATE_COMMAND ""
)

#
# deltafs
#
GenDownloadConfig (deltafs_download deltafs deltafs-a30dd43.tar.gz
    GIT_REPOSITORY "https://github.com/pdlfs/deltafs.git"
    GIT_TAG v2017.8.2
    ### GIT_TAG master
)

MaybeRunTests (deltafs_test
    TEST_COMMAND ctest -E "gigaplus_test|autocompact_test|db_test|index_block_test"
)

ExternalProject_Add (deltafs
    DEPENDS mercury deltafs-common deltafs-bb
    ${deltafs_download}
    CMAKE_ARGS ${MY_PDLFS_OPTIONS}
               -DBUILD_SHARED_LIBS=ON
               -DBUILD_TESTS=${BUILD_TESTS}
               -DDELTAFS_COMMON_INTREE=OFF
               -DMPI_CXX_COMPILER=${MPI_CXX_COMPILER}
               -DMPI_C_COMPILER=${MPI_C_COMPILER}
               -DDELTAFS_MPI=ON
    CMAKE_CACHE_ARGS ${init_cm_cache}
    UPDATE_COMMAND ""
    ${deltafs_test}
)

#
# deltafs-nexus
#
GenDownloadConfig (deltafs-nexus_download deltafs-nexus
                   deltafs-nexus.tar.gz
    GIT_REPOSITORY "https://github.com/pdlfs/deltafs-nexus.git"
    GIT_TAG v1.2
    ### GIT_TAG master
)

MaybeRunTests (deltafs-nexus_test
    ### TEST_COMMAND ctest -R nexus -V
    TEST_COMMAND ""
)

ExternalProject_Add (deltafs-nexus
    DEPENDS mercury
    ${deltafs-nexus_download}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${init_cm_cache}

    UPDATE_COMMAND ""
    ${deltafs-nexus_test}
)

#
# deltafs-vpic-preload
#
GenDownloadConfig (deltafs-vpic-preload_download deltafs-vpic-preload
                   deltafs-vpic-preload-v1.4b.tar.gz
    GIT_REPOSITORY "https://github.com/pdlfs/deltafs-vpic-preload.git"
    GIT_TAG v1.16
    ### GIT_TAG master
)

MaybeRunTests (deltafs-vpic-preload_test
    TEST_COMMAND ctest -R preload -V
)

ExternalProject_Add (deltafs-vpic-preload
    DEPENDS deltafs deltafs-nexus ch-placement ssg
    ${deltafs-vpic-preload_download}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${init_cm_cache}

    UPDATE_COMMAND ""
    ${deltafs-vpic-preload_test}
)

#
# vpic
#
GenDownloadConfig (vpic_download vpic vpic-6a9efff8.tar.gz
    GIT_REPOSITORY "https://github.com/pdlfs/vpic.git"
    GIT_TAG d74ac54  # Jul 2017
    ### GIT_TAG master
)

ExternalProject_Add (vpic
    DEPENDS deltafs           # XXX: just to make it build deltafs first
    ${vpic_download}

    # TODO: This code makes me sad, but then again this VPIC version
    #       also makes me sad. Feel free to fix.

    CONFIGURE_COMMAND cd <SOURCE_DIR> && ./config/bootstrap
        COMMAND <SOURCE_DIR>/prep_conf.sh <SOURCE_DIR>
        COMMAND <SOURCE_DIR>/configure ${ac_mpicomp}
                --prefix=${CMAKE_INSTALL_PREFIX}
                --with-machine=<SOURCE_DIR>/machine.conf

    # We only compile a sample deck here to ensure build.op was properly
    # put together.

    BUILD_COMMAND make
        COMMAND cd <SOURCE_DIR> &&
        <BINARY_DIR>/build.op decks/trecon-part/turbulence.cxx

    INSTALL_COMMAND make install
        COMMAND rm -rf ${CMAKE_INSTALL_PREFIX}/decks
        COMMAND cp -r <SOURCE_DIR>/decks ${CMAKE_INSTALL_PREFIX}
        COMMAND cp -r <SOURCE_DIR>/src/deck_wrapper.cxx
                                  ${CMAKE_INSTALL_PREFIX}/decks
        COMMAND cp -r <SOURCE_DIR>/src/main.cxx ${CMAKE_INSTALL_PREFIX}/decks
        COMMAND cp -r <BINARY_DIR>/vpic-build.op ${CMAKE_INSTALL_PREFIX}/bin
    UPDATE_COMMAND ""
)

#
# sndrcv-test (XXX: to be replaced with mercury-runner)
#
GenDownloadConfig (sndrcv_download sndrcv-test sndrcv-test-0bdb4dcc.tar.gz
    GIT_REPOSITORY "https://github.com/chuckcranor/sndrcv-test.git"
    ### GIT_TAG 0bdb4dcc		# Feb 2017
    ### GIT_TAG master
)

ExternalProject_Add (sndrcv-test
    DEPENDS deltafs-vpic-preload vpic     # to make it compile at the end
    ${sndrcv_download}
    ### CMAKE_ARGS -Dsomething=value
    CMAKE_CACHE_ARGS ${init_cm_cache}

    UPDATE_COMMAND ""
    # this is a test, no test command.
)

# only do sndrcv-test if we directly asked for it
set_property (TARGET sndrcv-test PROPERTY EXCLUDE_FROM_ALL True)

#
# mercury-runner
#
GenDownloadConfig (mrun_download mercury-runner mercury-runner-2624612c.tar.gz
    GIT_REPOSITORY "https://github.com/pdlfs/mercury-runner.git"
    GIT_TAG 2624612c
    ### GIT_TAG master
)

ExternalProject_Add (mercury-runner
    DEPENDS mercury
    ${mrun_download}
    ### CMAKE_ARGS -Dsomething=value
    CMAKE_CACHE_ARGS ${init_cm_cache}

    UPDATE_COMMAND ""
    # this is a test, no test command.
)

#
# trecon-reader -- actually lives in vpic but uses cmake
#
ExternalProject_Add (trecon-reader
    DEPENDS vpic
    DOWNLOAD_COMMAND true    # no need to download, comes with vpic
    SOURCE_DIR ${CMAKE_BINARY_DIR}/vpic-prefix/src/vpic/decks/trecon-reader
    CMAKE_CACHE_ARGS ${init_cm_cache}

    UPDATE_COMMAND ""
)

#
# scripts -- live in deltafs-umbrella
#
ExternalProject_Add (scripts
    DOWNLOAD_COMMAND true    # no need to download, comes with umbrella
    SOURCE_DIR ${CMAKE_SOURCE_DIR}/scripts
    CMAKE_CACHE_ARGS ${init_cm_cache}

    UPDATE_COMMAND ""
)

