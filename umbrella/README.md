# PDLFS umbrella

PDLFS umbrella is a cmake-based framework used to build and install
a set of related software packages.  It is designed to be embedded
within a thin umbrella "meta" package that selects which software
components to use.   For example, the deltafs-umbrella package
(https://github.com/pdlfs/deltafs-umbrella) uses PDLFS umbrella to
build and install all the software components needed to run DeltaFS.

PDLFS umbrella acts as a small, lightweight, self-contained software
package manager.  It leverages cmake's built-in ExternalProject library
to handle dependency tracking and low-level package build operations.

# usage

First you must create an umbrella repository to contain the meta
information for the software you want to build.  Then you embed
PDLFS umbrella in this repository.  The embedding is typically
done using a git subrepo (https://github.com/ingydotnet/git-subrepo)
or git submodule.  The umbrella code can also be directly copied into
a project if using a git subrepo/submodule is undesirable.
Once umbrella is embedded, you use cmake to make use of it.

There are multiple embedding options:

## embed umbrella using git subrepo

Embedding using git subrepo has the advantage of being transparent
to users (non-developers see the umbrella as a normal checked out
git directory that comes with your repo).  As a developer, you can
use git subrepo to easily sync your copy of umbrella with the main
umbrella repository on github.  The main drawback of subrepo is
that developers who want to perform subrepo ops on the embedded
copy of umbrella must install the git subrepo code (see URL above
for details on git subrepo, including how to install it).

Once you have git subrepo installed, you can easily embed umbrella
in your project using subrepo clone.  For example, from the top-level
directory of your umbrella repo run:
```
% git subrepo clone git@github.com:pdlfs/umbrella umbrella
Subrepo 'git@github.com:pdlfs/umbrella' (master) cloned into 'umbrella'.
%
```

After finishing the subrepo clone, you can use "git push" to push
the change back to your repository.

To pull the latest changes from the main github pdlfs/umbrella repo
into your repo, you can use a subrepo pull:
```
% git subrepo pull umbrella
Subrepo 'umbrella' pulled from 'git@github.com:pdlfs/umbrella' (master).
%
```
And then use a git push to push the changes back to your repo.

For reference, PDL users who have write access to the pdlfs/umbrella
repository can push changes from the repository that umbrella is embedded
in back to the main pdlfs/umbrella repo using a subrepo push:
```
% vi umbrella/README.md
...
% git add umbrella/README.md
% git commit
% git push
...
% git subrepo push umbrella
Subrepo 'umbrella' pushed to 'git@github.com:pdlfs/umbrella' (master).
%
```

## embed umbrella using git submodule

Use git submodule add to add umbrella as as submodule, then commit it:
```
% git submodule add git@github.com:pdlfs/umbrella
Cloning into '/tmp/sr/test/testin2/umbrella'...
remote: Enumerating objects: 661, done.
remote: Counting objects: 100% (41/41), done.
remote: Compressing objects: 100% (27/27), done.
remote: Total 661 (delta 21), reused 28 (delta 14), pack-reused 620
Receiving objects: 100% (661/661), 135.63 KiB | 4.11 MiB/s, done.
Resolving deltas: 100% (459/459), done.
% git commit -m 'add umbrella submodule'
[master db62892] add umbrella submodule
 2 files changed, 4 insertions(+)
 create mode 100644 .gitmodules
 create mode 160000 umbrella
%
```

When you check out your repository, use submodule init and submodule
update to fetch the umbrella:
```
% git submodule init
Submodule 'umbrella' (git@github.com:pdlfs/umbrella) registered for path 'umbrella'
% git submodule update
Cloning into '/tmp/sr/test/testin2/umbrella'...
Submodule path 'umbrella': checked out 'cddb40759838ca36b627143fe7a61a30f0e0e25b'
%
```

## embed umbrella manually

Check out https://github.com/pdlfs/umbrella in a temporary directory
and manually copy and commit the non-git files into your project.

# using umbrella

To use PDLFS umbrella, you need to have a basic understanding of cmake.

Assuming you've embedded umbrella in a top-level directory in
your repository (as in the examples above), create/edit your main
top-level CMakeLists.txt file and make the following changes around
your call to project() to add a basic link to the umbrella code.
```
cmake_minimum_required (VERSION 3.1)

#
# add the following 2 lines before the call to project.  The first
# adds the umbrella directory to your module search path.  The second
# pulls in a small bit of init code (used to allow CC and CXX cmake
# variables set on the command line with -D to set the compiler).
#
list (APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/umbrella")
include (umbrella-init)

project (testing C CXX)

#
# optional, pulls in cmake MPI support.  only needed when building MPI apps.
#
set (UMBRELLA_MPI 1)

#
# add the following line after project() to pull in the main umbrella fns.
#
include (umbrella-main)
```

Once the above is done, you can browse umbrella/umbrella to select
software to build and install.  For example, if you want to add
leveldb to your project, you can simply add the following line to
CMakeLists.txt:
```
include(umbrella/leveldb)
```

That is the minimal basics on how to use umbrella.  More detailed
information follows.

# umbrella configuration variables

PDLFS umbrella uses many of the standard cmake variables for
configuration.  The following cmake comment describes this:
```
#
# CMAKE_INSTALL_PREFIX=/usr/local    # installation prefix for all pkgs
# CMAKE_BUILD_TYPE=RelWithDebInfo    # or Release, Debug, etc.
# CMAKE_PREFIX_PATH=''               # list of additional search dirs for pkgs
#
# UMBRELLA_BUILDTESTS=OFF            # build unit tests?
# UMBRELLA_RUNTESTS=OFF              # skip running unit tests?
#
# CMAKE_INCLUDE_PATH=''              # extra include dirs to search
# CMAKE_LIBRARY_PATH=''              # extra lib dirs to search
#
# these variables can all be defined on the cmake command line
# with the -D flag (e.g. -DCMAKE_INSTALL_PREFIX=/usr/pkg ).
#
# note that all PATH variables are in cmake list format.
# if there are multiple directories, quote the variable and
# use ';' between list items.  For example:
#
#    CMAKE_PREFIX_PATH='/usr/dir1;/usr/dir2'
#
# use the more succinct CMAKE_PREFIX_PATH (rather than CMAKE_INCLUDE_PATH
# and # CMAKE_LIBRARY_PATH) when possible.
#
# the CMAKE_BUILD_TYPE is applied to all cmake-based packages.
# it may not app to non-cmake builds (e.g. autotools).
#
# specifying alternate compilers (overrides CC/CXX environment variables):
# CC=/bin/cc
# CXX=/bin/cxx
#  (you can also use the long form names CMAKE_C_COMPILER/CMAKE_CXX_COMPILER)
#
# when UMBRELLA_MPI is set, you can specify which mpi to use by pointing
# at the desired compiler wrappers (otherwise cmake will use your shell's
# path to find them):
# MPI_C_COMPILER=/usr/bin/mpicc
# MPI_CXX_COMPILER=/usr/bin/mpicxx
# MPIEXEC=/usr/bin/mpiexec
#
```

## umbrella option variables

PDLFS umbrella option variables are used to configurure individual
packages that can be built.   (Option variables are built on top
of cmake cache variables.)  Option variables are normally defined
in the umbrella/umbrella/*.cmake files like this:

```
#
# define the string option variable "BMI_TAG" and assign it the default
# value of "main" if it is not currently defined by the user.  if the
# user has already defined "BMI_TAG" then we use their value rather than
# the default.  The option variable we be stored in a cmake cache variable.
#
umbrella_defineopt (BMI_TAG "main" STRING "BMI GIT tag")
```

The option variable's default value can be overridden in your project's
CMakeLists.txt using umbrella_opt_default(), like this:

```
#
# for this project, change the default BMI_TAG value to "6ea0b78f" rather
# than using the "main" default.
#
umbrella_opt_default (BMI_TAG "6ea0b78f")
```

The modified project default value set by umbrella_opt_default() can
be overridden on the cmake command line using the -D flag:
```
cmake -DBMI_TAG="5c312711"
```

This provides a hierarchy of ways an umbrella option variable can be
set.  User specified values (e.g. -D on the command line) are used first.
If the user has not specified a value, then the value passed to
umbrella_opt_default() by the project is used.  Finally, if the project does
not use umbrella_opt_default(), then the default set with umbrella_defineopt()
in the umbrella/umbrella/*.cmake files is used.

Commonly used option variables for projects include:
variable | use
--- | ---
*_TAG | revision to check out when using a source code control system
*_REPO | URL of repository to checkout (e.g. github)
*_TAR | tar file of source code (when using a local tar file cache)
*_BASEURL | URL to get srcs from (when not using a source code control system)
*_URLDIR | subdirectory of BASEURL to use
*_URLFILE | file to download (when using BASEURL)
*_URLMD5 | MD5 of the downloaded file (it will be checked)

## umbrella settings

PDLFS umbrella settings provide a way to easily support sharing
configurations across projects being built.  A setting is defined
by a setting name and a set of possible values for that setting.
"ON" and "OFF" are the default set of possible values for a setting.
The setting name and possible values are used to define a set of
cmake variables starting with "UMBRELLA_" that can be searched by
target to see if the setting applies to it.

For example, we can define an umbrella setting "BUILDTESTS" with
possible values of "ON" and "OFF" to control if a project's unit
tests are built or not.  This uses three cmake variables:
* UMBRELLA_BUILDTESTS: the global default for BUILDTESTS ("ON" or "OFF")
* UMBRELLA_BUILDTESTS_ON: cmake list of targets to have BUILDTESTS set to ON
* UMBRELLA_BUILDTESTS_OFF: cmake list of targets to have BUILDTESTS set to OFF

This allows users to do things like:
```
# disable BUILDTESTS by default, but turn it on for bmi and psm
cmake -DUMBRELLA_BUILDTESTS=OFF -DUMBRELLA_BUILDTESTS_ON='bmi;psm'

# enable BUILDTESTS by default, but turn it off for ofi
cmake -DUMBRELLA_BUILDTESTS=ON -DUMBRELLA_BUILDTESTS_OFF='ofi'
```

Internally, the umbrella_setting() function is used to search umbrella
settings for a given target.  The result of this search is often used
to link a target's default value for an option variable to an umbrella-wide
setting.  For example, the "bmi" target may do:
```
#
# set value of BMI_BUILDTESTS based on umbrella BUILDTESTS setting.
# if BMI_BUILDTESTS is already defined, it is left unchanged.
#
umbrella_setting(BUILDTESTS bmi BMI_BUILDTESTS)

#
# define BMI_BUILDTESTS as an option variable.  Since we just used
# umbrella_setting() above to set BMI_BUILDTESTS, its current value
# will be used as the default value (rather than the "OFF" in the
# call to umbrella_defineopt() below).
#
umbrella_defineopt(BMI_BUILDTESTS OFF BOOL "Build bmi unit tests")
```

## notes

Note that umbrella scripts define build targets based on their
name.  For example, umbrella/mercury defines a "mercury" target
for building mercury from source.  This means that you cannot have
both the umbrella/mercury script and then normal cmake
"find_package(mercury)" active at the same time since the "mercury"
target can only be defined once (cmake targets are global).

Also note that it is possible to exclude umbrella targets from
make's "all" target using the "EXCLUDE_FROM_ALL" property.  For
example, the following command excludes mercury-runner from the
"all" target (but you can still run "make mercury-runner" to build
the target).
```
set_property (TARGET mercury-runner PROPERTY EXCLUDE_FROM_ALL True)
```

# umbrella internals

The main directory contains three scripts.

The umbrella-init.cmake script handles setting the C and C++
compilers on the command line using flags like -DCC=/bin/cc and
-DCXX=/bin/c++.   This script should be included before the project()
command.

The umbrella-main.cmake script contains all the common umbrella code.
It uses or sets up config variables including (default values shown at end):
* UMBRELLA_PREFIX: root of umbrella directory
* UMBRELLA_MPI: set to enable MPI (off)
* UMBRELLA_BUILDTESTS: default setting for building unit tests (off)
* UMBRELLA_RUNTESTS: default setting for running unit tests (off)
* UMBRELLA_PATCHDIR: internal directory for patches (UMBRELLA_PREFIX/patches)
* UMBRELLA_USER_PATCHDIR: set for user-level patch directory (CMAKE_SOURCE_DIR/patches)
* UMBRELLA_HAS_GNULIBDIRS: built pkg has non-"lib" dir (eg. "lib64") (off)
* UMBRELLA_CPPFLAGS: C preprocessor flags for autotool config scripts
* UMBRELLA_LDFLAGS: link flags for autotool config scripts
* UMBRELLA_COMP: CC/CXX vars for autotool config scripts
* UMBRELLA_MPICOMP: CC/CXX vars set to MPI for autotool config scripts
* UMBRELLA_PKGCFGPATH: PKG_CONFIG_PATH for pkg-config/autotool config scripts
* UMBRELLA_CMAKECACHE: init cmake cache vars for cmake-based builds
* CMAKE_INSTALL_PREFIX: where to install
* CMAKE_PREFIX_PATH: path to search for other packages
* CMAKE_BUILD_TYPE: Debug, Release, RelWithDebInfo, MinSizeRel

UMBRELLA_BUILDTESTS and UMBRELLA_BUILDTESTS are umbrella settings.
Additional target info can be specified in cmake lists in
UMBRELLA_BUILDTESTS_ON, UMBRELLA_BUILDTESTS_OFF,
UMBRELLA_RUNTESTS_ON, and UMBRELLA_RUNTESTS_OFF.   Targets that
support testing also have target variables (e.g. DELTAFS_RUNTESTS
can be set to ON or OFF).

Targets that support being prebuilt can be set to use a prebuilt
version by adding the target to the UMBRELLA_PREBUILD_ON cmake list
or by setting the target's PREBUILT variable to on (e.g.
FOO_PREBUILT=ON).

The umbrella-main.cmake script contains common functions including:
* umbrella_onlist(list lookfor rv) - look if lookfor is on a list
* umbrella_targetvar_prefix(target result) - gen target var prefix from target
* umbrella_defineopt(var val type doc) - define umbrella option variable
* umbrella_opt_default(var newdefault) - set new default value for option var
* umbrella_setting(setting target result) - check for UMBRELLA_* setting vars
* umbrella_prebuilt_check(target ...) - allow target to be prebuilt
* umbrella_patchcheck(result target) - look for target's patch files
* umbrella_download(result target localtar) - gen download config, honor cache
* umbrella_buildtests(target result) - support buildtests for a target
* umbrella_testcommand(target result) - ret command if testing is enabled

The ensure-autogen script is used to run autotools to generate
a configure script (for projects that ship without a pre-generated one).

Within the main directory there is an umbrella subdirectory that
contains scripts for each project that can be generated.  For
example umbrella/bmi.cmake has the information needed to build BMI.
These script use the variables and functions from umbrella-main.cmake,
config from the user (either via their CMakeLists.txt or command line
-D flags), and their own variables to generate a config for their
package.  They then use cmake's ExternalProject_Add() with this
information to build the project.   The scripts should include their
dependencies within them so that the order they are included does
not matter.

Here is an example umbrella script:
```
umbrella_prebuilt_check(bmi FILE bmi.h)

if (NOT TARGET bmi)

# define option variables
umbrella_defineopt (BMI_REPO "https://github.com/radix-io/bmi.git"
                    STRING "BMI GIT repository")
umbrella_defineopt (BMI_TAG "master" STRING "BMI GIT tag")
umbrella_defineopt (BMI_TAR "bmi-${BMI_TAG}.tar.gz" STRING "BMI cache tar file")

# generate commands for ExternalProject_Add
umbrella_download (BMI_DOWNLOAD bmi ${BMI_TAR}
                   GIT_REPOSITORY ${BMI_REPO} GIT_TAG ${BMI_TAG})
umbrella_patchcheck (BMI_PATCHCMD bmi)

# could include (umbrella/*) here, if we depend on other projects

# create target w/ExternalProject_Add
ExternalProject_Add (bmi ${BMI_DOWNLOAD} ${BMI_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
    ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
    --prefix=${CMAKE_INSTALL_PREFIX} --enable-shared --enable-bmi-only)

# add extra step for "prepare"
ExternalProject_Add_Step (bmi prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/prepare
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif ()    # NOT TARGET bmi
```

First, the call to umbrella_prebuilt_check() allows umbrella to
support using a prebuilt system bmi (rather than building it itself).
If bmi is set to be prebuilt, it verifies this by looking for an
installed bmi.h.

Next, the remaining body of the script is encapsulated within a
"if (NOT TARGET bmi)" conditional.  This allows the file to be
included more than once without error.  Next, the script defines
three umbrella option variables (BMI_REPO, BMI_TAG, and BMI_TAR).
This include their types, default values, and documentation strings.
The script then calls umbrella_download and umbrella_patchcmd.
The umbrella_download() function generates a download command for
this project by first looking to see if there is a cached local tar file
available.  If it is present, then that is used.  Otherwise we
access the project over the internet using git.  Supporting
cached local tar files is important for environments where access
to the internet is restricted.

The umbrella_patchcmd looks for patches in 4 places and generates
commands to apply any patches found.  Using "bmi" the search order
for patch files is:
1. umbrella/patches/bmi.patch
1. umbrella/patches/bmi-CMAKE_SYSTEM_NAME.patch
1. UMBRELLA_USER_PATCHDIR/bmi.patch
1. UMBRELLA_USER_PATCHDIR/bmi-CMAKE_SYSTEM_NAME.patch
The user has the option of creating their own patch directory by
setting UMBRELLA_USER_PATCHDIR.  If UMBRELLA_USER_PATCHDIR is not set,
then umbrella_patchcmd does not search for patches there.

Next, we call ExternalProject_Add() to create the target.  For
bmi, we call the autotools "configure" script.  We pass
UMBRELLA_COMP, UMBRELLA_CPPFLAGS, and UMBRELLA_LDFLAG to the
configure script to pass the environment to the autoconfig scripts.
We also use the --prefix flag with CMAKE_INSTALL_PREFIX to pass
the prefix in.  Finally, the bmi git repository does not include
a pre-generated "configure" script, so we add a "prepare" step
to the build that uses the "ensure-autogen" script to run automake
and friends to generate a new configure script if it is not already
present.

For tools that use pkg-config and need a path for that, you can
pass in ${UMBRELLA_PKGCFGPATH} into the configure script to have
pkg-config search CMAKE_PREFIX_PATH and CMAKE_INSTALL_PREFIX for
*.pc files.

For cmake-based packages, we provide ${UMBRELLA_CMAKECACHE} to
be used with ExternalProject_Add's CMAKE_CACHE_ARGS command to
load the environment into the project.  (bmi uses autotools, so
this is not needed.)

For packages that provide tests, we have the umbrella_testcommand()
function that sets the test command if we are not cross-compiling.
The umbrella_testcommand() honors the RUNTESTS setting.
