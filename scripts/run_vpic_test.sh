#!/bin/bash -eu
#
#MSUB -N deltafs-test
#MSUB -l walltime=1:00:00
#MSUB -l nodes=4:haswell
#MSUB -o /users/$USER/joblogs/deltafs-test-$MOAB_JOBID.out
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

cores=$((nodes * cores_per_node))
build_op_dir="$umbrella_build_dir/vpic-prefix/src/vpic-build"
deck_dir="$umbrella_build_dir/vpic-prefix/src/vpic/decks/trecon-part"
dpoints=2
logfile=""

bb_sst_size=$((2 * (2**20)))    # BBOS SST table size in bytes
bb_log_size=$((1024 * (2**20))) # BBOS max per-core log size in bytes

bb_clients=$cores
bb_client_cfg="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb/config/narwhal_8_client.conf"
bb_client="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb-build/src/bbos_client"

bb_servers=$bbos_buddies
bb_server_cfg="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb/config/narwhal_2_server.conf"
bb_server="$umbrella_build_dir/deltafs-bb-prefix/src/deltafs-bb-build/src/bbos_server"

source ./common.sh

mkdir -p $job_dir || die "failed to create $job_dir"
gen_hosts

parts=$cores
while [ $dpoints -gt 0 ]
do
    build_deck "file-per-process" $parts $parts
    do_run "baseline" $(((parts**2)*100))

    build_deck "file-per-particle" $parts $parts
    do_run "deltafs" $(((parts**2)*100))

    dpoints=$(( dpoints - 1 ))
    parts=$(( parts * 2 ))
done
