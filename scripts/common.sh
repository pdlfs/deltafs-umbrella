#!/bin/bash -eu
#
# Common code shared across experiment scripts

# TODO:
# - Convert node lists to ranges on CRAY

message () { echo "$@" | tee -a $logfile; }
die () { message "Error $@"; exit 1; }

# Generate hostfile with all hosts
gen_hostfile() {
    message "Generating hostfile with all hosts..."

    if [ `which aprun` ]; then
        # Generate hostfile on CRAY and store on disk
        cat $PBS_NODEFILE | uniq | sort > $job_dir/hosts.txt || \
            die "failed to create hosts.txt file"

    else
        # Generate hostfile on Emulab and store on disk
        fqdn_suffix="`hostname | sed 's/^[^\.]*././'`"
        exp_hosts="`/share/testbed/bin/emulab-listall | tr ',' '\n' | \
                    sed 's/$/'$fqdn_suffix'/g'`"

        echo "$exp_hosts" > $job_dir/hosts.txt || \
            die "failed to create hosts.txt file"
    fi

    # Populate a variable with hosts
    all_nodes=$(cat $job_dir/hosts.txt)
}

# Generate host lists
gen_hosts() {
    message "Generating host lists..."

    if [ `which aprun` ]; then
        # Generate host lists on CRAY and store them on disk
        cat $PBS_NODEFILE | uniq | sort | head -n $nodes \
            tr '\n' ',' | sed '$s/,$//' > $job_dir/vpic.hosts || \
            die "failed to create vpic.hosts file"
        cat $PBS_NODEFILE | uniq | sort | tail -n $bbos_buddies | \
            tr '\n' ',' | sed '$s/,$//' > $job_dir/bbos.hosts || \
            die "failed to create bbos.hosts file"

    else
        # Generate host lists on Emulab and store them on disk
        fqdn_suffix="`hostname | sed 's/^[^\.]*././'`"
        exp_hosts="`/share/testbed/bin/emulab-listall | tr ',' '\n' | \
                    sed 's/$/'$fqdn_suffix'/g'`"

        echo "$exp_hosts" | head -n $nodes | \
            tr '\n' ',' | sed '$s/,$//' > $job_dir/vpic.hosts || \
            die "failed to create vpic.hosts file"
        echo "$exp_hosts" | tail -n $bbos_buddies | \
            tr '\n' ',' | sed '$s/,$//' > $job_dir/bbos.hosts || \
            die "failed to create bbos.hosts file"
    fi

    # Populate host list variables
    vpic_nodes=$(cat $job_dir/vpic.hosts)
    bbos_nodes=$(cat $job_dir/bbos.hosts)
    # num_bbos_nodes=$(cat $job_dir/bbos.hosts | wc -l)
    # num_vpic_nodes=$(cat $job_dir/vpic.hosts | wc -l)
}

# Clear node caches
clear_caches() {
    message "Clearing node caches..."

    if [ `which aprun` ]; then
        aprun -L $vpic_nodes -n $cores -N $nodes sudo sh -c \
            'echo 3 > /proc/sys/vm/drop_caches'
    else
        /share/testbed/bin/emulab-mpirunall sudo sh -c \
            'echo 3 > /proc/sys/vm/drop_caches'
    fi
}

# Configure config.h
# @1 in {"file-per-process", "file-per-particle"}
# @2 particles on x dimension
# @3 particles on y dimension
build_deck() {
    px=$2
    py=$3

    cd $deck_dir || die "cd failed"
    mv $deck_dir/config.h $deck_dir/config.bkp || die "mv failed"

    case $1 in
    "file-per-process")
        cat $deck_dir/config.bkp | \
            sed 's/^#define VPIC_FILE_PER_PARTICLE/\/\/#define VPIC_FILE_PER_PARTICLE/' | \
            sed 's/VPIC_TOPOLOGY_X.*/VPIC_TOPOLOGY_X '$cores'/' | \
            sed 's/VPIC_TOPOLOGY_Y.*/VPIC_TOPOLOGY_Y 1/' | \
            sed 's/VPIC_TOPOLOGY_Z.*/VPIC_TOPOLOGY_Z 1/' | \
            sed 's/VPIC_PARTICLE_X.*/VPIC_PARTICLE_X '$px'/' | \
            sed 's/VPIC_PARTICLE_Y.*/VPIC_PARTICLE_Y '$py'/' | \
            sed 's/VPIC_PARTICLE_Z.*/VPIC_PARTICLE_Z 1/' > $deck_dir/config.h || \
            die "config.h editing failed"
        ;;
    "file-per-particle")
        cat $deck_dir/config.bkp | \
            sed 's/^\/\/#define VPIC_FILE_PER_PARTICLE/#define VPIC_FILE_PER_PARTICLE/' | \
            sed 's/VPIC_TOPOLOGY_X.*/VPIC_TOPOLOGY_X '$cores'/' | \
            sed 's/VPIC_TOPOLOGY_Y.*/VPIC_TOPOLOGY_Y 1/' | \
            sed 's/VPIC_TOPOLOGY_Z.*/VPIC_TOPOLOGY_Z 1/' | \
            sed 's/VPIC_PARTICLE_X.*/VPIC_PARTICLE_X '$px'/' | \
            sed 's/VPIC_PARTICLE_Y.*/VPIC_PARTICLE_Y '$py'/' | \
            sed 's/VPIC_PARTICLE_Z.*/VPIC_PARTICLE_Z 1/' > $deck_dir/config.h || \
            die "config.h editing failed"
        ;;
    *)
        die "build_deck: VPIC mode not supported"
        ;;
    esac

    # Compile input deck
    cd $deck_dir || die "cd failed"
    $build_op_dir/build.op ./turbulence.cxx || die "compilation failed"
}

# Run CRAY MPICH, ANL MPICH, or OpenMPI run command
# Arguments:
# @1 number of processes
# @2 number of processes per node
# @3 array of env vars: ("name1", "val1", "name2", ... )
# @4 host list (comma-separated)
# @5 executable (and any options that don't fit elsewhere)
# @6 outfile (used to log output)
do_mpirun() {
    procs=$1
    ppnode=$2
    if [ ! -z "$3" ]; then
        declare -a envs=("${!3}")
    else
        envs=()
    fi
    hosts="$4"
    exe="$5"
    outfile="$6"

    envstr=""; npstr=""; hstr=""

    if [ `which aprun` ]; then
        # This is likely a CRAY machine. Deploy an aprun job.

        if [ ${#envs[@]} -gt 0 ]; then
            envstr=`printf -- "-e %s=\"%s\" " ${envs[@]}`
        fi

        if [ $ppnode -gt 0 ]; then
            npstr="-N $ppnode"
        fi

        if [ ! -z "$hosts" ]; then
            hstr="-L $hosts"
        fi

        message "Running: aprun $hstr -n $procs $npstr $envstr $exe"
        aprun $hstr -n $procs $npstr $envstr $exe 2>&1 | tee -a $outfile

    elif [ `which mpirun.mpich` ]; then
        if [ ${#envs[@]} -gt 0 ]; then
            envstr=`printf -- "-env %s \"%s\" " ${envs[@]}`
        fi

        if [ $ppnode -gt 0 ]; then
            die "MPICH does not support a fixed number of processes per node"
        fi

        if [ ! -z "$hosts" ]; then
            hstr="--host $hosts"
        fi

        message "mpirun.mpich -np $procs $hstr $envstr $exe"
        mpirun.mpich -np $procs $hstr $envstr $exe 2>&1 | tee -a $outfile

    elif [ `which mpirun.openmpi` ]; then
        if [ ${#envs[@]} -gt 0 ]; then
            envstr=`printf -- "-x %s=%s " ${envs[@]}`
        fi

        if [ $ppnode -gt 0 ]; then
            npstr="-npernode $ppnode"
        fi

        if [ ! -z "$hosts" ]; then
            hstr="--host $hosts"
        fi

        message "mpirun.openmpi -np $procs $npstr $hstr $envstr $exe"
        mpirun.openmpi -np $procs $npstr $hstr $envstr $exe 2>&1 | tee -a "$outfile"

    else
        die "could not find a supported mpirun or aprun command"
    fi
}

# Query particle trajectories
# @1 experiment type in {"baseline", "deltafs"}
# @2 vpic output directory
# @3 total number of particles
# @4 logfile to print results in
query_particles() {
    runtype=$1
    vpicout=$2
    qparts=$3
    logfile=$4

    case $runtype in
    "baseline")
        reader_bin="$umbrella_build_dir/trecon-reader-prefix/src/"\
"trecon-reader-build/vpic-reader"
        ;;
    "deltafs")
        reader_bin="$umbrella_build_dir/deltafs-vpic-preload-prefix/src/"\
"deltafs-vpic-preload-build/tools/vpic-deltafs-reader"
        ;;
    *)
        die "query_particles: unknown runtype '$runtype'"
    esac

    # Query more particles per iteration, from 10**0 to 10**6 (1M)
    # to see when the DeltaFS approach breaks compared to the old,
    # single-pass approach
    n=0
    while [ $n -le 6 ] && [ $((10**n)) -lt $qparts ]; do
        mkdir -p $vpicout/reader/part_10_$n || die "mkdir for reader output failed"
        $reader_bin -n $((10**n)) -i $vpicout -o $vpicout/reader/part_10_$n | tee -a $logfile

        n=$((n + 1))
    done
}

# Run VPIC
# @1 experiment type in {"baseline", "deltafs", "shuffle_test"}
# @2 number of particles
do_run() {
    runtype=$1
    p=$2

    if [ $((p / (10**6))) -gt 0 ]; then
        pp="$((p / (10**6)))M"
    elif [ $((p / (10**3))) -gt 0 ]; then
        pp="$((p / (10**3)))K"
    else
        pp="$p"
    fi

    exp_dir="$job_dir/${runtype}_P${pp}_C${cores}_N${nodes}"
    cd $job_dir || die "cd to $job_dir failed"
    mkdir "$exp_dir" || die "mkdir failed"
    cd $exp_dir || die "cd to $exp_dir failed"

    # Define logfile before calling message()
    logfile="$job_dir/${runtype}_P${pp}_C${cores}_N${nodes}.log"

    clear_caches

    message ""
    message "=================================================================="
    message "Running VPIC ($runtype) with $pp particles on $cores cores."
    message "=================================================================="
    message ""

    case $runtype in
    "baseline")
        do_mpirun $cores 0 "" "$vpic_nodes" "$deck_dir/turbulence.op" $logfile
        if [ $? -ne 0 ]; then
            die "baseline: mpirun failed"
        fi

        echo -n "Output size: " >> $logfile
        du -b $exp_dir | tail -1 | cut -f1 >> $logfile

        query_particles $runtype $exp_dir $p $logfile
        ;;

    "deltafs")
        # Start BBOS servers and clients
        exp_dir="$job_dir/${runtype}_$pp"
        message "BBOS Per-core log size: $((bb_log_size / (2**20)))MB"

        bb_server_list=$(cat $job_dir/bbos.hosts | tr '\n' ' ')
        n=1
        for s in $bb_server_list; do
            container_dir=$exp_dir/bbos/containers.$n
            do_mpirun 1 0 "" "" "mkdir -p $container_dir" "$logfile"

            env_vars=("BB_Server_IP_address" "$s"
                      "BB_Output_dir" "$container_dir"
                      "BB_Server_port" "19900")
            do_mpirun 1 0 env_vars[@] "$s" "$bb_server" "$logfile" &

            message "BBOS server started at $s"

            n=$((n + 1))
        done

        sleep 5

        c=1
        all_clients=$(echo $vpic_nodes | tr ',' '\n')
        num_clts_per_svr=$((nodes / bbos_buddies))
        for s in $bb_server_list; do
          # Generate string of comma-separated client hostnames for aprun
          clts=$(echo -e $all_clients | head -n $(($c*$bbos_buddies)) | \
                tail -n $num_clts_per_svr)
          clts=$(echo -e "$clts" | tr ' ' ',')

          # one aprun for set of clients bound to one server
          env_vars=("BB_Server_port" "19900" "BB_Server_IP_address" "$s"
                    "BB_Object_size" "$bb_log_size" "BB_Mercury_transfer_size" "$((2**21))")
          do_mpirun $num_clts_per_svr 0 env_vars[@] "$clts" "$bb_client" "$logfile" &
          client_pids[$c]=$! # so that we can wait for clients to finish
          c=$((c+1))
        done

        # Start DeltaFS processes
        mkdir -p $exp_dir/metadata || die "deltafs metadata mkdir failed"
        mkdir -p $exp_dir/data || die "deltafs data mkdir failed"
        mkdir -p $exp_dir/plfs || die "deltafs plfs mkdir failed"

        preload_lib_path="$umbrella_build_dir/deltafs-vpic-preload-prefix/src/"\
"deltafs-vpic-preload-build/src/libdeltafs-preload.so"
        deltafs_srvr_path="$umbrella_build_dir/deltafs-prefix/src/"\
"deltafs-build/src/server/deltafs-srvr"
        deltafs_srvr_ip=`hostname -i`

        vars=("LD_PRELOAD" "$preload_lib_path"
        "PRELOAD_Deltafs_root" "particle"
        "PRELOAD_Local_root" "${exp_dir}/plfs"
        "PRELOAD_Bypass_deltafs_namespace" "1"
        "PRELOAD_Enable_verbose_error" "1"
        "SHUFFLE_Virtual_factor" "1024"
        "SHUFFLE_Mercury_proto" "bmi+tcp"
        "SHUFFLE_Subnet" "$ip_subnet")

        do_mpirun $cores 0 vars[@] "$vpic_nodes" "$deck_dir/turbulence.op" $logfile
        if [ $? -ne 0 ]; then
          die "deltafs: mpirun failed"
        fi

        echo -n "Output size: " >> $logfile
        du -b $exp_dir | tail -1 | cut -f1 >> $logfile

        # Waiting for clients to finish data transfer to server
        for c_pid in "${!client_pids[@]}"; do
          wait ${client_pids[$c_pid]}
        done

        # Kill BBOS clients and servers
        message ""
        message "Killing BBOS servers"
        do_mpirun $bbos_buddies 0 "" "$bb_server_list" "pkill -SIGINT bbos_server" "$logfile"

        # Wait for BBOS binpacking to complete
        wait

        query_particles $runtype $exp_dir $p $logfile
        ;;
    "shuffle_test")
        np=$3

        # Start DeltaFS processes
        mkdir -p $exp_dir/metadata || die "shuffle test metadata mkdir failed"
        mkdir -p $exp_dir/data || die "shuffle test data mkdir failed"
        mkdir -p $exp_dir/plfs || die "shuffle test plfs mkdir failed"

        preload_lib_path="$umbrella_build_dir/deltafs-vpic-preload-prefix/src/"\
"deltafs-vpic-preload-build/src/libdeltafs-preload.so"
        deltafs_srvr_path="$umbrella_build_dir/deltafs-prefix/src/"\
"deltafs-build/src/server/deltafs-srvr"
        deltafs_srvr_ip=`hostname -i`

        vars=("LD_PRELOAD" "$preload_lib_path"
              "PRELOAD_Deltafs_root" "particle"
              "PRELOAD_Local_root" "${exp_dir}/plfs"
              "PRELOAD_Bypass_write" "y"
              "PRELOAD_Enable_verbose_error" "y"
              "SHUFFLE_Virtual_factor" "1024"
              "SHUFFLE_Mercury_proto" "bmi+tcp"
              "SHUFFLE_Subnet" "$ip_subnet")

        do_mpirun $cores $np vars[@] "$vpic_nodes" "$deck_dir/turbulence.op" $logfile
        if [ $? -ne 0 ]; then
            die "deltafs: mpirun failed"
        fi

        echo -n "Output size: " >> $logfile
        du -b $exp_dir | tail -1 | cut -f1 >> $logfile
        ;;
    esac
}
