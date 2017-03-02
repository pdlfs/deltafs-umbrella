**// This file is written for collaborators that are willing to run experiments using deltafs on Cray systems.**

[![Build Status](https://travis-ci.org/pdlfs/deltafs-umbrella.svg?branch=master)](https://travis-ci.org/pdlfs/deltafs-umbrella)

# deltafs-umbrella

Download, build, and install deltafs, deltafs friends, and their dependencies in a single highly-automated step.

## Installation

This guide assumes a Linux Cray.

### Step-0: Prepare git-lfs

First, get a latest `git-lfs` release from github.com.

The latest release version may be higher than 2.0.0.
```
wget https://github.com/git-lfs/git-lfs/releases/download/v2.0.0/git-lfs-linux-amd64-2.0.0.tar.gz
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
module load craype-haswell  # Or module load craype-sandybridge if you want to run code on monitor nodes
```
Also make sure the desired compiler bundle (`PrgEnv-*` such as Intel, GNU, or Cray) has been configured, such as
```
module load PrgEnv-intel  # Or module load PrgEnv-gnu
```
Now, load a few addition modules needed by deltafs umbrella.
```
module load boost  # needed by mercury rpc
module load cmake  # at least v3.x
```

### Step-2: Build deltafs suite

Assuming `$INSTALL` is a global file system location that is accessible from all compute, monitor, and head nodes, our plan is to build deltafs under `$HOME/deltafs/src`, and to install everything under `$INSTALL/deltafs`.

**After installation, the build dir `$HOME/deltafs/src` is no longer needed and can be safely discarded. `$INSTALL/deltafs` is going to be the only thing we need for running deltafs experiments.**

**Do not move install directory after installation is done. If you do not like your current install location, remove the install directiry and reinstall deltafs to a new place.**
```
#
# $INSTALL/deltafs
#  -- bin
#  -- decks (vpic input decks)
#  -- include
#  -- lib
#  -- scripts
#  -- share
#
# $HOME/deltafs
#  -- src
#      -- deltafs-umbrella
#          -- cache.0
#          -- cache
#          -- build
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
Now, kick-off the cmake auto-building process:
```
mkdir build
cd build

# Skip unit tests, and tell cmake that we are doing cross-compiling
CC=cc CXX=CC cmake -DSKIP_TESTS=ON -DCMAKE_INSTALL_PREFIX=$INSTALL/deltafs \
      -DCMAKE_SYSTEM_NAME=CrayLinuxEnvironment \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo ..

make
```
**After installation, the build dir `$HOME/deltafs/src` is no longer needed and can be safely discarded. `$INSTALL/deltafs` is going to be the only thing we need for running deltafs experiments.**

**Do not move install directory after installation is done. If you do not like your current install location, remove the install directiry and reinstall deltafs to a new place.**

## Shuffle test

The following scripts are involved in our shuffle test. Note that you can find all our scripts in the install directory. Do not use the scripts in the build directory.
```
# $INSTALL/deltafs
#  -- bin
#  -- decks (vpic input decks)
#  -- include
#  -- lib
#  -- scripts
#      -- common.sh
#      -- run_shuffle_test.sh
#
```
First, open `run_shuffle_test.sh`, at Line 20-30ish, set `cores_per_node` to 32 perhaps, `nodes` to 4 for the 1st test run, and as many as 128 for later runs. Update `ip_subnet` to the subnet used by your compute nodes, such as something like "10.4", "172.16.3".
```
# Node topology
cores_per_node=4
nodes=16

# DeltaFS config
ip_subnet="10.92"
```
Next let's check if the following system envrionments used by our scripts are in control.
```
# environment variables we set/use:
#  $JOBDIRHOME - where to put job dirs (default: $HOME/jobs)
#                example: /lustre/ttscratch1/users/$USER
#
# environment variables we use as input:
#  $HOME - your home directory
#  $MOAB_JOBNAME - jobname (cray)
#  $PBS_JOBID - job id (cray)
#  $PBS_NODEFILE - file with list of all nodes (cray)
#
```
`JOBDIRHOME` is expected to be set by you. The rest are expected to be set by the system.

If you set `JOBDIRHOME` to `/lustre/ttscratch1/users/$USER`, our script will auto expand it to `/lustre/ttscratch1/users/${USER}/${MOAB_JOBNAME}.${PBS_JOBID}` ^_^

One last thing, go to `common.sh` Line 210ish, add `-cc numa_node` as an additional option to `aprun`. We think this will ask aprun to bind each process to a speicifc CPU socket.

OK.

Time to submit the job to the batch system.

After the job is done, in `${JOBDIRHOME}/${MOAB_JOBNAME}.${PBS_JOBID}`, there will be a set of result directories like:
```
shuffle_test_P240K_C8_N8
shuffle_test_P960K_C32_N8
```
Pxxx is the number of particles, Cxxx is the number of cores, and Nxxx is the number of compute nodes used.

Inside each result directory, you will see something like:
```
# shuffle_test_P240K_C8_N8
#  -- data  fields  global.vpc  hydro  info  info.bin  metadata
#  -- restart0  restart1  restart2  rundata
#  -- plfs
#      -- vpic-deltafs-mon-reduced-20170302-16:34:26.bin
#      -- vpic-deltafs-mon-reduced-20170302-16:34:26.txt
#      -- vpic-deltafs-mon-reduced.bin
#      -- vpic-deltafs-mon-reduced.txt
#  -- shuffle_test_P960K_C32_N8.log
#
```
Two files are important: *shuffle_test_P960K_C32_N8.log* and *vpic-deltafs-mon-reduced.txt*.

We hope you can send these two files back to us ^_^

This concludes the shuffle test.

Thanks for trying deltafs :-)
