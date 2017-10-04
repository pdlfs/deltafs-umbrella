# PDLFS umbrella

PDLFS umbrella is an embeddable cmake-based framework for building
third party software.  It is designed to be embedded within other
projects as a git subrepo (https://github.com/ingydotnet/git-subrepo).
Note that only developers need to know that the umbrella is
a git subrepo.  Non-developers will see the umbrella as a
normal git directory and do not need to install git subrepo.

# usage

First you must embed umbrella in the repository you want to use
it then.  Once umbrella is embedded, you can use cmake to link
into it.

## embed umbrella (using git subrepo)

To embed PDLFS umbrella into a repository, you must first install
git subrepo (see URL above).   Then you check out your repository
and then use "git subrepo clone repo subdir" to embed umbrella within it.
Here is an example of embedding PDLFS umbrella inside the
deltafs-umbrella:

```
% cd deltafs-umbrella
% git subrepo clone git@dev.pdl.cmu.edu:pdlfs/umbrella umbrella
Subrepo 'git@dev.pdl.cmu.edu:pdlfs/umbrella' (master) cloned into 'umbrella'.
%
```

After finishing the "subrepo clone" you would normally push the
result into the repository hosting the subrepo (i.e. in this case
you would do a "git push" after the subrepo clone to push the result
to deltafs-umbrella).

If you are an umbrella developer you can push and pull changes
from your repository to the umbrella repository.  For example,
to pull in the latest changes from the umbrella repository into
your repository you can use "git subrepo pull" like this:

```
% cd deltafs-umbrella
% git subrepo pull umbrella
Subrepo 'umbrella' pulled from 'git@dev.pdl.cmu.edu:pdlfs/umbrella' (master).
chuck@h0:/proj/TableFS/data/chuck/src/deltafs-umbrella % git status
On branch master
Your branch is ahead of 'origin/master' by 2 commits.
  (use "git push" to publish your local commits)

nothing to commit, working directory clean
% git push
```

Or, if you want to make a change to umbrella in your repository and
then push it to the umbrella repository you can use "git subrepo push"
like this:

```
% cd deltafs-umbrella
% vi umbrella/README.md
...
% git add umbrella/README.md
% git commit
% git push
...
% git subrepo push umbrella
Subrepo 'umbrella' pushed to 'git@dev.pdl.cmu.edu:pdlfs/umbrella' (master).
%
```

## using umbrella

First note that umbrella honors the following cmake config variables,
as described in this comment:
```
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
```

In your main CMakeLists.txt file, you start by specifying the
required cmake version.  Then you add the umbrella subrepo to
the CMAKE_MODULE_PATH and include umbrella-init.   This should
be done before the project() call.  The umbrella-init file
does some early processing (e.g. like allowing you to specify
the compiler on the command line).

```
cmake_minimum_required (VERSION 3.0)

list (APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/umbrella")
include (umbrella-init)
```

Next, start the project, marking it as using C and CXX if you want to
use MPI (this allows us to probe for the local MPI config in the
umbrella and pass that down to software we build).  Also set
the variable UMBRELLA_MPI if MPI is in use.  Then include umbrella-main.
The umbrella-main has code to setup shared umbrella variables and
also includes all the shared functions provided by the umbrella
framework.

```
project (deltafs-umbrella C CXX)

set (UMBRELLA_MPI 1)         # if using MPI
include (umbrella-main)
```

Now you can set up the configuration by setting variables.  Each
umbrella include has a set of option variables such as the
URL for downloading the package or the git tag to check out when
building the package.  For example, the umbrella/bmi include defines
BMI_TAG to be "master" meaning check out the most recent version
of BMI to compile.

Users can change the default values of the umbrella option variables
by calling umbrella_opt_default() on them to set a new value.  For
example:

```
umbrella_opt_default (BMI_TAG "49234ab")
```
changes the default tag for BMI from the value "master" (specified
in the included umbrella/bmi) to "49234ab" allowing your project to
lock down to a specific version of BMI.   Note that default values
set by umbrella_opt_default() can be overridden in three ways:
1. using "ccmake" to edit and change the value
1. running cmake with a new "-D" value on the command line
1. hardwiring the variable to a new value in the CMakeLists.txt file with set()


Once you have setup all the umbrella option variable to the desired
configuration, you can then include all the desired umbrella scripts.
For example, the next block of code sets a mercury option variable
and then pulls in the umbrella scripts for building mercury and
mercury-runner.
```
umbrella_opt_default (MERCURY_NA_INITIALLY_ON "bmi;cci;ofi;sm")
include (umbrella/mercury)
include (umbrella/mercury-runner)
```

Running cmake on the example CMakeLists.txt data shown above
produces a makefile that will download, compile, and install
mercury and mercury-runner.

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

## umbrella internals

The main directory contains three scripts.

The umbrella-init.cmake script handles setting the C and C++
compilers on the command line using flags like -DCC=/bin/cc and
-DCXX=/bin/c++.   This script should be included before the project()
command.

The umbrella-main.cmake script contains all the common umbrella code.
It uses or sets up config variables including:
* UMBRELLA_PREFIX - root of umbrella directory
* UMBRELLA_MPI - set to enable MPI
* CMAKE_BUILD_TYPE - Debug, Release, RelWithDebInfo, MinSizeRel
* UMBRELLA_BUILD_TESTS - set to build tests
* UMBRELLA_PATCHDIR - internal directory for patches
* UMBRELLA_SKIP_TESTS - set to skip running tests (e.g. for crosscompile)
* UMBRELLA_USER_PATCHDIR - set for user-level patch directory
* UMBRELLA_CPPFLAGS - C preprocessor flags for autotool config scripts
* UMBRELLA_LDFLAGS - link flags for autotool config scripts
* UMBRELLA_COMP - CC/CXX vars for autotool config scripts
* UMBRELLA_MPICOMP - CC/CXX vars set to MPI for autotool config scripts
* UMBRELLA_PKGCFGPATH - PKG_CONFIG_PATH for pkg-config/autotool config scripts
* UMBRELLA_CMAKECACHE - init cmake cache vars for cmake-based builds

The umbrella-main.cmake script contains common functions including:
* umbrella_patchcheck(result target) - look for target's patch files
* umbrella_download(result target localtar) - gen download config, honor cache
* umbrella_onlist(list lookfor rv) - look if lookfor is on a list
* umbrella_testcommand(result) - ret command if testing is enabled
* umbrella_defineopt(var val type doc) - define umbrella option variable
* umbrella_opt_default(var newdefault) - set new default value for option var

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
if (NOT TARGET bmi)

# define option variables
umbrella_defineopt (BMI_REPO "http://git.mcs.anl.gov/bmi.git"
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

First, the entire body of the script is encapsulated within a
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
1. umbrella/patches/bmi-${CMAKE_SYSTEM_NAME}.patch
1. ${UMBRELLA_USER_PATCHDIR}/bmi.patch
1. ${UMBRELLA_USER_PATCHDIR}/bmi-${CMAKE_SYSTEM_NAME}.patch
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

For packages that provide tests, we have the umbrella_testcommand ()
function that sets the test command if we are not cross-compiling
and UMBRELLA_BUILD_TESTS is set and UMBRELLA_SKIP_TESTS is not set.
