# deltafs-umbrella

Download and build deltafs and its dependencies in a single step.

### Requirements
A recent compiler with standard build tools, git, cmake (3.0 or newer), and optionally internet access to github.com.

On Ubuntu 16.04 LTS, these requirements may be installed by:

```
sudo apt-get update
sudo apt-get install gcc g++ make cmake pkg-config
sudo apt-get install autoconf automake libtool
sudo apt-get install libltdl-dev
sudo apt-get install git
```

To build deltafs and install it in a directory (e.g. /tmp/deltafs):

```
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/tmp/deltafs ..
make
```
