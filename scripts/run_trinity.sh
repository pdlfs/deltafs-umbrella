#!/bin/bash -eu
#
#MSUB -N deltafs-exp
#MSUB -l walltime=1:00:00
#MSUB -l nodes=4:haswell
#MSUB -o /users/$USER/joblogs/deltafs-exp-$MOAB_JOBID.out
#MSUB -j oe
##MSUB -V
##MSUB -m b
##MSUB -m $USER@lanl.gov

######################
# Tunable parameters #
######################

# Notes:
# ------
#
# nodes: Use a power of two to get better particle numbers.
#
# bbos_buddies: An additional number of nodes dedicated for burst buffer
# communication. Should be set to the same number of nodes as the burst buffer
# nodes.

# Node topology
cores_per_node=4
nodes=4
bbos_buddies=1

# Paths
umbrella_build_dir="$HOME/src/deltafs-umbrella/build"
job_dir="$HOME/src/vpic/decks/dump"

# DeltaFS config
ip_subnet="10.92"


###############
# Core script #
###############

# Notes:
# ------
#
# min_cores and max_cores: we scale the number of cores used by VPIC by starting
# at min_cores and increasing the number exponentially until we reach max_cores,
# which is defined (by default) to be the number of cores in the nodes allocated
# for VPIC through the $nodes variable above.

min_cores=1
max_cores=$((nodes * cores_per_node))
max_cores=1
build_op_dir="$umbrella_build_dir/vpic-prefix/src/vpic-build"
deck_dir="$umbrella_build_dir/vpic-prefix/src/vpic/decks/trecon-part"
logfile=""

bb_sst_size=$((2 * (2**20)))    # BBOS SST table size in bytes
bb_log_size=$((1024 * (2**20))) # BBOS max per-core log size in bytes

bb_client_cfg="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb/config/narwhal_8_client.conf"
bb_client="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb-build/src/bbos_client"

bb_servers=$bbos_buddies
bb_server_cfg="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb/config/narwhal_2_server.conf"
bb_server="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb-build/src/bbos_server"

source ./common.sh

mkdir -p $job_dir || die "failed to create $job_dir"
gen_hosts

cores=$min_cores
while [ $cores -le $max_cores ]
do
    px=$((cores * 30))
    py=$((10**4))
    parts=$((px * py * 100))
    bb_clients=$cores

    build_deck "file-per-process" $px $py
    do_run "baseline" $parts

    build_deck "file-per-particle" $x $py
    do_run "deltafs" $parts

    cores=$(( cores * 2 ))
done