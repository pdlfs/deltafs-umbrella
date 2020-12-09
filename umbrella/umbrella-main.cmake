#
# umbrella-main.cmake  generic parts of the umbrella framework
# 27-Sep-2017  chuck@ece.cmu.edu
#

#
# check to make sure umbrella-init ran
#
if (NOT UMBRELLA_INIT_DONE)
    message (FATAL_ERROR "umbrella-main: umbrella-init has not been included")
endif ()

#
# various helper function
#

#
# umbrella_patchcheck: look for patch files and return patch command
# if any are found.  we look in the system patch directory and then
# the user's patch directory.  the patch file names are $target.patch
# and $target-$CMAKE_SYSTEM_NAME.patch.  any patch file found is applied.
#
function (umbrella_patchcheck result target)

    # start with system patch directory, use find_file() to save in cache var
    # we'll put the complete list of found patches in ${plist}
    find_file ("${target}_genpatch" "${target}.patch"
                ${UMBRELLA_PATCHDIR} NO_DEFAULT_PATH)
    find_file ("${target}_syspatch" "${target}-${CMAKE_SYSTEM_NAME}.patch"
                ${UMBRELLA_PATCHDIR} NO_DEFAULT_PATH)
    mark_as_advanced (${target}_genpatch ${target}_syspatch)
    if (${target}_genpatch)
        list(APPEND plist ${${target}_genpatch})
    endif ()
    if (${target}_syspatch)
        list(APPEND plist ${${target}_syspatch})
    endif ()

    if (UMBRELLA_USER_PATCHDIR)
        find_file ("${target}_ugenpatch" "${target}.patch"
                    ${UMBRELLA_USER_PATCHDIR} NO_DEFAULT_PATH)
        find_file ("${target}_usyspatch" "${target}-${CMAKE_SYSTEM_NAME}.patch"
                    ${UMBRELLA_USER_PATCHDIR} NO_DEFAULT_PATH)
        mark_as_advanced (${target}_ugenpatch ${target}_usyspatch)
        if (${target}_ugenpatch)
            list(APPEND plist ${${target}_ugenpatch})
        endif ()
        if (${target}_usyspatch)
            list(APPEND plist ${${target}_usyspatch})
        endif ()
    endif ()

    # now we need to turn ${plist} into patch commands
    list (LENGTH plist plist_len)
    math (EXPR plist_range "${plist_len} - 1")  # cvt to range for foreach()
    if (${plist_range} GREATER -1)
        foreach (lcv RANGE ${plist_range})
            list (GET plist ${lcv} patch)
            if (${lcv} EQUAL 0)
                list (APPEND rv PATCH_COMMAND patch
                      -p1 -i ${patch} -d <SOURCE_DIR>)
            else ()
                list (APPEND rv COMMAND patch
                      -p1 -i ${patch} -d <SOURCE_DIR>)
            endif ()
        endforeach ()
    endif ()

    # return result
    set (${result} ${rv} PARENT_SCOPE)

endfunction ()

#
# umbrella_download: generate the download commands for the project,
# including handling the cache
#
function (umbrella_download result target localtar)
    if (UMBRELLA_CACHEDIR AND EXISTS "${UMBRELLA_CACHEDIR}/${localtar}")
        message (STATUS "${target}: using cache (${localtar})")

        # assume correct, but set URL_MD5 to quiet warning
        file (MD5 "${UMBRELLA_CACHEDIR}/${localtar}" localmd5)
        set (${result} URL "${UMBRELLA_CACHEDIR}/${localtar}"
                       URL_MD5 ${localmd5} PARENT_SCOPE)
    else ()
        set (${result} ${ARGN} PARENT_SCOPE)
    endif ()
endfunction ()

#
# umbrella_onlist: set rv to "ON" if lookfor is on the given list
# (note "list" should be the name of the list variable, not the list itself)
#
function (umbrella_onlist list lookfor rv)
    list (FIND ${list} "${lookfor}" result)
    if (${result} EQUAL -1)
        set (${rv} "OFF" PARENT_SCOPE)
    else ()
        set (${rv} "ON" PARENT_SCOPE)
    endif ()
endfunction ()


# umbrella_testcommand: generate test-args output only if 1) we are not
# cross compiling (so we can avoid trying to run target crosscompiled
# binaries on the host), and 2) skip_tests are not set.
#
function (umbrella_testcommand result)
    if (NOT CMAKE_CROSSCOMPILING AND UMBRELLA_BUILD_TESTS
                                 AND NOT UMBRELLA_SKIP_TESTS)
        set (${result} ${ARGN} PARENT_SCOPE)
    else ()
        set (${result} "" PARENT_SCOPE)
    endif ()
endfunction ()

#
# umbrella option variables are built on top of cmake CACHE
# and normal variables.  we put the basic definition of the
# option variable in the umbrella/*.cmake file, but we allow
# the user to override the variable's default value by loading
# it into a normal variable and using that to define the
# cache variable.   users can also directly set a normal
# variable to override all the defaults (including -D from
# the cmake command line).
#

#
# umbrella_defineopt: define an umbrella option variable in
# the cmake cache.  this has no effect on the option variable
# if it has already been defined (first define wins).  when
# defining options, we use the given default value unless one
# was previously defined (e.g. with umbrella_opt_default), in
# which case we use that.
#
function (umbrella_defineopt var val type docstring)
    if (DEFINED ${var})   # user provided their own default value
        set (${var} ${${var}} CACHE ${type} ${docstring})
    else ()
        set (${var} ${val} CACHE ${type} ${docstring})
    endif ()
endfunction()

#
# umbrella_opt_default: set a user-provided default value for an
# umbrella option variable.  we convey this to umbrella_defineopt
# using a normal (non-cache) cmake variable.  but we don't change
# anything if the variable is already defined (it could be a "-D"
# from the command line, that should override this function).
#
function (umbrella_opt_default var newdefault)
    if (NOT DEFINED ${var})
        set (${var} ${newdefault} PARENT_SCOPE)
    endif ()
endfunction ()

#
# umbrella_get_pkgcfglist: get list of package cfg directories
# currently configured in the environment that we need to consider.
#
function(umbrella_get_pkgcfglist outvar)
    unset(rv)
    set(srcvars PKG_CONFIG_PATH)
    if("${CMAKE_C_COMPILER_WRAPPER}" STREQUAL "CrayPrgEnv")
        # extra variables of interest on the cray
        list(APPEND srcvars PKG_CONFIG_PATH_DEFAULT PE_PKG_CONFIG_PATH)
    endif()
    foreach(pkgcfgvar ${srcvars})
        file(TO_CMAKE_PATH "$ENV{${pkgcfgvar}}" pkgcfg)
        list(APPEND rv ${pkgcfg})
    endforeach()
    if(rv)
        list(REMOVE_DUPLICATES rv)
    endif()
    set(${outvar} "${rv}" PARENT_SCOPE)   # push results to parent
endfunction()

#
# umbrella_get_prefixpath: get the value of ${UMBRELLA_PREFIX_PATH}.
# this is what we pass down to projects as their ${CMAKE_PREFIX_PATH}.
# include directories specified to pkgconfig (PKG_CONFIG_PATH...).
#
function(umbrella_get_prefixpath pkgcfglist outvar)
    set(rv ${CMAKE_PREFIX_PATH})        # start with our prefix path...
    # cray: newer versions of cmake already added to system prefix path
    if("${CMAKE_C_COMPILER_WRAPPER}" STREQUAL "CrayPrgEnv" AND
       CMAKE_VERSION VERSION_GREATER 3.14)
        unset(pkgcfglist)
    endif()
    foreach(path ${pkgcfglist})
        string(REGEX REPLACE "(.*)/lib[^/]*/pkgconfig$" "\\1" path "${path}")
        if(NOT "${path}" STREQUAL "")
            list(APPEND rv "${path}")
        endif()
    endforeach()
    #
    # XXX: we shouldn't have to put CMAKE_INSTALL_PREFIX in
    #      UMBRELLA_PREFIX_PATH since cmake already searches
    #      the install prefix in most cases (as CMAKE_INSTALL_PREFIX
    #      gets added to CMAKE_SYSTEM_PREFIX_PATH and that is searched).
    #      unfortunately, FindPkgConfig.cmake builds its search
    #      path only from CMAKE_PREFIX_PATH and ignores
    #      CMAKE_INSTALL_PREFIX... since we need to use FindPkgConfig.cmake
    #      and we want it to search CMAKE_INSTALL_PREFIX, we have to
    #      add the install prefix to the prefix path to work around
    #      the PkgConfig issue.
    #
    list(APPEND rv "${CMAKE_INSTALL_PREFIX}")
    if(rv)
        list(REMOVE_DUPLICATES rv)
    endif()
    set(${outvar} "${rv}" PARENT_SCOPE)   # push results to parent
endfunction()

#
# main code
#

#
# public UMBRELLA_* variables:
#
#   UMBRELLA_PREFIX: base directory for umbrella files
#   UMBRELLA_MPI: user sets this if we are using MPI (default=off)
#   UMBRELLA_BUILD_TESTS: build unit tests (default=on)
#   UMBRELLA_HAS_GNULIBDIRS: built pkg has non-"lib" dir (eg. "lib64") (def=off)
#   UMBRELLA_PATCHDIR: system-level patchdir (def=UMBRELLA_PREFIX/patchdir)
#   UMBRELLA_SKIP_TESTS: skip running tests (default=OFF)
#   UMBRELLA_USER_PATCHDIR: user patch dir (def=CMAKE_SOURCE_DIR/patches)
#   UMBRELLA_PKGCFGLIST: (internal) list of pkgconfig directories from env
#   UMBRELLA_PREFIX_PATH: passed down as CMAKE_PREFIX_PATH (see below)
#   UMBRELLA_CMAKECACHE: init cache values for cmake-based projects
#
# for autotools-based projects:
#   UMBRELLA_PKGCFGPATH: PKG_CONFIG_PATH to pass to configure script
#   UMBRELLA_CPPFLAGS: preprocessor flags to pass into configure script
#   UMBRELLA_LDFLAGS: link flags to pass into configure script
#   UMBRELLA_COMP: C/C++ compilers for autoconf
#   UMBRELLA_MPICOMP: C/C++ compilers with MPI for autoconf
#
# users specify the installation prefix as ${CMAKE_INSTALL_PREFIX}.
# cmake adds this to the ${CMAKE_SYSTEM_PREFIX_PATH} so that find_file,
# find_path, etc. search it.
#
# users may also specify ${CMAKE_PREFIX_PATH} to add prefixes to the
# search path.  note that cmake searches ${CMAKE_PREFIX_PATH} before
# ${CMAKE_SYTEM_PREFIX_PATH}.
#
# In addition to ${CMAKE_PREFIX_PATH}, users may also specify
# ${CMAKE_INCLUDE_PATH} and ${CMAKE_LIBRARY_PATH}.  the difference
# between the two is that cmake appends the appropriate subdirectory
# names (e.g. "include") to directories in ${CMAKE_PREFIX_PATH}
# but does not modify the paths in ${CMAKE_INCLUDE_PATH}.   thus,
# if you have directory /usr/pkg in ${CMAKE_PREFIX_PATH} you do not
# need to add /usr/pkg/include to ${CMAKE_INCLUDE_PATH} (that would be
# redundant).
#
# useful additional prefixes can also be extracted from $ENV{PKG_CFG_PATH}.
# in fact, this is done automatically on Crays in cmake 3.15 or newer.
# for other systems, we do it manually.
#
# all this needs to be reflected back out on the command line for
# autoconfig-based packages.
#

#
# get umbrella prefix/base directory
#
get_filename_component (UMBRELLA_PREFIX ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)

#
# all umbrella builds use the build-in cmake ExternalProject routines
#
include (ExternalProject)

#
# pull in MPI if requested
#
if (UMBRELLA_MPI)
    find_package (MPI MODULE REQUIRED)
endif ()

#
# set default build type and insert it to cache.  add additional options.
#
if (NOT CMAKE_BUILD_TYPE)
    set (CMAKE_BUILD_TYPE RelWithDebInfo
         CACHE STRING "Choose the type of build." FORCE)
    set_property (CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
                  "Debug" "Release" "RelWithDebInfo" "MinSizeRel")
endif ()

set (UMBRELLA_BUILD_TESTS "ON" CACHE BOOL "Build unit tests")
find_file (UMBRELLA_CACHEDIR cache PATH ${CMAKE_SOURCE_DIR}
           DOC "Cache directory of tar files" NO_DEFAULT_PATH)
set (UMBRELLA_PATCHDIR "${UMBRELLA_PREFIX}/patches"
     CACHE STRING "Internal patch directory")
mark_as_advanced (UMBRELLA_PATCHDIR)
set (UMBRELLA_SKIP_TESTS "OFF" CACHE BOOL "Skip running unit tests")
set (UMBRELLA_USER_PATCHDIR "${CMAKE_SOURCE_DIR}/patches"
     CACHE STRING "User patch directory")

#
# UMBRELLA_HAS_GNULIBDIRS: if we use a package that installs libs
# in some GNU-style directory other than $prefix/lib (e.g. $prefix/lib64)
# then set this in order to make sure that directory gets added to RPATH
# in any binaries we generate.   most packges don't do this, so
# we don't enable it by default.
#
set (UMBRELLA_LIBDIRS "${CMAKE_INSTALL_PREFIX}/lib")  # default
if (UMBRELLA_HAS_GNULIBDIRS)
    include (GNUInstallDirs)
    if (NOT "${CMAKE_INSTALL_LIBDIR}" STREQUAL "lib")
        set (UMBRELLA_LIBDIRS
             "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}"
             "${CMAKE_INSTALL_PREFIX}/lib")
    endif ()
endif()

#
# init UMBRELLA_PREFIX_PATH with our CMAKE_PREFIX_PATH and possible
# additional prefixes from PKG_CONFIG_PATH-like variables.  this is
# passed down to projects as their CMAKE_PREFIX_PATH...
#
umbrella_get_pkgcfglist(UMBRELLA_PKGCFGLIST)
umbrella_get_prefixpath("${UMBRELLA_PKGCFGLIST}" UMBRELLA_PREFIX_PATH)

#
# UMBRELLA_PKGCFGPATH contains "PKG_CONFIG_PATH=<path>" for adding
# to the ./configure script command line...  we build it as a cmake
# list and then convert it to a string.
#
unset(UMBRELLA_PKGCFGPATH)
foreach (prefix ${UMBRELLA_LIBDIRS})
    list(APPEND UMBRELLA_PKGCFGPATH "${prefix}/pkgconfig")
endforeach()
foreach(prefix ${CMAKE_PREFIX_PATH})
    if(EXISTS "${prefix}/lib64/pkgconfig")
        list(APPEND UMBRELLA_PKGCFGPATH "${prefix}/lib64/pkgconfig")
    endif()
    if(EXISTS "${prefix}/lib/pkgconfig")
        list(APPEND UMBRELLA_PKGCFGPATH "${prefix}/lib/pkgconfig")
    endif()
endforeach()
list(APPEND UMBRELLA_PKGCFGPATH ${UMBRELLA_PKGCFGLIST})
list(REMOVE_DUPLICATES UMBRELLA_PKGCFGPATH)
# XXX: don't use file TO_NATIVE_PATH, it is not the opposite of TO_CMAKE_PATH
string(REPLACE ";" ":" UMBRELLA_PKGCFGPATH "${UMBRELLA_PKGCFGPATH}")
set (UMBRELLA_PKGCFGPATH "PKG_CONFIG_PATH=${UMBRELLA_PKGCFGPATH}")

#
# UMBRELLA_CPPFLAGS: preprocessor flags for autoconfig projects.
# we assume we just need CMAKE_INSTALL_PREFIX, CMAKE_PREFIX_PATH,
# and CMAKE_INCLUDE_PATH.  for other stuff autoconfig will use
# pkg-config to find additional header paths...
#
set(UMBRELLA_CPPFLAGS "-I${CMAKE_INSTALL_PREFIX}/include")
foreach(umbrella_val ${CMAKE_INCLUDE_PATH})
    set(UMBRELLA_CPPFLAGS "${UMBRELLA_CPPFLAGS} -I${umbrella_val}")
endforeach()
foreach(umbrella_val ${CMAKE_PREFIX_PATH})
    set(UMBRELLA_CPPFLAGS "${UMBRELLA_CPPFLAGS} -I${umbrella_val}/include")
endforeach()
set(UMBRELLA_CPPFLAGS "CPPFLAGS=${UMBRELLA_CPPFLAGS}")

#
# UMBRELLA_LDFLAGS: linker flags for autoconfig projects.
# we assume we just need CMAKE_INSTALL_PREFIX, CMAKE_PREFIX_PATH,
# and CMAKE_LIBRARY_PATH.  for other stuff autoconfig will use
# pkg-config to find additional header paths...
#
unset(UMBRELLA_LDFLAGS)
foreach(umbrella_val ${UMBRELLA_LIBDIRS})
    if(NOT DEFINED UMBRELLA_LDFLAGS)
      set(UMBRELLA_LDFLAGS "-L${umbrella_val} -Wl,-rpath,${umbrella_val}")
    else()
      set(UMBRELLA_LDFLAGS
          "${UMBRELLA_LDFLAGS} -L${umbrella_val} -Wl,-rpath,${umbrella_val}")
    endif()
endforeach()
foreach(umbrella_val ${CMAKE_LIBRARY_PATH})
    set(UMBRELLA_LDFLAGS
        "${UMBRELLA_LDFLAGS} -L${umbrella_val} -Wl,-rpath,${umbrella_val}")
endforeach()
foreach(umbrella_val ${CMAKE_PREFIX_PATH})
    if(EXISTS "${umbrella_val}/lib64")
        set(UMBRELLA_LDFLAGS "${UMBRELLA_LDFLAGS} -L${umbrella_val}/lib64")
        set(UMBRELLA_LDFLAGS
            "${UMBRELLA_LDFLAGS} -Wl,-rpath,${umbrella_val}/lib64")
    elseif(EXISTS "${umbrella_val}/lib")
        set(UMBRELLA_LDFLAGS "${UMBRELLA_LDFLAGS} -L${umbrella_val}/lib")
        set(UMBRELLA_LDFLAGS
            "${UMBRELLA_LDFLAGS} -Wl,-rpath,${umbrella_val}/lib")
    endif()
endforeach()
set(UMBRELLA_LDFLAGS "LDFLAGS=${UMBRELLA_LDFLAGS}")

# compiler settings, the second one is to force an mpi wrapper based compile.
if (DEFINED CMAKE_OSX_SYSROOT AND NOT CMAKE_OSX_SYSROOT STREQUAL "")
    # OSX with CMAKE_OSX_SYSROOT set requires additional flags
    set (UMBRELLA_COMP
      "CC=${CMAKE_C_COMPILER} ${CMAKE_C_SYSROOT_FLAG} ${CMAKE_OSX_SYSROOT}"
      "CXX=${CMAKE_CXX_COMPILER} ${CMAKE_CXX_SYSROOT_FLAG} ${CMAKE_OSX_SYSROOT}"
    )
else ()
    set (UMBRELLA_COMP CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER})
endif ()
if (UMBRELLA_MPI)
    set (UMBRELLA_MPICOMP CC=${MPI_C_COMPILER} CXX=${MPI_CXX_COMPILER})
else ()
    # if MPI is off, fall back to standard compilers.  this allows us
    # to compile projects where MPI is optional...
    set (UMBRELLA_MPICOMP CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER})
endif ()

#
# provide ${UMBRELLA_CMAKECACHE} for cmake-based projects.  we want
# these values to propagate from the umbrella on down...
#
# XXX: tried passing through CMAKE_SYSTEM_NAME here, but that causes
# cmakes under us to think we are crosscompiling even if the passed
# in system name matches the host (see Modules/CMakeDetermineSystem.cmake).
#                -DCMAKE_SYSTEM_NAME:STRING=${CMAKE_SYSTEM_NAME}
#
set (UMBRELLA_CMAKECACHE
                -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
                -DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}
                -DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}
                -DCMAKE_INSTALL_PREFIX:STRING=${CMAKE_INSTALL_PREFIX}
                -DCMAKE_PREFIX_PATH:STRING=${UMBRELLA_PREFIX_PATH}
                -DCMAKE_INCLUDE_PATH:STRING=${CMAKE_INCLUDE_PATH}
                -DCMAKE_LIBRARY_PATH:STRING=${CMAKE_LIBRARY_PATH}
                -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY:BOOL=1
                -DCMAKE_INSTALL_RPATH:STRING=${UMBRELLA_LIBDIRS}
                -DCMAKE_INSTALL_RPATH_USE_LINK_PATH:BOOL=TRUE
     )

message (STATUS "The umbrella framework is enabled")

#
# print the current config so users are aware of the current settings...
#
message (STATUS "Current Umbrella settings:")
message (STATUS "  target OS: ${CMAKE_SYSTEM_NAME} "
                             "${CMAKE_SYSTEM_VERSION}")
message (STATUS "  host OS: ${CMAKE_HOST_SYSTEM_NAME} "
                           "${CMAKE_HOST_SYSTEM_VERSION}")
message (STATUS "  build type: ${CMAKE_BUILD_TYPE}")
message (STATUS "  install lib dirs: ${UMBRELLA_LIBDIRS}")
if (EXISTS "${UMBRELLA_USER_PATCHDIR}")
    message (STATUS "  user patch dir: ${UMBRELLA_USER_PATCHDIR}")
endif ()
if (UMBRELLA_CACHEDIR)
    message (STATUS "  tar cache directory: ${UMBRELLA_CACHEDIR}")
endif ()
message (STATUS "  CXX compiler: ${CMAKE_CXX_COMPILER} "
                  "(${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION})")
if (UMBRELLA_MPI)
    message (STATUS "  MPI CXX wrapper:  ${MPI_CXX_COMPILER}")
endif ()
message (STATUS "  C compiler: ${CMAKE_C_COMPILER} "
                  "(${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION})")
if (UMBRELLA_MPI)
    message (STATUS "  MPI C wrapper:  ${MPI_C_COMPILER}")
endif ()
message (STATUS "  crosscompiling: ${CMAKE_CROSSCOMPILING}")
message (STATUS "  build tests: ${UMBRELLA_BUILD_TESTS}")
if (UMBRELLA_BUILD_TESTS)
    message (STATUS "  skip running tests: ${UMBRELLA_SKIP_TESTS}")
else ()
    message (STATUS "  skip running tests: <off, build disabled>")
endif ()
message (STATUS "  ${UMBRELLA_PKGCFGPATH}")
