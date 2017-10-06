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
# build command-line variable settings for autotools configure scripts:
#   ${UMBRELLA_CPPFLAGS}   -- preprocessor flags for autoconf
#   ${UMBRELLA_LDFLAGS}    -- linker flags for autoconf
#   ${UMBRELLA_COMP}       -- C/C++ compilers for autoconf
#   ${UMBRELLA_MPICOMP}    -- C/C++ compilers with MPI for autoconf
#   ${UMBRELLA_PKGCFGPATH} -- PKG_CONFIG_PATH setting
#
# users can reflect the cmake settings (including prefixes) down
# to the configure script via env vars CPPFLAGS, LDFLAGS, CC, AND CXX.
#
if (CMAKE_INCLUDE_PATH)
  foreach (umbrella_inc ${CMAKE_INCLUDE_PATH})
      set (UMBRELLA_CPPFLAGS "${UMBRELLA_CPPFLAGS} -I${inc}")
  endforeach ()
  # remove the leading space
  string (SUBSTRING ${UMBRELLA_CPPFLAGS} 1 -1 UMBRELLA_CPPFLAGS)
  set (UMBRELLA_CPPFLAGS "CPPFLAGS=${cppflags}")
endif ()
if (CMAKE_LIBRARY_PATH)
  foreach (lib ${CMAKE_LIBRARY_PATH})
      set (UMBRELLA_LDFLAGS "${UMBRELLA_LDFLAGS} -L${lib}")
  endforeach ()
  string (SUBSTRING ${UMBRELLA_LDFLAGS} 1 -1 UMBRELLA_LDFLAGS)
  set (UMBRELLA_LDFLAGS "LDFLAGS=${UMBRELLA_LDFLAGS}")
endif ()
# compiler settings, the second one is to force an mpi wrapper based compile.
set (UMBRELLA_COMP CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER})
if (UMBRELLA_MPI)
    set (UMBRELLA_MPICOMP CC=${MPI_C_COMPILER} CXX=${MPI_CXX_COMPILER})
endif ()

# some systems have PKG_CONFIG_PATH already set, so we need to add to it
if (DEFINED ENV{PKG_CONFIG_PATH})
  set (UMBRELLA_PKGCFGPATH
    "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
else ()
  set (UMBRELLA_PKGCFGPATH "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig")
endif ()
set (UMBRELLA_PKGCFGPATH "PKG_CONFIG_PATH=${UMBRELLA_PKGCFGPATH}")

#
# provide ${UMBRELLA_CMAKECACHE} for cmake-based projects.  we want
# these values to propagate from the umbrella on down...
#
set (UMBRELLA_CMAKECACHE
                -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
                -DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}
                -DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}
                -DCMAKE_INSTALL_PREFIX:STRING=${CMAKE_INSTALL_PREFIX}
                -DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}
                -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY:BOOL=1
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
