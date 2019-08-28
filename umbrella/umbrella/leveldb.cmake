#
# leveldb.cmake  umbrella for LEVELDB database package
# 04-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  LEVELDB_REPO - url of git repository
#  LEVELDB_TAG  - tag to checkout of git
#  LEVELDB_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET leveldb)

#
# umbrella option variables
#
umbrella_defineopt (LEVELDB_REPO "https://github.com/google/leveldb.git"
                    STRING "LEVELDB GIT repository")
umbrella_defineopt (LEVELDB_TAG "master" STRING "LEVELDB GIT tag")
umbrella_defineopt (LEVELDB_TAR "leveldb-${LEVELDB_TAG}.tar.gz" STRING
                    "LEVELDB cache tar file")

# we know revs "v1.X" where X < 21 use makefile instead of cmake
if ("${LEVELDB_TAG}" MATCHES "^v1\\.([0-9]+)$" AND CMAKE_MATCH_1 LESS 21)
    umbrella_defineopt (LEVELDB_USE_MAKEFILE "ON" BOOL "Build with makefile")
else ()
    umbrella_defineopt (LEVELDB_USE_MAKEFILE "OFF" BOOL "Build with makefile")
endif ()

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (LEVELDB_DOWNLOAD leveldb ${LEVELDB_TAR}
                   GIT_REPOSITORY ${LEVELDB_REPO}
                   GIT_TAG ${LEVELDB_TAG})
umbrella_patchcheck (LEVELDB_PATCHCMD leveldb)

#
# create leveldb target
#
if (LEVELDB_USE_MAKEFILE)
    message (STATUS "  leveldb: building with makefile")
    ExternalProject_Add (leveldb ${LEVELDB_DOWNLOAD} ${LEVELDB_PATCHCMD}
        CONFIGURE_COMMAND ""
        BUILD_IN_SOURCE 1      # old school makefiles
        BUILD_COMMAND make
        INSTALL_COMMAND mkdir -p ${CMAKE_INSTALL_PREFIX}/lib
          COMMAND cd <SOURCE_DIR>/out-shared &&
          sh -c "cp libleveldb.* ${CMAKE_INSTALL_PREFIX}/lib"
          COMMAND cp -r <SOURCE_DIR>/include/leveldb
                                           ${CMAKE_INSTALL_PREFIX}/include
        UPDATE_COMMAND "")
else()
    message (STATUS "  leveldb: building with cmake")
    ExternalProject_Add (leveldb ${LEVELDB_DOWNLOAD} ${LEVELDB_PATCHCMD}
        CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
        CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
        UPDATE_COMMAND "")
endif()

endif (NOT TARGET leveldb)
