#
# CMakeLists.txt  build deltafs and its environment
# 20-Sep-2016  chuck@ece.cmu.edu
#

# command line config:
#
# -DCMAKE_INSTALL_PREFIX=/tmp/delta       # where to install
#

#
# [optional config vars]
# -DCMAKE_PREFIX_PATH='/pkg'              # look for additional installs here
#
# the following also applies for configure scripts:
# -DCMAKE_INCLUDE_PATH='/pkg/include'     # extra include directories
# -DCMAKE_LIBRARY_PATH='/pkg/lib'         # extra library path
#

cmake_minimum_required (VERSION 3.0)      # glog requires 3.0
project (deltafs-umbrella NONE)
include (ExternalProject)

#
# determine all the places to look for packaged software...  we add
# the install prefix to the places we look.
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
# generate a prefix path with an alternate LIST_SEPARATOR for ExternalProject
#
string (REPLACE ";" "^^" CMAKE_QUOTED_PREFIX_PATH "${CMAKE_PREFIX_PATH}")

#
# use vars to build build CPPFLAGS and LDFLAGS for configure scripts
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

#
# CCI
#

find_library (LIBIBVERBS NAMES ibverbs)
find_path (RDMA_INCLUDE rdma/rdma_cma.h HINTS ${RDMA_INCLUDE_DIR})
if (LIBIBVERBS AND RDMA_INCLUDE)
   set (ibv "--with-verbs")
else ()
   set (ibv "--without-verbs")
endif ()
message (STATUS "CCI ibverbs setting: ${ibv}")

ExternalProject_Add (cci
    # avoiding aclocal problem, build from tar
    # XXX: no configure script @ github tar
    ###URL https://github.com/CCI/cci/archive/v2.0.tar.gz
    URL http://yogi.pdl.cmu.edu/~chuck/tmp/cci-2.0.tgz
    URL_MD5 a7f5c6054a4f47ff369b5271dc94f46e
    TIMEOUT 5
    ### GIT_REPOSITORY "https://github.com/CCI/cci"
    ### GIT_TAG master
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${cppflags} ${ldflags}
         --prefix=${CMAKE_INSTALL_PREFIX} ${ibv}
    UPDATE_COMMAND ""
)

# only needed if building from github
#ExternalProject_Add_Step(cci prepare
#    COMMAND <SOURCE_DIR>/autogen.pl
#    COMMENT "preparing source for configure"
#    DEPENDEES update
#    DEPENDERS configure
#    WORKING_DIRECTORY <SOURCE_DIR>
#)

#
# BMI
#
set (bmipatch "${CMAKE_SOURCE_DIR}/patches/bmi-${CMAKE_SYSTEM_NAME}-patch")
if (EXISTS ${bmipatch})
    set (bmipatchcmd patch -i ${bmipatch} -d <SOURCE_DIR>)
endif ()

ExternalProject_Add (bmi
    GIT_REPOSITORY "http://git.mcs.anl.gov/bmi.git"
    # GIT_TAG master
    PATCH_COMMAND ${bmipatchcmd}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared --enable-bmi-only
    UPDATE_COMMAND ""
)

ExternalProject_Add_Step(bmi prepare
    COMMAND <SOURCE_DIR>/prepare
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

ExternalProject_Add (mercury
    DEPENDS cci bmi
    LIST_SEPARATOR ^^                    # for passing CMAKE_PREFIX_PATH
    GIT_REPOSITORY "https://github.com/mercury-hpc/mercury.git"
    # GIT_TAG master
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
               -DCMAKE_PREFIX_PATH=${CMAKE_QUOTED_PREFIX_PATH}
               -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=1
               -DNA_USE_MPI=OFF -DNA_USE_CCI=ON -DNA_USE_BMI=ON
               -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=ON
               -DMERCURY_USE_BOOST_PP=ON -DMERCURY_USE_CHECKSUMS:BOOL=OFF
               -DNA_CCI_USE_POLL:BOOL=ON
               -DBMI_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include
               -DBMI_LIBRARY=${CMAKE_INSTALL_PREFIX}/lib/libbmi.so
               -DCCI_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include
               -DCCI_LIBRARY=${CMAKE_INSTALL_PREFIX}/lib/libcci${suf}
    UPDATE_COMMAND ""

# XXX: not all tests run, so no TEST_COMMAND for now
#ctest -E 'mercury_bulk_cci_tcp|mercury_bulk_seg_cci_tcp|mercury_posix_cci_tcp'
# some issues with cci/tcp transport

)

#
# Snappy (XXX: using tar file, as aclocal on nerc is broken)
#

ExternalProject_Add (snappy
    URL https://github.com/google/snappy/releases/download/1.1.3/snappy-1.1.3.tar.gz
    URL_MD5 7358c82f133dc77798e4c2062a749b73
    TIMEOUT 5
    ### GIT_REPOSITORY "https://github.com/google/snappy"
    ### GIT_TAG master
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${cppflags} ${ldflags}
         --prefix=${CMAKE_INSTALL_PREFIX}
    UPDATE_COMMAND ""
)

# XXX: only needed if building from github
#ExternalProject_Add_Step(snappy prepare
#    COMMAND <SOURCE_DIR>/autogen.sh
#    COMMENT "preparing source for configure"
#    DEPENDEES update
#    DEPENDERS configure
#    WORKING_DIRECTORY <SOURCE_DIR>
#)

#
# gflags
#

ExternalProject_Add (gflags
    LIST_SEPARATOR ^^                    # for passing CMAKE_PREFIX_PATH
    GIT_REPOSITORY "https://github.com/gflags/gflags"
    # GIT_TAG master
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
               -DCMAKE_PREFIX_PATH=${CMAKE_QUOTED_PREFIX_PATH}
               -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=1
               -DBUILD_SHARED_LIBS=ON
    UPDATE_COMMAND ""
)


#
# glog
#

ExternalProject_Add (glog
    DEPENDS gflags
    LIST_SEPARATOR ^^                    # for passing CMAKE_PREFIX_PATH
    GIT_REPOSITORY "https://github.com/google/glog"
    # GIT_TAG master
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
               -DCMAKE_PREFIX_PATH=${CMAKE_QUOTED_PREFIX_PATH}
               -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=1
               -DBUILD_SHARED_LIBS=ON
    UPDATE_COMMAND ""
)

#
# deltafs
#
ExternalProject_Add (deltafs
    DEPENDS mercury gflags glog snappy
    LIST_SEPARATOR ^^
    GIT_REPOSITORY "https://github.com/pdlfs/deltafs.git"
    GIT_SUBMODULES "deps/openpa"
    GIT_TAG "v0.9.1"
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
               -DCMAKE_PREFIX_PATH=${CMAKE_QUOTED_PREFIX_PATH}
               -DBUILD_SHARED_LIBS=ON -DBUILD_TESTS=ON
               -DPDLFS_MERCURY_RPC=1 -DPDLFS_SNAPPY=1
               -DPDLFS_GFLAGS=1 -DPDLFS_GLOG=1
               -DDELTAFS_MPI=ON
    UPDATE_COMMAND ""
    TEST_COMMAND ctest
)
