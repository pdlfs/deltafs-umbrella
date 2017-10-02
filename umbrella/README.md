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

```
cmake_minimum_required (VERSION 3.0)

list (APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/umbrella")
include (umbrella-init)
```

Next, start the project, marking as using C and CXX if you want to
use MPI (this allows us to probe for the local MPI config in the 
umbrella and pass that down to software we build).  Also set
the variable UMBRELLA_MPI if MPI is in use.  Then include umbrella-main:

```
project (deltafs-umbrella C CXX)

set (UMBRELLA_MPI 1)         # if using MPI
include (umbrella-main)
```

Now you can set up the configuration by setting variables.  For example,
the umbrella/mercury script takes the initial default list of enabled network
backends in the MERCURY_NA_INITIALLY_ON variable.  Once you have setup
the config, then you can include all the desired umbrella scripts:

```
umbrella_opt_default (MERCURY_NA_INITIALLY_ON "bmi;cci;ofi;sm")
include (umbrella/mercury)
include (umbrella/mercury-runner)
```

Note that umbrella scripts define build targets based on their
name.  For example, umbrella/mercury defines a "mercury" target
for building mercury from source.  This means that you cannot have
both the umbrella/mercury script and then normal cmake 
"find_package(mercury)" active at the same time since the "mercury"
target can only be defined once (cmake targets are global).

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
* UMBRELLA_CPPFLAGS - preprocessor flags for autotool config scripts
* UMBRELLA_LDFLAGS - link flags for autotool config scripts
* UMBRELLA_COMP - CC/CXX vars for autotool config scripts
* UMBRELLA_MPICOMP - CC/CXX vars set to MPI for autotool config scripts
* UMBRELLA_PKGCFGPATH - PKG_CONFIG_PATH for autotool config scripts
* UMBRELLA_CMAKECACHE - init cmake cache vars for cmake-based builds

The umbrella-main.cmake script contains common functions including:
* umbrella_patchcheck(result target) - look for target's patch files
* umbrella_download(result target localtar) - gen download config, honor cache
* umbrella_onlist(list lookfor rv) - look if lookfor is on a list
* umbrella_testcommand(result) - ret command if testing is enabled

The ensure-autogen script is used to run autotools to generate
a configure script (for projects that ship without a pregenereated one).

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
