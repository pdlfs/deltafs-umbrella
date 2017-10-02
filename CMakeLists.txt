#
# CMakeLists.txt  build deltafs and its environment
# 20-Sep-2016  chuck@ece.cmu.edu
#

#
# general command line config:
#
#   -DCMAKE_INSTALL_PREFIX=/usr/local      # installation prefix
#   -DCMAKE_BUILD_TYPE=RelWithDebInfo      # or Release, Debug, etc.
#      (XXX: currently only applied to cmake-based builds)
#
#   -DUMBRELLA_BUILD_TESTS=ON              # build unit tests?
#   -DUMBRELLA_SKIP_TESTS=OFF              # skip running unit tests?
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
# be specified using a semicolon to create a path).
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

#
# put the umbrella scripts in our search path and include umbrella-init
# (umbrella-init needs to run before "project")
#
list (APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/umbrella")
include (umbrella-init)

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
# set git tags to the versions we want to stick to by default...
#
umbrella_opt_default (BMI_TAG "cb70e870")             # Dec 2016
umbrella_opt_default (CCI_TAG "3ab663e0")
umbrella_opt_default (CH_PLACEMENT_TAG "0b706ca06")   # Dec 2016
umbrella_opt_default (DELTAFS_BB_TAG "f9040bd1")      # May 2017
umbrella_opt_default (DELTAFS_COMMON_TAG "v17.4")
umbrella_opt_default (DELTAFS_NEXUS_TAG "v1.3")
umbrella_opt_default (DELTAFS_VPIC_PRELOAD_TAG "v1.23")
umbrella_opt_default (DELTAFS_TAG "v2017.9")
umbrella_opt_default (MERCURY_RUNNER_TAG "773e6cc5")  # Sep 2017
umbrella_opt_default (MERCURY_TAG "a26d6f72")         # Sep 2017
umbrella_opt_default (OFI_TAG "v1.5.0")
umbrella_opt_default (SSG_TAG "0164e690")
umbrella_opt_default (VPIC_TAG "d74ac54")             # Jul 2017

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

set (CH_PLACEMENT_REPO "https://github.com/chuckcranor/ch-placement.git"
     CACHE STRING "temp copy of ch-placement GIT repository")

# note: NA_INITIALLY_ON is only applied as the defaults the first time
# you run cmake.  if you want to reconfigure, change MERCURY_BMI, et al.
umbrella_opt_default (MERCURY_NA_INITIALLY_ON "bmi;cci;ofi;sm")

set (PDLFS_OPTIONS -DPDLFS_MERCURY_RPC=ON -DPDLFS_SNAPPY=OFF
                   -DPDLFS_GFLAGS=OFF -DPDLFS_GLOG=OFF
                   -DPDLFS_VERBOSE=${DELTAFS_VERBOSE})


include (umbrella/ch-placement)
include (umbrella/deltafs)
include (umbrella/deltafs-bb)
include (umbrella/deltafs-common)
include (umbrella/deltafs-nexus)
include (umbrella/deltafs-vpic-preload)
include (umbrella/mercury)
include (umbrella/mercury-runner)
include (umbrella/ssg)
include (umbrella/trecon-reader)
include (umbrella/vpic)

#
# scripts -- live here in deltafs-umbrella
#
ExternalProject_Add (scripts
    DOWNLOAD_COMMAND true    # no need to download, comes with umbrella
    SOURCE_DIR ${CMAKE_SOURCE_DIR}/scripts
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}

    UPDATE_COMMAND ""
)
