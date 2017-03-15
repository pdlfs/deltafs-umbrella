**This guide is written for our LANL collaborators that are kind enough to experiment with deltafs on their Cray systems.**

Deltafs-umbrella
================
Download, build, and install deltafs, deltafs friends, and their dependencies in a single highly-automated step.

[![Build Status](https://travis-ci.org/pdlfs/deltafs-umbrella.svg?branch=master)](https://travis-ci.org/pdlfs/deltafs-umbrella)

TABLE OF CONTENTS
=================
  * [Deltafs-umbrella](#deltafs-umbrella)
  * [Table of contents](#table-of-contents)
  * [Installation](#installation)
  * **Micro-banchmarks**
    * [Mercury-runner](#mercury-runner)
    * [IOR](#ior-test)
  * **Macro-tests**
    * [Vpic-baseline](#vpic-baseline-test)
    * [Vpic-deltafs](#vpic-deltafs-test)

INSTALLATION
============
This guide is assuming a Linux Cray.

## STEP-0: prepare git-lfs

First, we need to get a latest `git-lfs` release from github.com.

**NOTE**: the latest release version may be higher than 2.0.0.
```bash
wget https://github.com/git-lfs/git-lfs/releases/download/v2.0.0/git-lfs-linux-amd64-2.0.0.tar.gz
tar xzf git-lfs-linux-amd64-2.0.0.tar.gz -C .
```
The entire `git-lfs` release consists of a single executable file so we can easily install it by moving it to a directory that belongs to the `PATH`, such as
```bash
mv git-lfs-2.0.0/git-lfs $HOME/bin/
which git-lfs
```
After that, initalize `git-lfs` once by
```bash
module load git  # load the original git
git lfs install
```

## STEP-1: prepare cray programming env

First, let's set cray link type to dynamic (required to compile deltafs)
```bash
export CRAYPE_LINK_TYPE="dynamic"
```
If `CRAYOS_VERSION` is not in the env, we have to explicitly set it.
On Nersc Edison, `CRAYOS_VERSION` is pre-set by the Cray system. On Nersc Cori, which has a newer version of Cray, it is not set.
```bash
export CRAYOS_VERSION=6
```
Make sure the desired processor-targeting module (such as `craype-sandybridge`, or `craype-haswell`, or `craype-mic-knl`, etc.) has been loaded. These targeting modules will configure the compiler driver scripts (`cc`, `CC`, `ftn`) to compile code optimized for the processors on the compute nodes.
```bash
module load craype-haswell  # Or module load craype-sandybridge if you want to run code on monitor nodes
```
Also make sure the desired compiler bundle (`PrgEnv-*` such as Intel, GNU, or Cray) has been configured, such as
```bash
module load PrgEnv-intel  # Or module load PrgEnv-gnu
```
Now, load a few addition modules needed by deltafs umbrella.
```bash
module load boost  # needed by mercury rpc
module load cmake  # at least v3.x
```

## STEP-2: build deltafs suite

Assuming `$INSTALL` is a global file system location that is accessible from all compute, monitor, and head nodes, our plan is to build deltafs under `$HOME/deltafs/src`, and to install everything under `$INSTALL/deltafs`.

**NOTE**: after installation, the build dir `$HOME/deltafs/src` is no longer needed and can be safely discarded. `$INSTALL/deltafs` is going to be the only thing we need for running deltafs experiments.

**NOTE**: do not rename the install dir after installation is done. If the current install location is bad, simply remove the install dir and reinstall deltafs to a new place.
```
+$INSTALL/deltafs
| |- bin
| |- decks (vpic input decks)
| |- include
| |- lib
| |- scripts
| -- share
|
+$HOME/deltafs
| -- src
|     +- deltafs-umbrella
|         |- cache.0
|         |- cache
|         -- build
=
mkdir -p $HOME/deltafs/src
cd $HOME/deltafs/src
```
First, let's get a recent deltafs-umbrella release from github:
```bash
git lfs clone https://github.com/pdlfs/deltafs-umbrella.git
cd deltafs-umbrella
```
Second, prepolute the cache directory:
```bash
cd cache
ln -fs ../cache.0/* .
cd ..
```
Now, kick-off the cmake auto-building process:

**NOTE**: set `-DVERBS=ON` if **cci-ibverbs** is to be enabled.
```bash
mkdir build
cd build
#
# a. tell cmake that we are doing cross-compiling
# b. skip unit tests, and
# c. set -DVERBS=ON if we are to use cci+ibverbs
CC=cc CXX=CC cmake -DSKIP_TESTS=ON -DVERBS=OFF -DCMAKE_INSTALL_PREFIX=$INSTALL/deltafs \
      -DCMAKE_SYSTEM_NAME=CrayLinuxEnvironment \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo ..

make
```
**NOTE**: after installation, the build dir `$HOME/deltafs/src` is no longer needed and can be safely discarded. `$INSTALL/deltafs` is going to be the only thing we need for running deltafs experiments.

**NOTE**: do not rename the install dir after installation is done. If the current install location is bad, simply remove the install dir and reinstall deltafs to a new place.

MERCURY RUNNER
===============

**mercury runner** is a microbenchmark we coded to verify mercury suite functionality, as well as its compatibility with different native network transports including sm, bmi, cci (with ib, gni, ...), and mpi. Running mercury runner can also give us the baseline rpc performance on top of a specific HPC system.

The following scripts are involved in our mercury runner test.

**NOTE**: all scripts are in the install dir. Do not use the script templates in the build dir.
```
+ $INSTALL/deltafs
|  |- bin
|  |- decks (vpic input decks)
|  |- include
|  |- lib
|  +- scripts
|  |   |- common.sh
|  |   |- lanl_do_mercury_runner.sh
|  |   -- run_mercury_runner.sh
|  |
|  -- share
=
```
**NOTE**: do not invoke `run_mercury_runner.sh` directly. Use the `lanl_do_mercury_runner.sh` wrapper script instead.

To do that, open `lanl_do_mercury_runner.sh`, check the **subnet** option and modify it to match your network settings.

Next, set env `JOBDIRHOME` to the root of all job outputs, and env `EXTRA_MPIOPTS` to a list of extra `aprun` options.
```bash
export JOBDIRHOME="/lustre/ttscratch1/users/$USER"
export EXTRA_MPIOPTS="-cc cpu"
```

**NOTE**: if `JOBDIRHOME` has been set to `/lustre/ttscratch1/users/$USER`, our script will auto expand it to `/lustre/ttscratch1/users/${USER}/${MOAB_JOBNAME}.${PBS_JOBID}`.

Time to submit the job to the batch system !!

Our job requires **2 compute nodes** to run, consists of a series of small mercury-testing tasks, and the entire job is expected to run for **2 hours**.

After the job completes, the main script will parse the outputs generated by individual tests and print testing results to stdout, which usually looks like:
```
----------

/users/qingzhen/jobs/run_mercury_runner.sh.7890/norm-bmi+tcp-1-64.result
bmi   1 0.000107 sec per op, cli/srv sys time 4.276000 / 2.210000 sec, r=2
bmi   8 0.000042 sec per op, cli/srv sys time 4.676000 / 1.626000 sec, r=2
bmi  16 0.000043 sec per op, cli/srv sys time 4.666000 / 1.604000 sec, r=2

----------

/users/qingzhen/jobs/run_mercury_runner.sh.7890/norm-cci+tcp-1-64.result
cci   1 0.000117 sec per op, cli/srv sys time 17.988000 / 16.812000 sec, r=2
cci   8 0.000062 sec per op, cli/srv sys time 14.998000 / 13.218000 sec, r=2
cci  16 0.000063 sec per op, cli/srv sys time 15.134000 / 13.526000 sec, r=2

```

Those final results may also be found at `$JOBDIRHOME/${MOAB_JOBNAME}.${PBS_JOBID}/mercury-runner.log`.

IOR TEST
========

// *TODO*

VPIC BASELINE TEST
==================

The following scripts are involved to run vpic baseline tests.

Each vpic baseline run consists of a `write` phase that generates N-N particle timestep dumps and a `read` phase that performs queries on one or more particle trajectroies.

**NOTE**: all scripts are in the install dir. Do not use the script templates in the build dir.
```
+ $INSTALL/deltafs
|  |- bin
|  |- decks (vpic input decks)
|  |- include
|  |- lib
|  +- scripts
|  |   |- common.sh
|  |   |- lanl_do_vpic_baseline.sh
|  |   -- run_vpic_baseline.sh
|  |
|  -- share
=
```
**NOTE**: do not invoke `run_vpic_baseline.sh` directly. Use the `lanl_do_vpic_baseline.sh` wrapper script instead.

To do that, open `lanl_do_vpic_baseline.sh`:

**a**) check the **subnet** option and modify it to match your network configurations;

**b**) set the **nodes** and **cores_per_node** options to control the number of compute nodes and cores to request -- since this will be a vpic-only test, it is safe and recommended to set the cores_per_node to just the total number of cores available on a compute node (32 for Trinitite);

**c**) finally, set the **num_vpic_dumps**,  **px_factor**, and **py_factor** options to control the size of job outputs as well as the runtime of a job.

**NOTE**: to do an initial validation run to check code and debug scripts, set **nodes** to 1, **num_vpic_dumps** to 2,  **px_factor** to 4, and **py_factor** to 2 (on a 32-core Trinitite node, this will result in a tiny run that lasts no more than 5 minites and generates data at 4MB/core/dump, and 256MB of data in total).

To do a standard vpic baseline test, set the above options as follows:

|         VPIC baseline | Run 1 | Run 2 | Run 3 | Run 4 | Note                                 |
|----------------------:|:-----:|:-----:|:-----:|:-----:|:-------------------------------------|
|                 nodes |   1   |   4   |   16  |   64  |                                      |
|                 cores |   32  |  128  |  512  |  2048 | 32 cores per node                    |
|        num_vpic_dumps |   8   |   8   |   8   |   8   |                                      |
|             px_factor |   16  |   16  |   16  |   16  |                                      |
|             py_factor |   4   |   4   |   4   |   4   |                                      |
|         num_particles |  512M |   2G  |   8G  |  32G  | 16M per core                         |
| estimated_output_size |<256GB | <1TB  | <4TB  | <16TB | less than 1GB per core per dump      |
|       estimated_files |   1K  |   4K  |  16K  |  64K  | 4 PFS or BB files per core per dump  |
|     estimated_runtime |  2hr  |  2hr  |  2hr  | 2.5hr | query time not included              |
|    estimated_hpc_util |  95%  |  95%  |  95%  |  90%  |                                      |
|  estimated_query_time |  1min |  5min | 20min | 80min | 8 reader cores w/ each at 512MB/s    |

Next, set env `JOBDIRHOME` to a desired root for all job outputs, and env `EXTRA_MPIOPTS` to a list of extra `aprun` options.
```bash
export JOBDIRHOME="/lustre/ttscratch1/users/$USER"
export EXTRA_MPIOPTS="-cc cpu"
```

**NOTE**: if `JOBDIRHOME` has been set to `/lustre/ttscratch1/users/$USER`, our script will auto expand it to `/lustre/ttscratch1/users/${USER}/${MOAB_JOBNAME}.${PBS_JOBID}`.

Time to submit the job to the batch system !!

After the job completes, the main script will show the testing results, which may look like:
```
==================================================================
Running VPIC (baseline) with 320K particles on 4 cores.
Experiment dir is /users/qingzhen/jobs/run_vpic_baseline.sh.15665/baseline_P320K_C4_N1
==================================================================

mpirun.mpich -np 4  --host h0.fs.tablefs.narwhal.pdl.cmu.edu   /users/qingzhen/jobs/run_vpic_baseline.sh.15665/current-deck.op
/users/qingzhen/jobs/run_vpic_baseline.sh.15665/tmpdeck.15665/trecon-part/./turbulence.cxx(325)[0]: Topology: X=4 Y=1 Z=1
/users/qingzhen/jobs/run_vpic_baseline.sh.15665/tmpdeck.15665/trecon-part/./turbulence.cxx(333)[0]: num_step = 1000 nppc = 50
/users/qingzhen/jobs/run_vpic_baseline.sh.15665/tmpdeck.15665/trecon-part/./turbulence.cxx(342)[0]: Particles: nx = 32 ny = 100 nz = 1
/users/qingzhen/jobs/run_vpic_baseline.sh.15665/tmpdeck.15665/trecon-part/./turbulence.cxx(351)[0]: total # of particles = 320000
/users/qingzhen/vpic-install/decks/main.cxx(86): **** Beginning simulation advance with 1 tpp ****
Free Mem: 99.31%
/users/qingzhen/jobs/run_vpic_baseline.sh.15665/tmpdeck.15665/trecon-part/./turbulence.cxx(1185)[0]: Dumping trajectory data: step T.500
/users/qingzhen/jobs/run_vpic_baseline.sh.15665/tmpdeck.15665/trecon-part/./turbulence.cxx(1201)[0]: Dumping duration 0.161916
Free Mem: 99.22%
/users/qingzhen/jobs/run_vpic_baseline.sh.15665/tmpdeck.15665/trecon-part/./turbulence.cxx(1185)[0]: Dumping trajectory data: step T.1000
/users/qingzhen/jobs/run_vpic_baseline.sh.15665/tmpdeck.15665/trecon-part/./turbulence.cxx(1201)[0]: Dumping duration 0.149855
/users/qingzhen/vpic-install/decks/main.cxx(94): simulation time: 28.719526

/users/qingzhen/vpic-install/decks/main.cxx(103): Maximum number of time steps reached.  Job has completed.
mpirun.mpich -np 2  --host h0.fs.tablefs.narwhal.pdl.cmu.edu   /users/qingzhen/vpic-install/bin/vpic-reader -i /users/qingzhen/jobs/run_vpic_baseline.sh.15665/baseline_P320K_C4_N1 -n 1

Number of particles: 320000

Querying 1 particles (3 retries)
Overall: 35ms / query, 35 ms / particle
Overall: 37ms / query, 34 ms / particle
Overall: 36ms / query, 33 ms / particle
Querying results: 34 ms / query, 34 ms / particle

Script complete.
start: Tue Mar 14 14:15:25 MDT 2017
  end: Tue Mar 14 14:16:02 MDT 2017

```

Those final results may also be found at `$JOBDIRHOME/${MOAB_JOBNAME}.${PBS_JOBID}/baseline_P{XX}_C{YY}_N{ZZ}/baseline_P{XX}_C{YY}_N{ZZ}.log`. Here `XX` will be the number of particles simulated, `YY` the number of cores, and `ZZ` the number of compute nodes used.

**NOTE**: Each individual vpic baseline run will potentially generate a large amount of data. These data **can be safely removed** after each run. The only thing we need is the log file generated by out script. To locate all job log files, use `find $JOBDIRHOME -maxdepth 3 -iname 'baseline_*.log'`.

VPIC DELTAFS TEST
=================
// *TODO*

SHUFFLE TEST [under construction]
=================================

**shuffle test** is designed to touch only the rpc and inter-process communication functionality within the deltafs micro-service stack so all file-system related activities have been removed and converted to no-op. The main goal of running a shuffle test is to evaluate and quantify the overhead incurred by deltafs to move particles around.

The following scripts are involved in our shuffle test.

**NOTE**: all scripts are in the install dir. Do not use the script templates in the build dir.
```
# $INSTALL/deltafs
#  -- bin
#  -- decks (vpic input decks)
#  -- include
#  -- lib
#  -- scripts
#      -- common.sh
#      -- lanl_do_shuffle_test.sh
#      -- run_shuffle_test.sh
#  -- share
```
**NOTE**: do not call `run_shuffle_test.sh` directly. Instead, call the `lanl_do_shuffle_test.sh` wrapper script.

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

END
===
Thanks for trying deltafs :-)
