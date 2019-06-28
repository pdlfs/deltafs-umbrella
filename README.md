**Download, build, and install deltafs, its friends, and their minimum dependencies in a single step.**

[[README for Cray]](README.cray.md) | [[README for PDL]](README.pdl.md)

[![Build Status](https://travis-ci.org/pdlfs/deltafs-umbrella.svg?branch=master)](https://travis-ci.org/pdlfs/deltafs-umbrella)
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

### Overview

This package is designed to help our collaborators to quickly setup deltafs on various computing platforms ranging from commodity NFS PRObE clusters to highly-specialized Cray systems customized by different national labs. The package features a highly-automated process that downloads, builds, and installs deltafs (including many of its friends and all their dependencies) along with a demo application (VPIC) that has been preloaded to use deltafs to perform file system activities.

Written on top of cmake, deltafs-umbrella is expected to work with most major computing platforms. We have successfully tested deltafs-umbrella on CMU PDL Narwhal, NERSC Edison, as well as NERSC Cori.

### Modules

* deltafs dependencies
  * libch-placement (http://xgitlab.cels.anl.gov/codes/ch-placement.git)
  * mssg (https://github.com/pdlfs/mssg.git)
  * mercury-rpc (https://github.com/mercury-hpc/mercury.git)
  * bmi (http://git.mcs.anl.gov/bmi.git)
  * libfabric (https://github.com/ofiwg/libfabric.git)
  * cci (https://github.com/CCI/cci.git)
* deltafs
  * deltafs (https://github.com/pdlfs/deltafs.git)
  * deltafs-common (https://github.com/pdlfs/pdlfs-common.git)
  * deltafs-nexus (https://github.com/pdlfs/deltafs-nexus.git)
  * deltafs-bb (https://github.com/pdlfs/deltafs-bb.git)
* vpic
  * deltafs-vpic-preload (https://github.com/pdlfs/deltafs-vpic-preload.git)
  * vpic (https://github.com/pdlfs/vpic.git)
* support
  * mercury-runner (https://github.com/pdlfs/mercury-runner.git)
  * nexus-runner (https://github.com/pdlfs/nexus-runner.git)

### Installation

A recent CXX compiler (e.g., gcc 5 or later) with standard building tools including make, cmake (used by deltafs), and automake (used by some of our dependencies), as well as a few other common library packages such as libpapi and libnuma (for debugging and performance montoring).

On Ubuntu systems, these software requirements can be met by:

```bash
sudo apt-get install gcc g++ make cmake autoconf automake libtool pkg-config libpapi-dev libnuma-dev git
```

To build deltafs and install it under a specific prefix (e.g., $HOME/deltafs):

```bash
export GIT_SSL_NO_VERIFY=true

mkdir -p $HOME/deltafs
cd $HOME/deltafs

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
  -DMERCURY_NA_INITIALLY_ON="bmi;sm" \
  -DMERCURY_POST_LIMIT=OFF \
  -DMERCURY_CHECKSUM=OFF \
  ../deltafs-umbrella
make
```

### Run vpic with mpi on top of deltafs

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
