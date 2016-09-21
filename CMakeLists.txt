#
# CMakeLists.txt  build deltafs and its environment
# 20-Sep-2016  chuck@ece.cmu.edu
#

# config:
#
# -DCMAKE_INSTALL_PREFIX=/tmp/delta       # where to install
#

# [optional]
# -DCMAKE_INCLUDE_PATH='/pkg/include'     # extra include directories
# -DCMAKE_LIBRARY_PATH='/pkg/lib'         # extra library path
# -DCMAKE_PREFIX_PATH='/pkg'              # look for additional installs here
#
# 

cmake_minimum_required (VERSION 3.0)      # glog requires 3.0
project (deltafs-umbrella NONE)
include (ExternalProject)

#
# build CPPFLAGS and LDFLAGS for configure scripts
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
    GIT_REPOSITORY "https://github.com/CCI/cci"
    # GIT_TAG master
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${cppflags} ${ldflags}
         --prefix=${CMAKE_INSTALL_PREFIX} ${ibv}
    UPDATE_COMMAND ""
)

ExternalProject_Add_Step(cci prepare
    COMMAND <SOURCE_DIR>/autogen.pl
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
    GIT_REPOSITORY "https://github.com/mercury-hpc/mercury.git"
    # GIT_TAG master
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
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
# Snappy
#

ExternalProject_Add (snappy
    GIT_REPOSITORY "https://github.com/google/snappy"
    # GIT_TAG master
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${cppflags} ${ldflags}
         --prefix=${CMAKE_INSTALL_PREFIX} 
    UPDATE_COMMAND ""
)

ExternalProject_Add_Step(snappy prepare
    COMMAND <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>
)

#
# gflags
#

ExternalProject_Add (gflags
    GIT_REPOSITORY "https://github.com/gflags/gflags"
    # GIT_TAG master
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
               -DBUILD_SHARED_LIBS=ON
    UPDATE_COMMAND ""
)


#
# glog
#

ExternalProject_Add (glog
    DEPENDS gflags
    GIT_REPOSITORY "https://github.com/google/glog"
    # GIT_TAG master
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
               -DBUILD_SHARED_LIBS=ON
    UPDATE_COMMAND ""
)

#
# deltafs
#
ExternalProject_Add (deltafs
    DEPENDS mercury gflags glog snappy
    GIT_REPOSITORY "https://github.com/pdlfs/deltafs.git"
    # GIT_TAG master
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
               -DBUILD_SHARED_LIBS=ON -DBUILD_TESTS=ON
               -DPDLFS_MERCURY_RPC=1 -DPDLFS_SNAPPY=1 
               -DDELTAFS_MPI=ON
               # XXX tmp disable these, add back to DEPENDS when enabled
               ### -DPDLFS_GFLAGS=1 -DPDLFS_GLOG=1 
    UPDATE_COMMAND ""
    TEST_COMMAND ctest
)
