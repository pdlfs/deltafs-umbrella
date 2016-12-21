**Download, build, and install deltafs, its friends, and their minimum dependencies in a single step.**

[[README for Cray]](README.cray.md) | [[README for PDL]](README.pdl.md)

[![Build Status](https://travis-ci.org/pdlfs/deltafs-umbrella.svg?branch=master)](https://travis-ci.org/pdlfs/deltafs-umbrella)

# deltafs-umbrella

This package is designed to help our collaborators to quickly setup deltafs on various computing platforms ranging from commodity NFS PRObE clusters to highly-specialized Cray systems customized by different national labs. The package features a highly-automated process that downloads, builds, and installs deltafs (including many of its friends and all their dependencies) along with a demo application (VPIC) that has been preloaded to use deltafs to perform file system activities.

Written on top of cmake, deltafs-umbrella is expected to work with most major computing platforms. We have successfully tested deltafs-umbrella on CMU PDL Narwhal, NERSC Edison, as well as NERSC Cori.

### Modules

* deltafs dependencies
  * libch-placement (http://xgitlab.cels.anl.gov/codes/ch-placement.git)
  * mercury rpc (https://github.com/mercury-hpc/mercury.git)
  * cci (http://cci-forum.com/wp-content/uploads/2016/06/cci-2.0.tar.gz)
  * bmi (http://git.mcs.anl.gov/bmi.git)
* deltafs
  * deltafs (https://github.com/pdlfs/deltafs.git)
* vpic
  * deltafs-vpic-preload (https://github.com/pdlfs/deltafs-vpic-preload.git)
  * vpic (https://github.com/pdlfs/vpic.git)

### Installation

A recent CXX compiler with standard building tools including make, cmake (used by deltafs), and automake (used by some of our dependencies), as well as a few other common library packages including libboost (used by mercury rpc) and libltdl (used by cci).

On Ubuntu 16.04, these requirements can be obtained by:

```
sudo apt-get update  # Optional, but recommended

sudo apt-get install gcc g++ make cmake
sudo apt-get install autoconf automake libtool pkg-config
sudo apt-get install libboost-dev libltdl-dev libopenmpi-dev
sudo apt-get install libibverbs-dev librdmacm-dev  # Optional, needed by cci
sudo apt-get install openmpi-bin git
```

To build deltafs and install it in a given prefix (e.g. $HOME/deltafs):

```
mkdir -p $HOME/deltafs/src

cd $HOME/deltafs/src
git clone https://github.com/pdlfs/deltafs-umbrella.git
mkdir -p deltafs-umbrella-build
cd deltafs-umbrella-build
cmake -DCMAKE_INSTALL_PREFIX=$HOME/deltafs ../deltafs-umbrella

make
```

### Run vpic with mpi

First, start deltafs metadata server processes:

*// We have used openmpi's command line syntax. Different mpi distributions usually have slightly different syntaxes.*

```
rm -rf $HOME/deltafs/var && mkdir -p $HOME/deltafs/var

export DELTAFS_RunDir="$HOME/deltafs/var/run"
export DELTAFS_Outputs="$HOME/deltafs/var/metadata"
export DELTAFS_MetadataSrvAddrs="<node_ip>:10101"
export DELTAFS_FioConf="root=$HOME/deltafs/var/data"
export DELTAFS_FioName="posix"

mpirun -n 1 -x DELTAFS_MetadataSrvAddrs -x DELTAFS_FioName -x DELTAFS_FioConf -x DELTAFS_Outputs -x DELTAFS_RunDir \
        $ROOT/bin/deltafs-srvr

```

Second, start vpic app:

```
mpirun -np 16 [ -npernode ... ] [ -hostfile ... ] -x "PDLFS_Root=particle" -x "DELTAFS_MetadataSrvAddrs=<node_ip>:10101" \
        -x "LD_PRELOAD=$HOME/deltafs/lib/libdeltafs-preload.so" \
        $HOME/deltafs/bin/turbulence-part.op 
```

**Enjoy** :-)
