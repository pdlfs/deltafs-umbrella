**This guide is written for our LANL collaborators that are kind enough to experiment with deltafs on their Cray systems.**

Deltafs-umbrella
================
Download, build, and install deltafs, deltafs friends, and their dependencies in a single highly-automated step.

[![Build Status](https://travis-ci.org/pdlfs/deltafs-umbrella.svg?branch=master)](https://travis-ci.org/pdlfs/deltafs-umbrella)
[![License](https://img.shields.io/badge/license-New%20BSD-blue.svg)](LICENSE)

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
If you are attempting to compile OFI (libfabrics) on the Cray, you
cannot use the Intel compiler (PrgEnv-intel) because it lacks support
for atomics that ofi requires.  To resolve this, use the GNU compiler
(you may need to "module swap PrgEnv-intel PrgEnv-gnu").

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
+ $INSTALL/deltafs
|  |- bin
|  |- decks (vpic input decks)
|  |- include
|  |- lib
|  |- scripts
|  -- share
|
+ $HOME/deltafs
|  -- src
|      +- deltafs-umbrella
|          |- cache.0
|          |- cache
|          -- build
=
```
First, let's get a recent deltafs-umbrella release from github:
```bash
mkdir -p $HOME/deltafs/src
cd $HOME/deltafs/src
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

Each vpic baseline run consists of a **write** phase that generates N-N particle timestep dumps and a **read** phase that performs queries on one or more particle trajectroies.

**NOTE**: all scripts are in the install dir. Do not use the script templates in the build dir.
```
+ $INSTALL/deltafs
|  |- bin
|  |- decks (vpic input decks)
|  |- include
|  |- lib
|  +- scripts
|  |   |- common.sh
|  |   |- lanl_do_vpic_test.sh
|  |   -- run_vpic_test.sh
|  |
|  -- share
=
```
**NOTE**: do not invoke `run_vpic_test.sh` directly. Use the `lanl_do_vpic_test.sh` wrapper script instead.

To do that, open `lanl_do_vpic_test.sh`:

**a**) set **test** to baseline;

**b**) set **subnet** to match your network configurations, such as "11.128";

**c**) set **nodes** and **ppn** to control the number of compute nodes and cores to request -- since this will be a vpic-only test, it is recommended to set ppn to the total number of cores available on a compute node (32 for Trinitite compute nodes);

**d**) set **num_vpic_dumps**,  **px_factor**, **py_factor**, and **pz_factor** to control the size of vpic simulations as well as the ratio between compute and I/O.

**NOTE**: to do an initial validation run to check code and debug scripts, set **nodes** to 1, **num_vpic_dumps** to 2, **px_factor**, **pz_factor** to 1, and **py_factor** to 4 (on a 32-core Trinitite node, this will result in a tiny run that lasts no more than 5 minites and generates data at 4MB/core/dump, and 256MB of data in total).

To do a standard vpic baseline test, set the above options as follows:

|         VPIC baseline | Run 1 | Run 2 | Run 3 | Run 4 | Note                                                 |
|----------------------:|:-----:|:-----:|:-----:|:-----:|:-----------------------------------------------------|
|             **nodes** |   1   |   4   |   16  |   64  |                                                      |
|                 cores |   32  |  128  |  512  |  2048 | 32 cpu cores per node (**ppn**=32)                   |
|    **num_vpic_dumps** |   8   |   8   |   8   |   8   |                                                      |
|         **px_factor** |   2   |   2   |   2   |   2   | *px=100*                                             |
|         **py_factor** |   20  |   20  |   20  |   20  | *py=640, 2560, 10K, 40K*                             |
|         **pz_factor** |   2   |   2   |   2   |   2   | *pz=100*                                             |
|         num_particles |  640M | 2560M |  10G  |  40G  | 20M particles per core                               |
| estimated_output_size | 320GB |1280GB |  5TB  |  20TB | roughly 1.28GB per core (64B per particle) per dump  |
|       estimated_files | 1.25K |   5K  |  20K  |  80K  | 4 PFS or BB files per core per dump                  |

Next, set env `JOBDIRHOME` to a desired root for all job outputs, and env `EXTRA_MPIOPTS` to a list of extra `aprun` options.
```bash
export JOBDIRHOME="/lustre/ttscratch1/users/$USER"
export EXTRA_MPIOPTS="-cc cpu"
```

**NOTE**: if `JOBDIRHOME` has been set to `/lustre/ttscratch1/users/$USER`, our script will auto expand it to `/lustre/ttscratch1/users/${USER}/${MOAB_JOBNAME}.${PBS_JOBID}`.

**Lastly**, check if all `#MSUB` and `#DW` directives have been properly set.

!!! Time to submit the job to the batch system !!!

After the job completes, the main script will show the testing results, which may look like:
```
-INFO- jobdir = /users/qingzhen/jobs/run_vpic_baseline.sh.21444
!!! WARNING !!! missing DW_JOB_STRIPED - putting data in jobdir for this test
-INFO- generating host lists...
-INFO- num vpic nodes = 1
-INFO- num bbos nodes = 0
--------------- [INPUT-DECK] --------------
!!! NOTICE !!! building vpic deck with cores = 4, px = 16, py = 100

/usr/bin/mpicxx -DVPIC_INSTALLED -DPACKAGE_NAME="VPIC" -DPACKAGE_TARNAME="vpic" -DPACKAGE_VERSION="3.1.2.1" -DPACKAGE_STRING="VPIC\ 3.1.2.1" -DPACKAGE_BUGREPORT="bergen@lanl.gov" -DPACKAGE_URL="" -DPACKAGE="vpic" -DVERSION="3.1.2.1" -DSTDC_HEADERS=1 -DHAVE_SYS_TYPES_H=1 -DHAVE_SYS_STAT_H=1 -DHAVE_STDLIB_H=1 -DHAVE_STRING_H=1 -DHAVE_MEMORY_H=1 -DHAVE_STRINGS_H=1 -DHAVE_INTTYPES_H=1 -DHAVE_STDINT_H=1 -DHAVE_UNISTD_H=1 -DHAVE_DLFCN_H=1 -DLT_OBJDIR=".libs/" -DENABLE_HOST=1 -DBUILDSTYLE=standard -DADDRESSING_64=1 -DOMPI_SKIP_MPICXX=1  -std=c++98 -D_XOPEN_SOURCE=600 -Wno-long-long -g -O2 -ffast-math -fno-unsafe-math-optimizations -fno-strict-aliasing -fomit-frame-pointer -march=opteron -mfpmath=sse -DUSE_V4_SSE   -I/users/qingzhen/vpic-install/include -I/users/qingzhen/vpic-install/include/vpic /users/qingzhen/vpic-install/decks/main.cxx /users/qingzhen/vpic-install/decks/deck_wrapper.cxx -DINPUT_DECK=/users/qingzhen/jobs/run_vpic_baseline.sh.21444/tmpdeck.21444/trecon-part/./turbulence.cxx -o /users/qingzhen/jobs/run_vpic_baseline.sh.21444/tmpdeck.21444/trecon-part/./turbulence.op /users/qingzhen/vpic-install/lib/libvpic.a    -lpthread -lm
[DECK] --- 19884215 -rwxr-xr-x 1 2616946 7004 1944312 2017-03-16 13:18:28.433460000 -0600 /users/qingzhen/jobs/run_vpic_baseline.sh.21444/current-deck.op

-INFO- vpic deck installed at /users/qingzhen/jobs/run_vpic_baseline.sh.21444/current-deck.op
--------------- [    OK    ] --------------


--------------- [   DOIT   ] --------------
!!! NOTICE !!! starting exp >> >> baseline_P160K_C4_N1...

-INFO- creating exp dir...
[MPIEXEC] mpirun.mpich -np 1 -ppn 1    mkdir -p /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1
-INFO- done
-INFO- clearing node caches...
mpirunall n=4: sudo sh -c echo 3 > /proc/sys/vm/drop_caches
-INFO- done

[DECK] --- 19884215 -rwxr-xr-x 1 2616946 7004 1944312 2017-03-16 13:18:28.433460000 -0600 /users/qingzhen/jobs/run_vpic_baseline.sh.21444/current-deck.op
==================================================================
!!! Running VPIC (baseline) with 160K particles on 4 cores !!!
------------
> Using /users/qingzhen/jobs/run_vpic_baseline.sh.21444/current-deck.op
> Job dir is /users/qingzhen/jobs/run_vpic_baseline.sh.21444
> Experiment dir is /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1
> Log to /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1/baseline_P160K_C4_N1.log
  + Log to /users/qingzhen/jobs/run_vpic_baseline.sh.21444/run_vpic_baseline.sh.21444.log
    + Log to STDOUT
==================================================================

[MPIEXEC] mpirun.mpich -np 4  --host h0.fs.tablefs.narwhal.pdl.cmu.edu -env VPIC_current_working_dir /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1   /users/qingzhen/jobs/run_vpic_baseline.sh.21444/current-deck.op
/users/qingzhen/jobs/run_vpic_baseline.sh.21444/tmpdeck.21444/trecon-part/./turbulence.cxx(325)[0]: Topology: X=4 Y=1 Z=1
/users/qingzhen/jobs/run_vpic_baseline.sh.21444/tmpdeck.21444/trecon-part/./turbulence.cxx(333)[0]: num_step = 1000 nppc = 50
/users/qingzhen/jobs/run_vpic_baseline.sh.21444/tmpdeck.21444/trecon-part/./turbulence.cxx(342)[0]: Particles: nx = 16 ny = 100 nz = 1
/users/qingzhen/jobs/run_vpic_baseline.sh.21444/tmpdeck.21444/trecon-part/./turbulence.cxx(351)[0]: total # of particles = 160000
/users/qingzhen/vpic-install/decks/main.cxx(93): **** Beginning simulation advance with 1 tpp ****
Free Mem: 99.50%
/users/qingzhen/jobs/run_vpic_baseline.sh.21444/tmpdeck.21444/trecon-part/./turbulence.cxx(1185)[0]: Dumping trajectory data: step T.500
/users/qingzhen/jobs/run_vpic_baseline.sh.21444/tmpdeck.21444/trecon-part/./turbulence.cxx(1201)[0]: Dumping duration 0.104736
Free Mem: 99.48%
/users/qingzhen/jobs/run_vpic_baseline.sh.21444/tmpdeck.21444/trecon-part/./turbulence.cxx(1185)[0]: Dumping trajectory data: step T.1000
/users/qingzhen/jobs/run_vpic_baseline.sh.21444/tmpdeck.21444/trecon-part/./turbulence.cxx(1201)[0]: Dumping duration 0.12373
/users/qingzhen/vpic-install/decks/main.cxx(101): simulation time: 16.085537

/users/qingzhen/vpic-install/decks/main.cxx(110): Maximum number of time steps reached.  Job has completed.

-INFO- checking output size...
[MPIEXEC] mpirun.mpich -np 1 -ppn 1    du -sb /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1
26944448        /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1
[MPIEXEC] mpirun.mpich -np 1 -ppn 1    du -h /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1/particle
9.9M    /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1/particle/T.500
9.9M    /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1/particle/T.1000
20M     /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1/particle

==================================================================
!!! Query VPIC (baseline) using 2 cores !!!
------------
> Using /users/qingzhen/vpic-install/bin/vpic-reader
> Experiment dir is /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1
> Log to /users/qingzhen/jobs/run_vpic_baseline.sh.21444/run_vpic_baseline.sh.21444.log
  + Log to /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1/baseline_P160K_C4_N1.log
    + Log to STDOUT
==================================================================

[MPIEXEC] mpirun.mpich -np 2  --host h0.fs.tablefs.narwhal.pdl.cmu.edu   /users/qingzhen/vpic-install/bin/vpic-reader -i /users/qingzhen/jobs/run_vpic_baseline.sh.21444/baseline_P160K_C4_N1 -n 1

Number of particles: 160000

Querying 1 particles (3 retries)
Overall: 21ms / query, 20 ms / particle
Overall: 18ms / query, 17 ms / particle
Overall: 17ms / query, 16 ms / particle
Querying results: 17 ms / query, 17 ms / particle


--------------- [    OK    ] --------------
Script complete.
start: Thu Mar 16 13:18:33 MDT 2017
  end: Thu Mar 16 13:18:56 MDT 2017

```
Those final results from the experiment can also be found at `$JOBDIRHOME/${MOAB_JOBNAME}.${PBS_JOBID}/baseline_P{XX}_C{YY}_N{ZZ}/baseline_P{XX}_C{YY}_N{ZZ}.log`. Here `XX` will be the number of particles simulated, `YY` the number of cores, and `ZZ` the number of compute nodes used.

In addition, the entire job log can be found at `$JOBDIRHOME/${MOAB_JOBNAME}.${PBS_JOBID}/${MOAB_JOBNAME}.${PBS_JOBID}.log`.

**NOTE**: Each individual vpic baseline run will potentially generate a large amount of data. These data **can be safely removed** after each run. The only thing we need is the log file generated by the script set. To locate all job log files, use `find $JOBDIRHOME -maxdepth 3 -iname '*.log'`.

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
