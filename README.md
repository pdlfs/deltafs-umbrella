**Download, build, and install deltafs, its friends, and their minimum dependencies in a single step.**

[[README for LANL Trinity]](#lanl-trinitytrinitite) | [[README for LANL Grizzly]](#lanl-grizzly)

[![CI](https://github.com/pdlfs/deltafs-umbrella/actions/workflows/ci.yml/badge.svg)](https://github.com/pdlfs/deltafs-umbrella/actions/workflows/ci.yml)
[![GitHub (pre-)release](https://img.shields.io/github/release-pre/pdlfs/deltafs-umbrella.svg)](https://github.com/pdlfs/deltafs-umbrella/releases)
[![License](https://img.shields.io/badge/license-New%20BSD-blue.svg)](LICENSE.txt)

deltafs-umbrella
================

```
XXXXXXXXX
XX      XX                 XX                  XXXXXXXXXXX
XX       XX                XX                  XX
XX        XX               XX                  XX
XX         XX              XX   XX             XX
XX          XX             XX   XX             XXXXXXXXX
XX           XX  XXXXXXX   XX XXXXXXXXXXXXXXX  XX         XX
XX          XX  XX     XX  XX   XX       XX XX XX      XX
XX         XX  XX       XX XX   XX      XX  XX XX    XX
XX        XX   XXXXXXXXXX  XX   XX     XX   XX XX    XXXXXXXX
XX       XX    XX          XX   XX    XX    XX XX           XX
XX      XX      XX      XX XX   XX X    XX  XX XX         XX
XXXXXXXXX        XXXXXXX   XX    XX        XX  XX      XX
```

DeltaFS was developed, in part, under U.S. Government contract 89233218CNA000001 for Los Alamos National Laboratory (LANL), which is operated by Triad National Security, LLC for the U.S. Department of Energy/National Nuclear Security Administration. Please see the accompanying [LICENSE.txt](LICENSE.txt) for further information. 

## Overview

This package is designed for quickly setting up deltafs on various computing platforms ranging from commodity NFS PRObE clusters to highly-optimized HPC systems used in national labs. The package features an automated process that downloads, builds, and installs deltafs (including its software dependencies) in a single step. A demo application (VPIC) is also included in this package for showcasing the filesystem's in-situ capabilities.

Written atop cmake, deltafs-umbrella is expected to work with major computing platforms. We have successfully tested deltafs-umbrella on CMU PDL Narwhal, LANL Trinity, LANL Grizzly, NERSC Edison, and NERSC Cori.

## Modules

* deltafs dependencies
  * libch-placement (http://xgitlab.cels.anl.gov/codes/ch-placement.git)
  * mssg (https://github.com/pdlfs/mssg.git)
  * mercury-rpc (https://github.com/mercury-hpc/mercury.git)
  * bmi (https://xgitlab.cels.anl.gov/sds/bmi.git)
  * libfabric (https://github.com/ofiwg/libfabric.git)
  * cci (https://github.com/CCI/cci.git)
* deltafs
  * deltafs (https://github.com/pdlfs/deltafs.git)
  * deltafs-common (https://github.com/pdlfs/pdlfs-common.git)
  * deltafs-nexus (https://github.com/pdlfs/deltafs-nexus.git)
  * deltafs-bb (https://github.com/pdlfs/deltafs-bb.git)
* vpic
  * deltafs-vpic-preload (https://github.com/pdlfs/deltafs-vpic-preload.git)
  * vpic v407 (https://github.com/pdlfs/vpic407.git)
  * vpic (https://github.com/pdlfs/vpic.git)
* support
  * osu-micro-benchmarks (https://github.com/pdlfs/osu-micro-benchmarks.git)
  * mercury-runner (https://github.com/pdlfs/mercury-runner.git)
  * nexus-runner (https://github.com/pdlfs/nexus-runner.git)

## Installation

A recent CXX compiler (e.g., gcc 5 or later) with standard building tools including make, cmake (used by deltafs), and automake (used by some of our dependencies), as well as a few other common library packages such as libpapi and libnuma (for debugging and performance montoring).

### Ubuntu

On Ubuntu systems, these software requirements can be met by:

```bash
sudo apt-get install gcc g++ make cmake autoconf automake libtool pkg-config libpapi-dev libnuma-dev git
```

To build deltafs and install it under a specific prefix (e.g., $HOME/deltafs):

```bash
export GIT_SSL_NO_VERIFY=true  # May be needed on some computing environments

mkdir -p $HOME/deltafs
cd $HOME/deltafs

# After installation, we will have the following:
#
# $HOME/deltafs
#  -- bin
#  -- include
#  -- lib
#  -- src
#      -- deltafs-umbrella
#      -- deltafs-umbrella-build
#  -- share
#

mkdir -p src
cd src
git clone https://github.com/pdlfs/deltafs-umbrella.git
mkdir -p deltafs-umbrella-build
cd deltafs-umbrella-build

cmake -DCMAKE_INSTALL_PREFIX=$HOME/deltafs -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DUMBRELLA_BUILD_TESTS=OFF -DUMBRELLA_SKIP_TESTS=ON \
  -DMERCURY_NA_INITIALLY_ON="bmi;sm" -DMERCURY_POST_LIMIT=OFF \
  -DMERCURY_CHECKSUM=OFF \
../deltafs-umbrella

make

make install

```

### LANL Trinity/Trinitite

**High-level summary: module/slurm/srun/gni**

LANL Trinity/Trinitite is a Cray machine. User-level software packages can be configured via a `module` command. Jobs are scheduled through SLURM and jobs directly run on compute nodes (no "MOM" nodes). MPI jobs should be launched using `srun`. Trinity/Trinitite features two types of compute nodes: Haswell and KNL. All Trinity/Trinitite nodes are interconnected via Cray Aries. 

#### Haswell

Each Trinity/Trinitite Haswell node has 32 CPU cores, 64 hardware threads, and 128GB RAM.

To build deltafs on such nodes:

```bash
export CRAYPE_LINK_TYPE="dynamic"
export CRAYOS_VERSION=6

module unload craype-hugepages2M

module load craype-haswell
module load PrgEnv-gnu
module load cmake

mkdir -p $HOME/deltafs
cd $HOME/deltafs

# After installation, we will have the following:
#
# $HOME/deltafs
#  -- bin
#  -- include
#  -- lib
#  -- src
#      -- deltafs-umbrella
#         -- cache
#         -- cache.0
#      -- deltafs-umbrella-build
#  -- share
#

mkdir -p src
cd src

git clone https://github.com/pdlfs/deltafs-umbrella.git
cd deltafs-umbrella
cd cache
ln -fs ../cache.0/* .
cd ..
cd ..

mkdir -p deltafs-umbrella-build
cd deltafs-umbrella-build

env CC=cc CXX=CC cmake -DCMAKE_INSTALL_PREFIX=$HOME/deltafs \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_PREFIX_PATH="$PAT_BUILD_PAPI_BASEDIR" \
  -DUMBRELLA_BUILD_TESTS=OFF -DUMBRELLA_SKIP_TESTS=ON \
  -DMERCURY_NA_INITIALLY_ON="bmi;ofi;sm" -DMERCURY_POST_LIMIT=OFF \
  -DMERCURY_CHECKSUM=OFF \
../deltafs-umbrella

make

make install

```

Note: we could use `PrgEnv-intel` instead of `PrgEnv-gnu` but the former currently does not provide `<stdatomic.h>`, which is used by a few of our software dependencies.

#### KNL

Each Trinity/Trinitite KNL node has 68 CPU cores, 272 hardware threads, and 96GB RAM. To build deltafs on such nodes, change `module load craype-haswell` to `module load craype-mic-knl`.

### LANL Grizzly

**High-level summary: module/slurm/srun/psm2**

LANL Grizzly is a Penguin machine. User-level software packages can be configured via a `module` command. Jobs are scheduled through SLURM and jobs directly run on compute nodes (no "MON" nodes). MPI jobs should be launched using `srun`. Each Grizzly node has 36 CPU cores and 64GB RAM. Grizzly compute nodes are interconnected via Intel Omni-Path.

To build deltafs on LANL Grizzly:

```bash
module add cmake gcc intel-mpi

mkdir -p $HOME/deltafs
cd $HOME/deltafs

# After installation, we will have the following:
#
# $HOME/deltafs
#  -- bin
#  -- include
#  -- lib
#  -- src
#      -- deltafs-umbrella
#         -- cache
#         -- cache.0
#      -- deltafs-umbrella-build
#  -- share
#

mkdir -p src
cd src

git clone https://github.com/pdlfs/deltafs-umbrella.git
cd deltafs-umbrella
cd cache
ln -fs ../cache.0/* .
cd ..
cd ..

mkdir -p deltafs-umbrella-build
cd deltafs-umbrella-build

cmake -DCMAKE_INSTALL_PREFIX=$HOME/deltafs -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DUMBRELLA_BUILD_TESTS=OFF -DUMBRELLA_SKIP_TESTS=ON \
  -DMERCURY_NA_INITIALLY_ON="bmi;ofi;sm" -DMERCURY_POST_LIMIT=OFF \
  -DMERCURY_CHECKSUM=OFF \
../deltafs-umbrella

make

make install

```

### Notes on C++ Compilers

Deltafs code is written in C++ 98 and can be compiled with g++ 4.4 or later. A few deltafs dependencies need atomic primitives and may require a more recent C/C++ compiler.

#### stdatomic.h

Mercury RPC, one critical deltafs dependency, implements atomic counters using whatever is available on the current system (e.g., OPA library, stdatomic.h, OSX's OSAtomic.h, the windows API). On Linux, when the C compiler (such as gcc 4.8 or eariler) cannot provide stdatomic.h, the OPA (Open Portable Atomics) library must be installed in order to compile mercury. There are at least 3 ways to install this library. The easiest way is to install CCI along with mercury since CCI uses and will install OPA alongside itself. In addition, MPICH also ships with OPA so installing MPICH will install OPA too. Finally, one can always compile and install OPA as a standalone library: https://github.com/pmodels/openpa.

#### _Atomic

Some components in the libfabric codebase make use of the "_Atomic" qualifier defined in c11: https://en.cppreference.com/w/c/atomic. Eariler C compilers (such as gcc 4.8 or eariler, and Intel icc 17.0 or eariler) may not recognize it, and may not even have stdatomic.h. To work around this issue, one simply has to use a compiler that understands _Atomic.

## Run vpic with mpi on top of deltafs

Running vpic is a two step process.  First you run vpicexpt_gen.pl to generate a set of one or more vpic run scripts, then you can run vpic with the generated scripts.

For example, to generate scripts for a "minimal" run:
```
mkdir $HOME/deltafs/runs
$HOME/deltafs/scripts/vpicexpt_gen.pl --experiment minimal $HOME/deltafs/runs
```

This will generate $HOME/deltafs/runs/vpic-minimal-0-baseline.sh and $HOME/deltafs/runs/vpic-minimal-0-deltafs.sh for running a minimal baseline and deltafs run.

Before running these scripts, keep in mind that all vpic output goes to the directory specified in the $JOBDIRHOME environment variable.  If $JOBDIRHOME is not set, then the default directory is $HOME/jobs.  Typically we point $JOBDIRHOME to a scratch parallel filesystem since vpic may generate alot of output.

Run vpic:
```
$HOME/deltafs/runs/vpic-minimal-0-baseline.sh

$HOME/deltafs/runs/vpic-minimal-0-deltafs.sh
```

After doing a run, cleanup $JOBDIRHOME if needed.

Note: it is assumed that $HOME is backed by a shared file system that can be accessed by all mpi nodes.

**Enjoy** :-)
