#!/bin/bash -eu
#
#MSUB -N deltafs-shuffle
#MSUB -l walltime=1:00:00
#MSUB -l nodes=4:haswell
#MSUB -o /users/$USER/joblogs/deltafs-shuffle-$MOAB_JOBID.out
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

# Node topology
cores_per_node=4
nodes=16

# Paths
umbrella_build_dir="$HOME/src/deltafs-umbrella/build"
job_dir="$HOME/src/vpic/decks/dump"

# DeltaFS config
ip_subnet="10.92"


###############
# Core script #
###############

bbos_buddies=0
build_op_dir="$umbrella_build_dir/vpic-prefix/src/vpic-build"
deck_dir="$umbrella_build_dir/vpic-prefix/src/vpic/decks/trecon-part"
logfile=""

source ./common.sh

mkdir -p $job_dir || die "failed to create $job_dir"
gen_hosts

procs_per_node=1
while [ $procs_per_node -le $cores_per_node ]
do
    cores=$((procs_per_node * nodes))
    px=$((cores * 3)) #10
    py=$((10**2)) #100
    parts=$((px * py * 100))

    build_deck "file-per-particle" $px $py
    do_run "shuffle_test" $parts $procs_per_node

    if [ $procs_per_node -eq 1 ]; then
        procs_per_node=4
    else
        procs_per_node=$(( procs_per_node + 4 ))
    fi
done
