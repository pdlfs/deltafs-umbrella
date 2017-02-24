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
num_bbos_client_nodes=1
num_bbos_server_nodes=1
deltafs_dir="$SWHOME/deltafs"
job_dir="/lustre/ttscratch1/users/$USER/$MOAB_JOBNAME.$PBS_JOBID"
bb_dir="$DW_JOB_STRIPED"
config_dir="$job_dir/config"
# SK: need scratch config dir for each run
scratch_config_dir=$job_dir/scratch_config
logfile="$job_dir/bb-test-log.txt"

# Client transfer sizes we experiment with
OBJECT_CHUNK_SIZE=($((1*(2**20))))
#                   $((2*(2**20)))
#                   $((4*(2**20)))
#                   $((8*(2**20)))) # 1-8 MB

# Lustre sizes we experiment with
PFS_CHUNK_SIZE=($(( 8*(2**20))))
#                $((16*(2**20)))
#                $((32*(2**20)))
#                $((64*(2**20)))) # 8-64 MB

message () { echo "$@" | tee -a $logfile; }

test_raw_bw() {
  svrs=$1
  outfile=$2
  blocksize=$3
  count=$4

  message "RAW dd throughput: servers=$svrs bs=$blocksize count=$count"
  aprun -L $svrs -n 1 dd if=/dev/zero of=$outfile bs=$blocksize count=$count 2>&1 | tee -a $logfile
  wait
}

start_server() {
  svr_name=$1
  cfg_file=$2
  exe=$deltafs_dir/bin/bbos_server

  message "Starting Server: server=$svr_name"
  aprun -L $svr_name -n 1 $exe $cfg_file 2>&1 | tee -a $logfile &
}

start_clients() {
  clients=$1
  obj_name=$2
  cfg_file=$3
  obj_size=$4
  chunk_size=$5
  exe=$deltafs_dir/bin/bbos_client

  message "Starting clients: clients=$clients"
  # SK: line below is a temporary fix to get each client to create an object
  # whose name is the same as the client. Eventually env variables will obviate
  # the need to do this.
  local_expansion="$exe \$h $cfg_file $obj_size $chunk_size"
  aprun -L $clients -n 1 /bin/bash -c "export h=\$(hostname) ; $local_expansion" 2>&1 | tee -a $logfile &
}

kill_server() {
  svr_name=$1

  message "Killing server: server=$svr_name"
  aprun -L $svr -n 1 pkill -SIGINT bbos_server
}

# Create the logfile
mkdir -p $job_dir
touch $logfile

# Split nodes into clients and servers
bbos_client_nodes=$(cat $PBS_NODEFILE | uniq | sort | head -n $num_bbos_client_nodes | tr '\n' ',')
bbos_server_nodes=$(cat $PBS_NODEFILE | uniq | sort | tail -n $num_bbos_server_nodes | tr '\n' ',')
message "Clients: $bbos_client_nodes"
message "Servers: $bbos_server_nodes"

# Test the burst buffer
aprun -n 1 mkdir -p $bb_dir
echo "Basic ls of Burst Buffer ..."
aprun -n 1 ls -l $bb_dir

# First perform basic BB benchmarking loop across all servers
# BWS: This seems pointless, but whatever
# SK - Goal: estimate bandwidth to burst buffer
for c in ${PFS_CHUNK_SIZE[@]}; do
  count=$((512 * (2**20) / c))

  message "TRIAL BW Testing BB Chunk: $c"

  test_raw_bw $bbos_server_nodes "\$(hostname)" $c $count
  wait # have to wait
done

# Now perform client-server test
# SK: purposely kept separate client and server bases to avoid renaming all files
mkdir -p $scratch_config_dir
config_server_base="trinitite_server.conf"
config_client_base="trinitite_client.conf"
bbos_client_config="$config_dir/$config_client_base"

for pchunk in ${PFS_CHUNK_SIZE[@]}; do
  for hgchunk in ${OBJECT_CHUNK_SIZE[@]}; do
    message "TRIAL PFS Chunk: $pchunk Mercury Chunk: $hgchunk"

    container_dir=$bb_dir/containers-$pchunk-$hgchunk
    aprun -n 1 mkdir -p $container_dir

    # Start servers
    # BWS: Why do this one at a time? Seems crazy/complicated
    # SK: Because they have different initialization parameters.
    # This should be fixed when we go to env variables for initialization
    for svr in $(echo $bbos_server_nodes | sed "s/,/ /g"); do
      svr_cfgfile=$scratch_config_dir/$config_server_base.$hgchunk.$pchunk.$svr
      clt_cfgfile=$scratch_config_dir/$config_client_base.$svr

      # Create server config for this hgchunk and pchunk setting
      cp $config_dir/$config_server_base.$hgchunk.$pchunk $svr_cfgfile
      echo $svr >> $svr_cfgfile             # Server name (for Mercury)
      echo $container_dir >> $svr_cfgfile   # Binpacked container dir

      # Create client config for this hgchunk and pchunk setting
      cp $bbos_client_config $clt_cfgfile
      echo $svr >> $clt_cfgfile

      # SK: moved background inside start_server
      start_server $svr $svr_cfgfile
    done
    sleep 3

    # Start client for each BB buddy on each node
    # Perform aprun once for all clients of the same server
    i=1
    all_clients=$(echo $bbos_client_nodes | tr ',' '\n')
    for svr in $(echo $bbos_server_nodes | sed "s/,/ /g"); do
      # Generate string of comma-separated client hostnames for aprun
      clts=$(echo -e "$all_clients" | head -n $(($i*$num_bbos_server_nodes)) | \
            tail -n $num_bbos_server_nodes)
      clts=$(echo "$clts" | tr '\n' ',')
      objname="\$(hostname)"
      cfgfile=$scratch_config_dir/$bbos_client_config.$svr
      cfgfile=$scratch_config_dir/trinitite_client.conf.$svr

      # one aprun for set of clients bound to one server
      start_clients $clts $objname $cfgfile $((2**30)) $hgchunk
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
