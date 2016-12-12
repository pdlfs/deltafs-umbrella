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

cmake_minimum_required (VERSION 3.0)
project (deltafs-umbrella NONE)
include (ExternalProject)

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
# set up the prefix path for packaged software that we may want to
# link to (e.g. third party libraries).   this will get added to
# the configure command line (for autotools-based projects).
# we want our install prefix to be in the prefix path too (it isn't
# be default).
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
# generate a prefix path with an alternate LIST_SEPARATOR for cmake-based
# projects.  needed for ExternalProject because CMAKE_ARGS eats ";"'s.
#
string (REPLACE ";" "^^" CMAKE_QUOTED_PREFIX_PATH "${CMAKE_PREFIX_PATH}")

#
# use above vars to build build CPPFLAGS and LDFLAGS for configure scripts
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
# now we are ready to start building packages
#

#
# CCI.   note that we enable verbs if we detect the necessary header
# files and libraries.   (note: the find calls below respect the prefix path.)
#
find_library (LIBIBVERBS NAMES ibverbs)
find_path (RDMA_INCLUDE rdma/rdma_cma.h HINTS ${RDMA_INCLUDE_DIR})
if (LIBIBVERBS AND RDMA_INCLUDE)
   set (ibv "--with-verbs")
else ()
   set (ibv "--without-verbs")
endif ()
message (STATUS "CCI ibverbs setting: ${ibv}")

GenDownloadConfig (cci_download cci cci-2.0.tar.gz
    URL http://cci-forum.com/wp-content/uploads/2016/06/cci-2.0.tar.gz
    URL_MD5 070b2ba4eca92a846c093f2cd000d3b2
    TIMEOUT 100
    ### GIT_REPOSITORY "https://github.com/CCI/cci"
    ### GIT_TAG master
)

ExternalProject_Add (cci
    ${cci_download}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${cppflags} ${ldflags}
         --prefix=${CMAKE_INSTALL_PREFIX} ${ibv}
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
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_INSTALL_PREFIX}
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

GenDownloadConfig (mercury_download mercury mercury-6d069df1.tar.gz
    GIT_REPOSITORY "https://github.com/mercury-hpc/mercury.git"
    GIT_TAG 6d069df1		# Dec 2016
    ### GIT_TAG master
)

ExternalProject_Add (mercury
    DEPENDS cci bmi
    LIST_SEPARATOR ^^                    # for passing CMAKE_PREFIX_PATH
    ${mercury_download}
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
# deltafs
#
GenDownloadConfig (deltafs_download deltafs deltafs-0.9.2.tar.gz
    GIT_REPOSITORY "https://github.com/pdlfs/deltafs.git"
    # XXX: switch this off until we decide we want to tag it off
    ###GIT_TAG "v0.9.2"
)

ExternalProject_Add (deltafs
    DEPENDS mercury
    LIST_SEPARATOR ^^
    ${deltafs_download}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
               -DCMAKE_PREFIX_PATH=${CMAKE_QUOTED_PREFIX_PATH}
               -DBUILD_SHARED_LIBS=ON -DBUILD_TESTS=ON
               -DPDLFS_MERCURY_RPC=ON -DPDLFS_SNAPPY=OFF
               -DPDLFS_GFLAGS=OFF -DPDLFS_GLOG=OFF
               -DDELTAFS_MPI=ON
    UPDATE_COMMAND ""
    TEST_COMMAND ctest
)

#
# pdlfs-preload
#
GenDownloadConfig (pdlfs_preload_download pdlfs_preload pdlfs-preload-0.2.tar.gz
    GIT_REPOSITORY "https://github.com/pdlfs/pdlfs-preload.git"
    GIT_TAG "v0.2"
)

ExternalProject_Add (pdlfs-preload
    DEPENDS deltafs
    LIST_SEPARATOR ^^
    ${pdlfs_preload_download}
    CONFIGURE_COMMAND ""
    BUILD_IN_SOURCE 1
    BUILD_COMMAND make PREFIX=${CMAKE_INSTALL_PREFIX}
    INSTALL_COMMAND ""

    # TODO: replace following commands with a proper INSTALL_COMMAND

    COMMAND cp <SOURCE_DIR>/build/libpdlfs-preload-deltafs.so ${CMAKE_INSTALL_PREFIX}/lib/
    COMMAND cp <SOURCE_DIR>/build/libpdlfs-preload-posix.so ${CMAKE_INSTALL_PREFIX}/lib/
    COMMAND cp <SOURCE_DIR>/build/libpdlfs-preload.so ${CMAKE_INSTALL_PREFIX}/lib/
)

# remove pdlfs-preload from the 'all' target .. replace w/deltafs-vpic-preload
set_property (TARGET pdlfs-preload PROPERTY EXCLUDE_FROM_ALL True)

#
# vpic
#
GenDownloadConfig (vpic_download vpic vpic_deltafs.tar.gz
    GIT_REPOSITORY "https://github.com/pdlfs/vpic.git"
    ### GIT_TAG master
)

ExternalProject_Add (vpic
    DEPENDS deltafs           # XXX: just to make it build deltafs first
    LIST_SEPARATOR ^^
    ${vpic_download}

    # TODO: This code makes me sad, but then again this VPIC version
    #       also makes me sad. Feel free to fix.

    CONFIGURE_COMMAND cd <SOURCE_DIR> && ./config/bootstrap
        COMMAND CC=mpicc CXX=mpicxx <SOURCE_DIR>/configure
                --with-machine=<SOURCE_DIR>/narwhal.conf
    BUILD_COMMAND make
        COMMAND cd <SOURCE_DIR> && <BINARY_DIR>/build.op input/turbulence.cxx

    INSTALL_COMMAND cp <SOURCE_DIR>/input/turbulence.op ${CMAKE_INSTALL_PREFIX}/bin/
    UPDATE_COMMAND ""
)

