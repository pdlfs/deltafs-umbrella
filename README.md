**Download, build, and install deltafs, its friends, and their minimum dependencies in a single step.**

# deltafs-umbrella

This package is designed to help our collaborators to quickly setup deltafs on various computing platforms ranging from commodity NFS PRObE clusters to highly-specialized Cray systems customized by different national labs. The package features a highly-automated process that downloads, builds, and installs deltafs (including many of its friends and all their dependencies) along with a demo application (VPIC) that has been preloaded to use deltafs to perform file system activities.

Written on top of cmake, deltafs-umbrella is expected to work with most major computing platforms. We have successfully tested deltafs-umbrella on CMU PDL Narwhal, NERSC Edison, as well as NERSC Cori.

### Modules

* deltafs dependencies
  * mercury rpc
  * cci
  * bmi
* deltafs
  * deltafs
* vpic
  * deltafs-vpic-preload
  * vpic

### Requirements

A recent CXX compiler with standard building tools including make, cmake (used by deltafs), and automake (used by some of our dependencies), as well as a few other common library packages including libboost (used by mercury rpc) and libltdl (used by cci).

On Ubuntu 16.04, these requirements can be obtained by:

```
sudo apt-get update # Optional, but recommended

sudo apt-get install gcc g++ make cmake
sudo apt-get install autoconf automake libtool pkg-config
sudo apt-get install libboost-dev libltdl-dev
sudo apt-get install git
```

To build deltafs and install it in a directory (e.g. /tmp/deltafs):

```
git clone https://github.com/pdlfs/deltafs-umbrella.git
cd deltafs-umbrella

mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/tmp/deltafs ..

make
```

## Enjoy :-)
