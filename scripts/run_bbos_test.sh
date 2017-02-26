#!/bin/bash
#
#MSUB -N deltafs-bb-test
#MSUB -l walltime=0:10:00
#MSUB -l nodes=2:haswell
#MSUB -o /users/$USER/joblogs/deltafs-bbos-bench-$MOAB_JOBID.out
#MSUB -j oe
#DW jobdw access_mode=striped capacity=25GiB type=scratch
##DW stage_in type=directory source=/lustre/ttscratch1/users/$USER... destination=$DW_JOB_STRIPED
##DW stage_out type=directory source=$DW_JOB_STRIPED destination=/lustre/ttscratch1/users/$USER

#
# Tunables
#
num_bbos_client_nodes=2
num_bbos_server_nodes=1
deltafs_dir="$SWHOME/deltafs"
deltafs_bb_dir="/proj/TableFS/bbos/src/build/deltafs-bb-prefix/src/deltafs-bb-build/src"
job_dir="/lustre/ttscratch1/users/$USER/$MOAB_JOBNAME.$PBS_JOBID"
job_dir="/proj/TableFS/bbos/src/build/deltafs-bb-prefix/src/deltafs-bb"
bb_dir="$DW_JOB_STRIPED"
bb_dir="/panfs/probescratch/TableFS/bbos_test_1"
output_dir=$bb_dir
# SK: need scratch config dir for each run
scratch_config_dir=$job_dir/scratch_config
logfile="$job_dir/bb-test-log.txt"
logfile="$bb_dir/bb-test-log.txt"
ip_file="$job_dir/bb-ips.txt"
ip_file="$bb_dir/bb-ips.txt"

# Client transfer sizes we experiment with
OBJECT_CHUNK_SIZE=($((1*(2**20))))
#                   $((2*(2**20))))
#                   $((4*(2**20)))
#                   $((8*(2**20)))) # 1-8 MB

# Lustre sizes we experiment with
PFS_CHUNK_SIZE=($(( 8*(2**20))))
#                $((16*(2**20)))
#                $((32*(2**20)))
#                $((64*(2**20)))) # 8-64 MB

message () { echo "$@" | tee -a $logfile; }

source ./common.sh

test_raw_bw() {
  svrs=$1
  env_vars=$2
  blocksize=$3
  count=$4
  num_servers=$5
  exe=$deltafs_bb_dir/eval_bb

  message "RAW dd throughput: servers=$svrs bs=$blocksize count=$count"
  do_mpirun $num_servers 1 env_vars[@] "$svrs" "$exe" "$logfile"

  # Let the DDs finish on all the servers
  wait
}

start_server() {
  svr_name=$1
  env_vars=$2
  exe=$deltafs_bb_dir/bbos_server

  message "Starting Server: server=$svr_name"
  do_mpirun 1 1 env_vars[@] "$svr_name" "$exe" "$logfile" &
}

start_clients() {
  clients=$1
  env_vars=$2
  num_clients=$3
  exe=$deltafs_bb_dir/bbos_client

  message "Starting clients: clients=$clients"
  # SK: line below is a temporary fix to get each client to create an object
  # whose name is the same as the client. Eventually env variables will obviate
  # the need to do this.
  do_mpirun $num_clients 1 env_vars[@] "$clients" "$exe" "$logfile" &
}

kill_server() {
  svr_name=$1

  message "Killing server: server=$svr_name"
  do_mpirun 1 1 "" "$svr" "pkill -SIGINT bbos_server" "$logfile"
}

mkdir -p $job_dir

# Create the logfile
touch $logfile
echo "" > $logfile # remove any stale log entries

# Create a file that will contain all hosts' IP addresses
touch $ip_file
echo "" > $ip_file # remove any stale IP entries

gen_hostfile
PBS_NODEFILE="$bb_dir/hosts.txt"
# Find the IP addresses of all allocated nodes
#all_nodes=$(echo -e "$all_nodes" | uniq | sort | tr '\n' ',')
#do_mpirun 1 1 "" "$all_nodes" "hostname -i" "$ip_file"
#cp $output_dir/fake_ips.txt $ip_file
# Split nodes into clients and servers
bbos_client_nodes=$(cat $PBS_NODEFILE | uniq | sort | head -n $num_bbos_client_nodes | tr '\n' ',')
bbos_server_nodes=$(cat $PBS_NODEFILE | uniq | sort | tail -n $num_bbos_server_nodes | tr '\n' ',')

message "Clients: $bbos_client_nodes"
message "Servers: $bbos_server_nodes"

# Test the burst buffer
do_mpirun 1 1 "" "" "mkdir -p $bb_dir" "$logfile"
echo "Basic ls of Burst Buffer ..."
do_mpirun 1 1 "" "" "ls -l" "$logfile"

# First perform basic BB benchmarking loop across all servers
# BWS: This seems pointless, but whatever
# SK - Goal: estimate bandwidth to burst buffer
for c in ${PFS_CHUNK_SIZE[@]}; do
  count=$((512 * (2**20) / c))

  message "TRIAL BW Testing BB Chunk: $c"

  env_vars=("BB_Lustre_chunk_size" "$c"
            "BB_Max_container_size" "1073741824" "BB_Dummy_file"
            "$bb_dir/\$(hostname)")
  test_raw_bw $bbos_server_nodes "$env_vars" $c $count $num_bbos_server_nodes
  wait # have to wait
done

# Now perform client-server test
# SK: purposely kept separate client and server bases to avoid renaming all files

for pchunk in ${PFS_CHUNK_SIZE[@]}; do
  for hgchunk in ${OBJECT_CHUNK_SIZE[@]}; do
    message "TRIAL PFS Chunk: $pchunk Mercury Chunk: $hgchunk"

    # Start servers
    # BWS: Why do this one at a time? Seems crazy/complicated
    # SK: Because they have different initialization parameters.
    # This should be fixed when we go to env variables for initialization
    for svr in $(echo $bbos_server_nodes | sed "s/,/ /g"); do
      container_dir=$bb_dir/containers-$pchunk-$hgchunk-$svr
      do_mpirun 1 1 "" "" "mkdir -p $container_dir" "$logfile"

      # SK: moved background inside start_server
      env_vars=("BB_Server_port" "19900" "BB_Lustre_chunk_size" "$pchunk"
                "BB_Mercury_transfer_size" "$hgchunk" "BB_Num_workers" "4"
                "BB_Server_IP_address" "$svr" "BB_Output_dir" "$container_dir")
      start_server "$svr" "$env_vars"
    done
    sleep 3

    # Start client for each BB buddy on each node
    # Perform aprun once for all clients of the same server
    i=1
    all_clients=$(echo $bbos_client_nodes | tr ',' '\n')
    for svr in $(echo $bbos_server_nodes | sed "s/,/ /g"); do
      # Generate string of comma-separated client hostnames for aprun
      clts=$(echo -e $all_clients | head -n $(($i*$num_bbos_server_nodes)) | \
            tail -n $((num_bbos_client_nodes / num_bbos_server_nodes)))
      num_clts=$((num_bbos_client_nodes / num_bbos_server_nodes))
      clts=$(echo -e "$clts" | tr ' ' ',')

      # one aprun for set of clients bound to one server
      env_vars=("BB_Server_port" "19900" "BB_Mercury_transfer_size" "$hgchunk"
      "BB_Object_size" "$((2**30))" "BB_Server_IP_address" "$svr")
      start_clients "$clts" "$env_vars" $num_clts
      client_pids[$i]=$! # so that we can wait for clients to finish
      i=$((i+1))
    done

    # Waiting for clients to finish data transfer to server
    for c_pid in "${!client_pids[@]}"; do
      wait ${client_pids[$c_pid]}
    done

    # Send SIGINT to initiate server shutdown
    # SK: removed wait, see above
    for svr in $(echo $bbos_server_nodes | sed "s/,/ /g"); do
      kill_server $svr
    done

    # Waiting for servers to finish binpacking
    wait
  done
done

exit 0
