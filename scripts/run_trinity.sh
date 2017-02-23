#!/bin/bash -eu
#
#MSUB -N deltafs-exp
#MSUB -l walltime=1:00:00
#MSUB -l nodes=5:haswell
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
# nodes: Use an odd number of nodes. The number of particles is a multiple of
# the number of cores, but 1 node is reserved for DeltaFS server, so you want
# to be left with power-of-2 cores to get better particle numbers.
#
# bbos_buddies: An additional number of node dedicated for burst buffer
# communication. Should be set to the same number of nodes as the burst buffer
# nodes.

# Node topology
cores_per_node=4
nodes=3
bbos_buddies=2

# Paths
umbrella_build_dir="$HOME/src/deltafs-umbrella/build"
output_dir="$HOME/src/vpic/decks/dump"

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
max_cores=$(((nodes-1) * cores_per_node))
build_op_dir="$umbrella_build_dir/vpic-prefix/src/vpic-build"
deck_dir="$umbrella_build_dir/vpic-prefix/src/vpic/decks/trecon-part"
logfile=""

bb_sst_size=$((2 * (2**20)))    # BBOS SST table size in bytes
bb_log_size=$((1024 * (2**20))) # BBOS max per-core log size in bytes

bb_clients=$cores
bb_client_cfg="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb/config/narwhal_8_client.conf"
bb_client="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb-build/src/bbos_client"

bb_servers=$bbos_buddies
bb_server_cfg="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb/config/narwhal_2_server.conf"
bb_server="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb-build/src/bbos_server"

message () { echo "$@" | tee -a $logfile; }
die () { message "Error $@"; exit 1; }

source ./run_common.sh

rm $logfile
gen_hosts

cores=$min_cores
while [ $cores -le $max_cores ]
do
    parts=$((cores * 32))

    build_deck "file-per-process" $parts
    do_run "baseline" $parts

    build_deck "file-per-particle" $parts
    do_run "deltafs" $parts

    cores=$(( cores * 2 ))
done
