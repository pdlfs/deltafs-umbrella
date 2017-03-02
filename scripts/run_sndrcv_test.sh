#!/bin/bash -eu
#
#MSUB -N transport-test
#MSUB -l walltime=0:15:00
#MSUB -l nodes=2:haswell
#MSUB -o /users/$USER/joblogs/transport-test-$MOAB_JOBID.out
#MSUB -j oe
##MSUB -V
##MSUB -m b
##MSUB -m $USER@lanl.gov

######################
# Tunable parameters #
######################

umbrella_bin_dir="$HOME/src/deltafs-umbrella/install/bin"
job_dir="$HOME/src/vpic/decks/dump"

###############
# Core script #
###############

logfile=$job_dir/sndrcv-log.txt
server="$umbrella_bin_dir/sndrcv-srvr"
client="$umbrella_bin_dir/sndrcv-client"

source ./common.sh

mkdir -p $job_dir || die "failed to create $output_dir"
touch $logfile
message "Output is available in $job_dir"

gen_hostfile

host1=$(echo "$all_nodes" | sort | head -n 1)
host2=$(echo "$all_nodes" | sort | head -n 2 | tail -n 1)

do_mpirun 1 1 "" $host1 "hostname -i" "$job_dir/host1-ip.txt"
do_mpirun 1 1 "" $host2 "hostname -i" "$job_dir/host2-ip.txt"
host1_ip=$(cat $job_dir/host1-ip.txt | head -1)
host2_ip=$(cat $job_dir/host2-ip.txt | head -1)
message "Host 1: hostname = $host1, ip = $host1_ip"
message "Host 2: hostname = $host2, ip = $host2_ip"

protos=("bmi+tcp" "cci+tcp" "cci+gni")
instances=(1 2 4 8)
repeats=3

run_one() {
    proto="$1"
    num="$2"
    iter=$3

    message ""
    message "====================================================="
    message "Testing protocol '$proto' with $num Mercury instances"
    message "Iteration $iter out of $repeats"
    message "====================================================="
    message ""

    clogfile=$job_dir/client-$proto-$num-$iter-log.txt
    slogfile=$job_dir/server-$proto-$num-$iter-log.txt

    saddress="${proto}://${host1_ip}:%d"
    caddress="${proto}://${host2_ip}:%d"

    # Start the server
    message "Starting server (Instances: $num, Address spec: $saddress)."
    do_mpirun 1 1 "" $host1 "$server $num $saddress" "$slogfile" &

    server_pid=$!

    # Start the client
    message "Starting client (Instances: $num, Address spec: $caddress)."
    message "Please be patient while the test is in progress..."
    do_mpirun 1 1 "" $host2 "$client $num $caddress $saddress" "$clogfile"

    # Collect return codes
    client_ret=$?
    wait $server_pid
    server_ret=$?

    if [[ $client_ret != 0 || $server_ret != 0 ]]; then
        if [ $client_ret != 0 ]; then
            message "Error: client returned $client_ret."
        fi
        if [ $server_ret != 0 ]; then
            message "Error: server returned $server_ret."
        fi
    else
        message "Test completed successfully."
    fi
}

for proto in ${protos[@]}; do
    for num in ${instances[@]}; do
        # BMI doesn't do well with >1 instances, so avoid those tests
        if [[ $proto == "bmi+tcp" && $num -gt 1 ]]; then
            continue;
        fi

        i=1
        while [ $i -le $repeats ]; do
            run_one $proto $num $i
            i=$((i + 1))
        done
    done
done