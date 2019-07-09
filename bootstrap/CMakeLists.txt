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
# CMakeLists.txt  optionally build some bootstrap packages for deltafs-umbrella
# 08-Jul-2019  chuck@ece.cmu.edu
#

#
# the main deltafs-umbrella assumes you've got all the basics installed
# (e.g. automake, libtool, some version of MPI, ...).   if that is not
# the case, this bootstrap CMakeLists.txt can be used to build some of
# the missing parts for the main deltafs-umbrella to pick up.
#
# You can either install the bootstrap stuff in its own directory
# (so it can be shared by multiple builds), or you can put it in
# same place you are going to install deltafs-umbrella.
#
# example: deltafs-umbrella requires MPI, but you don't have it
# installed anywhere.  You want to put MPI in prefix $HOME/boot
# and then use that to build deltafs-umbrella in $HOME/delta.
#
# in this directory:
#   mkdir build
#   cd build
#   cmake -DCMAKE_INSTALL_PREFIX=$HOME/boot -DBOOTSTRAP=mpich ..
#   make
#
# then when you configure deltafs-umbrella, make sure you put the
# bootstrap directory in the cmake prefix path.  i.e. in the top-level
# deltafs-umbrella directory:
#   mkdir build
#   cd build
#   cmake -DCMAKE_PREFIX_PATH=$HOME/boot -DCMAKE_INSTALL_PREFIX=$HOME/delta ..
#   make
#

#
# general command line config:
#
#   -DCMAKE_INSTALL_PREFIX=/usr/local     # bootstrap installation prefix
#   -DBOOTSTRAP='pkglist'                 # list of pkgs to bootstrap
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

cmake_minimum_required (VERSION 3.0)

#
# put the umbrella scripts in our search path and include umbrella-init
# (umbrella-init needs to run before "project")
#
list (APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../umbrella")
include (umbrella-init)

project (umbrella-bootstrap C CXX)

if ("${BOOTSTRAP}" STREQUAL "")
  message(FATAL_ERROR "BOOTSTRAP must be set (e.g. to pkgs to build)")
endif()

#
# configure umbrella for MPI and pull in the main routines
#
set (UMBRELLA_BUILD_TESTS "OFF" CACHE BOOL "Build unit tests")
include (umbrella-main)

#
# set git tags to the versions we want to stick to by default...
#

#
# set other configs before we start pulling in the pieces...
#

foreach(pkg ${BOOTSTRAP})
  include(umbrella/${pkg})
  message (STATUS "Will build ${pkg}")
endforeach()
