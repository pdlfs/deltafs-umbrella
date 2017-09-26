**Download, build, and install deltafs, its friends, and their minimum dependencies in a single step.**

[[README for Cray]](README.cray.md) | [[README for PDL]](README.pdl.md)

[![Build Status](https://travis-ci.org/pdlfs/deltafs-umbrella.svg?branch=master)](https://travis-ci.org/pdlfs/deltafs-umbrella)

# deltafs-umbrella

This package is designed to help our collaborators to quickly setup deltafs on various computing platforms ranging from commodity NFS PRObE clusters to highly-specialized Cray systems customized by different national labs. The package features a highly-automated process that downloads, builds, and installs deltafs (including many of its friends and all their dependencies) along with a demo application (VPIC) that has been preloaded to use deltafs to perform file system activities.

Written on top of cmake, deltafs-umbrella is expected to work with most major computing platforms. We have successfully tested deltafs-umbrella on CMU PDL Narwhal, NERSC Edison, as well as NERSC Cori.

### Modules

* deltafs dependencies
  * libch-placement (http://xgitlab.cels.anl.gov/codes/ch-placement.git)
  * ssg (https://xgitlab.cels.anl.gov/sds/ssg.git)
  * mercury-rpc (https://github.com/mercury-hpc/mercury.git)
  * bmi (http://git.mcs.anl.gov/bmi.git)
  * libfabric (https://github.com/ofiwg/libfabric.git)
  * cci (https://github.com/CCI/cci.git)
* deltafs
  * deltafs (https://github.com/pdlfs/deltafs.git)
  * deltafs-nexus (https://github.com/pdlfs/deltafs-nexus.git)
  * deltafs-bb (https://github.com/pdlfs/deltafs-bb.git)
* vpic
  * deltafs-vpic-preload (https://github.com/pdlfs/deltafs-vpic-preload.git)
  * vpic (https://github.com/pdlfs/vpic.git)

### Installation

A recent CXX compiler with standard building tools including make, cmake (used by deltafs), and automake (used by some of our dependencies), as well as a few other common library packages including libboost (used by mercury rpc) and libltdl (used by cci).

On Ubuntu 16.04.2, these requirements could be obtained by:

```
sudo apt-get update  # Optional, though highly recommended
sudo apt-get install gcc g++ make cmake
sudo apt-get install autoconf automake libtool pkg-config
sudo apt-get install libboost-dev libltdl-dev libopenmpi-dev
sudo apt-get install libibverbs-dev librdmacm-dev  # Optional, needed by cci in order to enable ibverbs
sudo apt-get install openmpi-bin git
```

To build deltafs and install it under a specific prefix (e.g. $HOME/deltafs):

```
export GIT_SSL_NO_VERIFY=true  # Assuming bash

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
cmake -DCMAKE_INSTALL_PREFIX=$HOME/deltafs \
    ../deltafs-umbrella
make
```

### Run vpic with mpi on top of deltafs

*// We have used openmpi's command line syntax. Different mpi distributions usually have slightly different syntaxes.*

First, start a single deltafs metadata server process:

```
rm -rf $HOME/deltafs/var && mkdir -p $HOME/deltafs/var

export DELTAFS_RunDir="$HOME/deltafs/var/run"
export DELTAFS_Outputs="$HOME/deltafs/var/metadata"
export DELTAFS_FioConf="root=$HOME/deltafs/var/data"
export DELTAFS_FioName="posix"

mpirun -n 1 -x DELTAFS_FioName \
       -x DELTAFS_FioConf \
       -x DELTAFS_Outputs \
       -x DELTAFS_RunDir \
       $HOME/deltafs/bin/deltafs-srvr

```

Second, start vpic app:

```
mpirun -np 16 [ -npernode ... ] [ -hostfile ... ] -x "DELTAFS_RunDir=$HOME/deltafs/var/run" \
       -x "LD_PRELOAD=$HOME/deltafs/lib/libdeltafs-preload.so" \
       -x "PDLFS_Root=particle" \
       $HOME/deltafs/bin/turbulence-part.op
```

Note: it is assumed that $HOME is backed by a shared file system that can be accessed by all mpi nodes.

**Enjoy** :-)
