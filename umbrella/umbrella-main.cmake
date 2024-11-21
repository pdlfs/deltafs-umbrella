#
# umbrella-main.cmake  generic parts of the umbrella framework
# 27-Sep-2017  chuck@ece.cmu.edu
#

#
# we establish a cmake target for each software package we want built
# using the ExternalProject module's ExternalProject_Add() function.
# each target has an umbrella file whose name matches the target.
# example: target 'foo' has an umbrella file 'umbrella/foo.cmake'
#
# targets are configured using variables whose names are prefixed
# by the target name (in upper case, with dashes replaced by underlines).
# example: target 'foo' variables start with 'FOO_'
#          target 'ch-placement' varibles start with 'CH_PLACEMENT_'
#
# global umbrella configuration variables are prefixed with 'UMBRELLA_'
#
#
# umbrella option variables:
#
#   umbrella option variables are built on top of cmake CACHE
#   and normal variables.  note that the values of variables stored
#   in the cmake CACHE persist between runs (in file CMakeCache.txt).
#   we put the baseline definition of an umbrella option variable
#   in the target's umbrella/*.cmake file, but we allow the user
#   to override the variable's baseline default value with a new
#   default value by loading it into a normal variable (which is
#   used to define a CACHE variable).  users can also directly set
#   a normal variable to override an umbrella option variable's
#   default value (this includes setting it with -D from the
#   cmake command line).
#
#   APIs/example:
#     >> set umbrella option variable (as a cmake CACHE variable)
#     umbrella_defineopt(variable-name baseline-default type docstring)
#
#     >> override baseline-default of an umbrella option variable
#     umbrella_opt_default(variable-name new-default)
#
#     typical usage, using target foo as example:
#
#     >> in umbrella/foo.cmake - set baseline default value to "main"
#     umbrella_defineopt(FOO_TAG "main" STRING "Foo GIT tag")
#
#     >> in umbrella's CMakeLists.txt, update default to "v1.1"
#     >> for this project's umbrella
#     umbrella_opt_default(FOO_TAG "v1.1")   # lock version down
#
#     user can override this by setting FOO_TAG or by
#     using -DFOO_TAG="v2.0" on the cmake command line.
#
#
# umbrella settings:
#
# a setting is a named config intended to be applied to multiple
# umbrella targets (vs the option variable which is for one target).
# setting values are limited to one item from a fixed list (the
# default fixed list is 'ON;OFF').  the setting name and the list
# of setting values are used to name a set of cmake variables starting
# with 'UMBRELLA_' that can be searched for a given target name
# to deterime the settings value for that target.  each setting
# has a variable for each possible setting value with a list of
# targets.  the variables are named like this: "UMBRELLA_name_value".
# in addition, each setting has a variable named "UMBRELLA_name"
# that can be used to establish a global setting default value.
#
# example: for a setting named 'BUILDTESTS' that allows values
# of 'ON' or 'OFF' the variables used are:
#
#   UMBRELLA_BUILDTESTS_ON  -- cmake list of targets with setting ON
#   UMBRELLA_BUILDTESTS_OFF -- cmake list of targets with setting OFF
#   UMBRELLA_BUILDTESTS     -- global default, set to ON or OFF
#
# a setting for a target may be undefined if the target isn't on
# one of the value lists and no global default value is set.
#
# to read the BUILDTEST umbrella setting for a target 'foo' we first check
# if 'foo' is on one of the UMBRELLA_BUILDTESTS_ON or
# UMBRELLA_BUILDTESTS_OFF lists (it is an error if a target is on
# more than one list).   if the target isn't on a list, then
# the global default value is used (if defined).
#
#   APIs/example:
#     >> read setting, value-list is optional (default='ON;OFF')
#     umbrella_setting(setting-name target return-variable value-list)
#
#     >> read target 'foo' BUILDTESTS setting into variable FOO_BUILDTESTS
#     umbrella_setting(BUILDTESTS foo FOO_BUILDTESTS)
#
# target setting variables:
#
# umbrella settings are often combined with option variables to create
# target setting variables.   a target setting variable is a per-target
# option variable whose value is linked to an umbrella setting.
#
#   APIs/example:
#     >> create variable with name based on 'setting-name' and 'target'
#     >> that is linked to the setting 'setting-name' ... the 'value-list'
#     >> is optional and defaults to 'ON;OFF' ... this call would typically
#     >> be in an umbrella/*.cmake file
#     umbrella_target_setting(setting-name target
#                              initial-default type doc-string value-list)
#
#
#     for example, for an 'ON;OFF' setting named 'MYSETTING' and target 'foo':
#
#       umbrella_target_setting(MYSETTING foo ON BOOL "mysetting for foo")
#
#     will create an option variable named 'FOO_MYSETTING' that is
#     set in the following way (listed in ~priority order):
#       1. using -DFOO_MYSETTING=ON (or OFF) on the command line
#       2. set with umbrella_opt_default(FOO_MYSETTING ON)
#       3. set to ON with UMBRELLA_MYSETTING_ON=foo  or
#          set to OFF with UMBRELLA_MYSETTING_OFF=foo
#       4. set to ON with global UMBRELLA_MYSETTING=ON  (or OFF)
#       5. FOO_MYSETTING will be undefined if none of the above applies
#
#   aside: internally the above translates to:
#          umbrella_setting(MYSETTING foo FOO_MYSETTING)
#          umbrella_defineopt(FOO_MYSETTING OFF BOOL "mysetting for foo")
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

#
# umbrella_targetvar_prefix: generate a target variable prefix from
# a target name.  e.g. "bmi" => "BMI_", "ch-placement" => "CH_PLACEMENT_"
#
function (umbrella_targetvar_prefix target retval)
    string(REPLACE "-" "_" prefix "${target}")
    string(TOUPPER "${prefix}" prefix)
    set(${retval} "${prefix}_" PARENT_SCOPE)
endfunction()

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
# umbrella_setting: check an umbrella-wide setting for a given target.
# returns target's setting in "retvar" ... if "retvar" is already defined
# then we do nothing (user is overriding the setting).
#
# note that we access all the possible UMBRELLA_${setting}* variables
# here even if we do not need their values.  this is to work around cmake
# warnings about unused cli -D variables.  e.g. if user does:
#
#   -DUMBRELLA_MYSETTING=OFF   # on command line
#   set(FOO_MYSETTING ON)      # override for target 'foo' in CMakeLists.txt
#
# strictly speaking a call to umbrella_setting(MYSETTING foo FOO_MYSETTING)
# does not need to look at the value of ${UMBRELLA_MYSETTING} because
# the value of ${FOO_MYSETTING} overrides it.   but in that case, if
# nothing else looks at ${UMBRELLA_MYSETTING} then you'll get an unused var
# warning for it.  it is true that in this case ${UMBRELLA_MYSETTING}
# is unused, but it is a legit case of that variable being overridden
# and so we don't really want a warning about it.
#
function (umbrella_setting setting targ retvar)

    # set rv to empty string to start (means we have not found a val yet)
    set(rv "")

    # allow user to provide possible values; default to ON and OFF
    if (${ARGC} EQUAL 3)
        set(vals ON OFF)     # default if no list specified
    else()
        set(vals ${ARGN})    # treat extra args as list of setting values
    endif()

    # check in UMBRELLA_${setting}_value lists (foreach value in ${vals})
    foreach (list ${vals})
        list(FIND UMBRELLA_${setting}_${list} "${targ}" result)
        if (NOT ${result} EQUAL -1)
            if (NOT "${rv}" STREQUAL "")
                message(WARNING
                        "umbrella_setting: dup define ${targ} ${setting}")
            endif()
            set (rv "${list}")
        endif()
    endforeach()

    # check for global setting in UMBRELLA_${setting}, apply it if no rv
    if (NOT "${UMBRELLA_${setting}}" STREQUAL "" AND "${rv}" STREQUAL "")
        set (rv ${UMBRELLA_${setting}})
    endif()

    # if we found a value and parent has not overriden us, push value up
    if (NOT "${rv}" STREQUAL "" AND NOT DEFINED ${retvar})
        set (${retvar} "${rv}" PARENT_SCOPE)
    endif()

endfunction()

#
# umbrella_target_setting: combine umbrella setting with option
# variable.  this links a global setting value to a target variable.
# takes an optional value-list at the end (for settings that are not
# 'ON;OFF').
#
function (umbrella_target_setting setting target initdefault type docstring)

    # use target to get prefix, then build varname by appending setting name
    umbrella_targetvar_prefix("${target}" prefix)
    set(varname "${prefix}${setting}")

    # if setting is set, read it into ${varname}.  o.w. ${varname} is !set
    umbrella_setting(${setting} ${target} ${varname} ${ARGN})

    # create variable in cache using setting value already loaded in
    # variable varname, or if that is !set use the initdefault
    umbrella_defineopt(${varname} ${initdefault} ${type} "${docstring}")

endfunction()

#
# umbrella_buildtests: BUILDTESTS target setting.  if a target has a
# "build tests" configuration, we can link it to the BUILDTESTS setting.
# the developer writing the target's umbrella/*.cmake file is responsible
# for using the value of this to configure target's build flags.
#
# note: we used to take the output variable name as an additional
# arg - but now we let umbrella_target_setting() determine the name
# and any additional args are ignored.
#
function (umbrella_buildtests target)
    umbrella_target_setting(BUILDTESTS ${target} OFF BOOL
        "Build ${target} tests")
endfunction()

#
# umbrella_runtests: RUNTESTS target setting.  if a target supports
# running tests (e.g. unit tests), we can link this to the
# RUNTESTS setting.   this is used to support the umbrella_testcommand()
# function.
#
function (umbrella_runtests target)
    umbrella_target_setting(RUNTESTS ${target} OFF BOOL "Run ${target} tests")
endfunction()

#
# umbrella_testcommand: generate test-args output if requested.
# we generate test-args if we are not cross compiling, the target
# built the tests (if that was an option), and we are requested to
# run the tests.
#
function (umbrella_testcommand target retvar)

    # get target prefix and read RUNTESTS target setting
    umbrella_targetvar_prefix("${target}" prefix)
    umbrella_runtests(${target})

    # now see if we need to do it
    if (NOT CMAKE_CROSSCOMPILING AND
        (NOT DEFINED ${prefix}BUILDTESTS OR ${prefix}BUILDTESTS) AND
        ${prefix}RUNTESTS)
        # add TEST_COMMAND for ExternalProject_Add() if not present
        if ("${ARGV2}" STREQUAL "TEST_COMMAND")
            set (${retvar} ${ARGN} PARENT_SCOPE)
        else()
            set (${retvar} TEST_COMMAND ${ARGN} PARENT_SCOPE)
        endif()
    else()
        set (${retvar} "" PARENT_SCOPE)
    endif()
endfunction()

#
# umbrella_prebuilt: PREBUILT target setting.  targets that support
# PREBUILT can use a previously built version of the target instead
# of building it themselves (e.g. to save time and/or avoid doing
# a complex build).  possible PREBUILT values are:
#    ON  - always use a prebuilt version of target (fails if !found)
#    OFF - never use a prebuilt version of target (we always build it)
#    TRY - use a prebuilt version of target if found, otherwise we build it
#
function (umbrella_prebuilt target)
    umbrella_target_setting(PREBUILT ${target} OFF BOOL
        "${target} is prebuilt" "ON;OFF;TRY")
endfunction()

#
# umbrella_prebuilt_check_mktarg: helper function.  does the checks
# and makes a custom target for prebuilt targets.
#
function(umbrella_prebuilt_check_mktarg target value check)
    if("${check}" STREQUAL "")
        set(UMBRELLA_PREBUILT_CHECK_${target} 1)       # no check requested
    elseif ("${check}" STREQUAL FILE)
        find_file(UMBRELLA_PREBUILT_CHECK_${target} ${ARGN})
    elseif("${check}" STREQUAL LIBRARY)
        find_library(UMBRELLA_PREBUILT_CHECK_${target} ${ARGN})
    elseif("${check}" STREQUAL PROGRAM)
        find_program(UMBRELLA_PREBUILT_CHECK_${target} ${ARGN})
    else()
        message(FATAL_ERROR "umbrella_prebuilt_check target ${target} "
                            "bad type: ${check}")
    endif()

    if (UMBRELLA_PREBUILT_CHECK_${target})
        add_custom_target(${target} ALL
                          COMMAND ""
                          COMMENT "Prebuilt ${target} target")
        message(STATUS "  Using prebuilt ${target} target")
    else()
        if (value STREQUAL "TRY")
            message(STATUS "  No prebuilt ${target} target - "
                             "will try to build it")
        else()
            message(FATAL_ERROR "${target} - cannot find prebuilt version "
                    "(${check} ${ARGN}) - check paths")
        endif()
    endif()
endfunction()

#
# umbrella_prebuilt_check: determine target's PREBUILT setting and
# apply it to the target (generating a custom target for it if we
# are using a prebuilt version).  we have the option of checking for
# a lib, include file, or program (to make sure the target we think
# is prebuilt is somewhere we can find it).   the CMAKE_PREFIX_PATH
# can be used to expand the search for prebuilt targets.
#
function(umbrella_prebuilt_check target)
    if (NOT TARGET "${target}")

        # get target prefix, read PREBUILT target setting, get target's value
        umbrella_targetvar_prefix("${target}" prefix)
        umbrella_prebuilt(${target})
        set(value "${${prefix}PREBUILT}")    # ON;OFF;TRY

        # try for a prebuilt target if we are ON or TRY
        if ("${value}" STREQUAL "ON" OR "${value}" STREQUAL "TRY")
            umbrella_prebuilt_check_mktarg("${target}" "${value}" ${ARGN})
        endif()

    endif()
endfunction()

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
#   UMBRELLA_BUILDTESTS: default setting for building unit tests (default=off)
#   UMBRELLA_RUNTESTS: default setting for running unit tests (default=off)
#   UMBRELLA_HAS_GNULIBDIRS: built pkg has non-"lib" dir (eg. "lib64") (def=off)
#   UMBRELLA_PATCHDIR: system-level patchdir (def=UMBRELLA_PREFIX/patchdir)
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
# note that UMBRELLA_BUILDTESTS and UMBRELLA_BUILDTESTS are umbrella
# ON/OFF settings, so additional target info can be specified in
# cmake lists in UMBRELLA_BUILDTESTS_ON, UMBRELLA_BUILDTESTS_OFF,
# UMBRELLA_RUNTESTS_ON, and UMBRELLA_RUNTESTS_OFF.   Targets that
# support testing also have target variables (e.g. DELTAFS_RUNTESTS
# can be set to ON or OFF).
#
# targets that support being prebuilt can be set to use a prebuilt
# version by adding the target to the UMBRELLA_PREBUILD_ON cmake list
# or by setting the target's PREBUILT variable to on (e.g.
# FOO_PREBUILT=ON).

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

set (UMBRELLA_BUILDTESTS "OFF" CACHE BOOL "Default for build unit tests")
find_file (UMBRELLA_CACHEDIR cache PATH ${CMAKE_SOURCE_DIR}
           DOC "Cache directory of tar files" NO_DEFAULT_PATH)
set (UMBRELLA_PATCHDIR "${UMBRELLA_PREFIX}/patches"
     CACHE STRING "Internal patch directory")
mark_as_advanced (UMBRELLA_PATCHDIR)
set (UMBRELLA_RUNTESTS "OFF" CACHE BOOL "Default for running unit tests")
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
                -DUMBRELLA_BINARY_DIR:STRING=${CMAKE_BINARY_DIR}
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
message (STATUS "  build tests default: ${UMBRELLA_BUILDTESTS}")
message (STATUS "  run tests default: ${UMBRELLA_RUNTESTS}")
message (STATUS "  ${UMBRELLA_PKGCFGPATH}")
