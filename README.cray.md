**// This file is written for collaborators that are willing to run experiments using deltafs on Cray systems.**

[![Build Status](https://travis-ci.org/pdlfs/deltafs-umbrella.svg?branch=master)](https://travis-ci.org/pdlfs/deltafs-umbrella)

# deltafs-umbrella

Download, build, and install deltafs, deltafs friends, and their dependencies in a single highly-automated step.

This guide assumes a Linux Cray.

### Step-0: Prepare git-lfs

First, get a latest `git-lfs` release from github.com.

The latest release version may be higher than 2.0.0.
```
wget https://github.com/git-lfs/git-lfs/releases/download/v2.0.0/git-lfs-linux-amd64-2.0.0.tar.gz -C .
tar xzf git-lfs-linux-amd64-2.0.0.tar.gz -C .
```
The entire `git-lfs` release consists of a single executable file so we can easily install it by moving it to a directory that belongs to the `PATH`, such as
```
mv git-lfs-2.0.0/git-lfs $HOME/bin/
```
After that, initalize `git-lfs` once by
```
module load git
git lfs install
```

### Step-1: Prepare cray programming env

First, set cray link type to dynamic (required to compile deltafs)
```
export CRAYPE_LINK_TYPE="dynamic"
```
If `CRAYOS_VERSION` is not in the env, we have to explicitly set it.
On Nersc Edison, `CRAYOS_VERSION` is pre-set by the Cray system. On Nersc Cori, which has a newer version of Cray, it is not set.
```
export CRAYOS_VERSION=6
```
Make sure the desired processor-targeting module (such as `craype-sandybridge`, or `craype-haswell`, or `craype-mic-knl`, etc.) has been loaded. These targeting modules will configure the compiler driver scripts (`cc`, `CC`, `ftn`) to compile code optimized for the processors on the compute nodes.
```
module load craype-haswell  # depending on your system
```
Also make sure the desired compiler bundle (`PrgEnv-*` such as Intel, GNU, or Cray) has been configured, such as
```
module load PrgEnv-intel  # depending on your system
```
Now, load a few addition modules needed by deltafs umbrella.
```
module load boost  # needed by mercury rpc
module load cmake  # at least v3.x
```

### Step-2: Build deltafs suite

Assuming `$HOME` is a global file system accessible from all compute, monitor, and head nodes, our plan is to build deltafs under `$HOME/deltafs/src`. After that, deltafs should be installed under `$HOME/deltafs`:
```
#
# $HOME/deltafs
#  -- bin
#  -- decks (vpic input decks)
#  -- include
#  -- lib
#  -- src
#      -- deltafs-umbrella
#          -- cache.0
#          -- cache
#          -- build
#  -- scripts
#  -- share
#
mkdir -p $HOME/deltafs/src
cd $HOME/deltafs/src
```
First, wget a recent deltafs-umbrella release from github:
```
git lfs clone git@github.com:pdlfs/deltafs-umbrella.git
cd deltafs-umbrella
```
Second, prepolute the cache directory:
```
cd cache
ln -fs ../cache.0/* .
cd ..
```
Finally, kick-off the cmake auto-building process:
```
mkdir build
cd build

# Skip unit tests, and tell cmake that we are doing cross-compiling
CC=cc CXX=CC cmake -DSKIP_TESTS=ON -DCMAKE_INSTALL_PREFIX=$HOME/deltafs \
      -DCMAKE_SYSTEM_NAME=CrayLinuxEnvironment \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo ..

make
```

**Thanks for trying deltafs :-)**
