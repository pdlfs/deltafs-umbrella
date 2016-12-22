**// This file is written for deltafs adoptors that want to experiment with deltafs on a Cray system**

[![Build Status](https://travis-ci.org/pdlfs/deltafs-umbrella.svg?branch=master)](https://travis-ci.org/pdlfs/deltafs-umbrella)

# deltafs-umbrella

Download, build, and install deltafs, deltafs friends, and their dependencies in a single highly-automated step.

This guide assumes a cray-based computing system.

### Step-1: prepare programming env

```
// First, set cray link type to dynamic (required to compile deltafs)
export CRAYPE_LINK_TYPE="dynamic"

// If CRAYOS_VERSION is not in the env, we have to explicitly set it.
export CRAYOS_VERSION=6

// Make sure the desired processor-targeting module (craype-sandybridge,
// craype-haswell, craype-mic-knl, etc.) and the desired PrgEnv-*
// compiling environment (Cray, Intel, GNU, etc.) has been loaded.

// These targeting modules will configure the compiler driver scripts
// (cc, CC, ftn) to compile code optimized for the processor
// on the compute node.

// Second, load a few addition modules needed by deltafs umbrella. 
module load cmake  # v3.5.0+ is required, the newer the better
module load boost  # needed by mercury rpc
```

### Step-2: build deltafs suite

```
// We will be building deltafs under $HOME/deltafs/src.
// After that, deltafs will be install under $HOME/deltafs
mkdir -p $HOME/deltafs/src
cd $HOME/deltafs/src

// First, wget a recent deltafs-umbrella release from github
wget https://github.com/pdlfs/deltafs-umbrella/releases/download/<release>/deltafs-umbrella-<release>.tar.gz
tar xzf deltafs-umbrella-<release>.tar.gz -C .
cd deltafs-umbrella-<release>

// Second, prepolute the cache directory
cd cache
ln -fs ../cache.0/* .
cd ..

// Finally, kick-off the building process
mkdir build
cd build

CC=cc CXX=CC cmake -DCMAKE_INSTALL_PREFIX=$HOME/deltafs \
      -DCMAKE_SYSTEM_NAME=CrayLinuxEnvironment \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo ..

make
```

**Thanks for trying deltafs :-)**
