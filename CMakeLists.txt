#
# Copyright (c) 2019 Carnegie Mellon University,
# Copyright (c) 2019 Triad National Security, LLC, as operator of
#     Los Alamos National Laboratory.
#
# All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.
#

#
# CMakeLists.txt  build deltafs and its environment
# 20-Sep-2016  chuck@ece.cmu.edu
#

#
# general command line config:
#
#   -DCMAKE_INSTALL_PREFIX=/usr/local     # installation prefix
#   -DCMAKE_BUILD_TYPE=RelWithDebInfo     # or Release, Debug, etc.
#      (XXX: currently only applied to cmake-based builds)
#
#   -DUMBRELLA_BUILD_TESTS=ON             # build unit tests?
#   -DUMBRELLA_SKIP_TESTS=OFF             # skip running unit tests?
#
# finding dependencies:
#
#   -DCMAKE_PREFIX_PATH='/pkg'            # look for additional installs here
#
# the following also applies for configure scripts:
#   -DCMAKE_INCLUDE_PATH='/pkg/include'   # extra include directories
#   -DCMAKE_LIBRARY_PATH='/pkg/lib'       # extra library path
#
# note these are all cmake lists (so more than one directory can
# be specified using a semicolon to create a path).
#
# specifying alternate compilers (overrides CC/CXX environment variables):
#   -DCC=/bin/cc
#   -DCXX=/bin/cxx
#
#   you may also use the longer names
#     -DCMAKE_C_COMPILER
#     -DCMAKE_CXX_COMPILER
#
# specifying which mpi to use by pointing at the wrappers:
#   -DMPI_C_COMPILER=/usr/bin/mpicc
#   -DMPI_CXX_COMPILER=/usr/bin/mpicxx
#   -DMPIEXEC=/usr/bin/mpiexec
#

cmake_minimum_required (VERSION 3.0)

#
# put the umbrella scripts in our search path and include umbrella-init
# (umbrella-init needs to run before "project")
#
list (APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/umbrella")
include (umbrella-init)

#
# we don't really use MPICXX for now. The difference between CXX and MPICXX
# is that CXX refers to the MPI C API being usable from C++, whereas MPICXX
# refers to the MPI-2 C++ API that was removed again in MPI-3.
# To enable MPICXX, run umbrella with -DMPI_CXX_SKIP_MPICXX=Off.
#
set (MPI_CXX_SKIP_MPICXX ON CACHE BOOL "True if MPICXX should be skipped")

#
# need to mark project as using C/CXX so we can probe for MPI
# using a compiler that may have been passed in via the command line
# or by using environment vars.
#
project (deltafs-umbrella C CXX)

#
# configure umbrella for MPI and pull in the main routines
#
set (UMBRELLA_MPI 1)
include (umbrella-main)

#
# propagate the MPICXX setting to all cmake subprojects
#
list(APPEND UMBRELLA_CMAKECACHE -DMPI_CXX_SKIP_MPICXX:BOOL=${MPI_CXX_SKIP_MPICXX})


#
# set git tags to the versions we want to stick to by default...
#
umbrella_opt_default (BMI_TAG "6ea0b78f")             # Jan 2020
umbrella_opt_default (CCI_TAG "3ab663e0")
umbrella_opt_default (CH_PLACEMENT_TAG "97fd3158")    # Jul 2019
umbrella_opt_default (DELTAFS_BB_TAG "8c7091ea")      # Oct 2017
umbrella_opt_default (DELTAFS_COMMON_TAG "v19.8")
umbrella_opt_default (DELTAFS_NEXUS_TAG "v1.19")
umbrella_opt_default (DELTAFS_SHUFFLE_TAG "bba0a2f6") # Feb 2020
umbrella_opt_default (DELTAFS_VPIC_PRELOAD_TAG "8f51d56")
umbrella_opt_default (DELTAFS_TAG "fb28f25")
umbrella_opt_default (MERCURY_PROGRESSOR_TAG "6892c220") # Oct 2020
umbrella_opt_default (MERCURY_RUNNER_TAG "381abae2")  # Oct 2020
umbrella_opt_default (MERCURY_TAG "df2fef78")         # Oct 2020
umbrella_opt_default (MSSG_TAG "v1.4")
umbrella_opt_default (NEXUS_RUNNER_TAG "40003c0d")    # Feb 2020
umbrella_opt_default (OFI_TAG "a593d160")             # Jun 2019
umbrella_opt_default (OSU_MICRO_BENCHMARKS_REPO
          "https://github.com/pdlfs/osu-micro-benchmarks.git")
          # forces a load from git repo
umbrella_opt_default (OSU_MICRO_BENCHMARKS_TAG "v5.6.1")

#
# vpic selection.  vpic407 is the old depreciated vpic code base.
#
set(VPIC407 ON CACHE BOOL "Use depreciate VPIC407 code")
if(VPIC407)
    umbrella_opt_default (VPIC407_TAG "0a1c2c50")         # Aug 2019
    set (my-vpic-inc trecon-reader)                       # pulls vpic407
    set (my-scripts-cache "${UMBRELLA_CMAKECACHE};-DVPIC407:STRING=1")
    message (STATUS "  vpic: vpic 407 selected (depreciated)")
else()
    umbrella_opt_default (VPIC_TAG "master")
    umbrella_opt_default (VPIC_DECKS_TAG "master")
    set (my-vpic-inc vpic-decks)                          # pulls vpic
    set (my-scripts-cache "${UMBRELLA_CMAKECACHE};-DVPIC407:STRING=0")
    message (STATUS "  vpic: vpic main selected")
endif()

#
# any additional cache variables we want to add that are not already
# part of the umbrella?
#
set (DELTAFS_VERBOSE "0" CACHE STRING "deltafs verbose level")
set_property (CACHE DELTAFS_VERBOSE PROPERTY STRINGS "0"
              "1" "2" "3" "4" "5" "6" "7" "8" "9" "10")
message (STATUS "  deltafs_verbose: ${DELTAFS_VERBOSE}")

#
# set other configs before we start pulling in the pieces...
#

# note: NA_INITIALLY_ON is only applied as the defaults the first time
# you run cmake.  if you want to reconfigure, change MERCURY_BMI, et al.
umbrella_opt_default (MERCURY_NA_INITIALLY_ON "bmi;ofi;sm")

set (PDLFS_OPTIONS -DPDLFS_MERCURY_RPC=ON -DPDLFS_SNAPPY=OFF
                   -DPDLFS_GFLAGS=OFF -DPDLFS_GLOG=OFF
                   -DPDLFS_VERBOSE=${DELTAFS_VERBOSE})

include (umbrella/ch-placement)
include (umbrella/deltafs)
include (umbrella/deltafs-bb)
include (umbrella/deltafs-common)
include (umbrella/deltafs-nexus)
include (umbrella/deltafs-shuffle)
include (umbrella/deltafs-vpic-preload)
include (umbrella/mercury)
include (umbrella/mercury-progressor)
include (umbrella/mercury-runner)
include (umbrella/mssg)
include (umbrella/nexus-runner)
include (umbrella/osu-micro-benchmarks)
include (umbrella/${my-vpic-inc})

#
# scripts -- live here in deltafs-umbrella
#
ExternalProject_Add (scripts
    DOWNLOAD_COMMAND true    # no need to download, comes with umbrella
    SOURCE_DIR ${CMAKE_SOURCE_DIR}/scripts
    CMAKE_CACHE_ARGS "${my-scripts-cache}"

    UPDATE_COMMAND ""
)

# don't build osu-micro-benchmarks by default
set_property (TARGET osu-micro-benchmarks PROPERTY EXCLUDE_FROM_ALL True)
