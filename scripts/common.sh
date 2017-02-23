#!/bin/bash -eu
#
# Common code shared across experiment scripts

# TODO:
# - Convert node lists to ranges on CRAY

# Generate host lists
gen_hosts() {
    message "Generating host lists..."

    if [ `which aprun` ]; then
        # Generate host lists on CRAY and store them on disk
        cat $PBS_NODEFILE | uniq | sort | head -n 1 | \
            tr '\n' ',' > $output_dir/deltafs.hosts || \
            die "failed to create deltafs.hosts file"
        cat $PBS_NODEFILE | uniq | sort | head -n $nodes | tail -n $((nodes-1)) | \
            tr '\n' ',' > $output_dir/vpic.hosts || \
            die "failed to create vpic.hosts file"
        cat $PBS_NODEFILE | uniq | sort | tail -n $bbos_buddies | \
            tr '\n' ',' > $output_dir/bbos.hosts || \
            die "failed to create bbos.hosts file"

    else
        # Generate host lists on Emulab and store them on disk
        fqdn_suffix="`hostname | sed 's/^[^\.]*././'`"
        exp_hosts="`/share/testbed/bin/emulab-listall | tr ',' '\n'`"

        echo $exp_hosts | head -n 1 | \
            tr '\n' ',' > $output_dir/deltafs.hosts || \
            die "failed to create deltafs.hosts file"
        echo $exp_hosts | head -n $nodes | tail -n $((nodes-1)) | \
            tr '\n' ',' > $output_dir/vpic.hosts || \
            die "failed to create vpic.hosts file"
        echo $exp_hosts | tail -n $bbos_buddies | \
            tr '\n' ',' > $output_dir/bbos.hosts || \
            die "failed to create bbos.hosts file"
    fi

    # Populate host list variables
    deltafs_nodes=$(cat $output_dir/deltafs.hosts)
    vpic_nodes=$(cat $output_dir/vpic.hosts)
    bbos_nodes=$(cat $output_dir/bbos.hosts)
}

# Clear node caches on Narwhal
clear_caches() {
    message "Clearing node caches..."

    if [ `which aprun` ]; then
        aprun -L $vpic_nodes -n $cores -N $((nodes - 1)) sudo sh -c \
            'echo 3 > /proc/sys/vm/drop_caches'
    else 
        /share/testbed/bin/emulab-mpirunall sudo sh -c \
            'echo 3 > /proc/sys/vm/drop_caches'
    fi
}

# Configure config.h
# @1 in {"file-per-process", "file-per-particle"}
# @2 particles
build_deck() {
    p=$2

    cd $deck_dir || die "cd failed"
    mv $deck_dir/config.h $deck_dir/config.bkp || die "mv failed"

    case $1 in
    "file-per-process")
        cat $deck_dir/config.bkp | \
            sed 's/^#define VPIC_FILE_PER_PARTICLE/\/\/#define VPIC_FILE_PER_PARTICLE/' | \
            sed 's/VPIC_TOPOLOGY_X.*/VPIC_TOPOLOGY_X '$cores'/' | \
            sed 's/VPIC_TOPOLOGY_Y.*/VPIC_TOPOLOGY_Y 1/' | \
            sed 's/VPIC_TOPOLOGY_Z.*/VPIC_TOPOLOGY_Z 1/' | \
            sed 's/VPIC_PARTICLE_X.*/VPIC_PARTICLE_X '$p'/' | \
            sed 's/VPIC_PARTICLE_Y.*/VPIC_PARTICLE_Y '$p'/' | \
            sed 's/VPIC_PARTICLE_Z.*/VPIC_PARTICLE_Z 1/' > $deck_dir/config.h || \
            die "config.h editing failed"
        ;;
    "file-per-particle")
        cat $deck_dir/config.bkp | \
            sed 's/^\/\/#define VPIC_FILE_PER_PARTICLE/#define VPIC_FILE_PER_PARTICLE/' | \
            sed 's/VPIC_TOPOLOGY_X.*/VPIC_TOPOLOGY_X '$cores'/' | \
            sed 's/VPIC_TOPOLOGY_Y.*/VPIC_TOPOLOGY_Y 1/' | \
            sed 's/VPIC_TOPOLOGY_Z.*/VPIC_TOPOLOGY_Z 1/' | \
            sed 's/VPIC_PARTICLE_X.*/VPIC_PARTICLE_X '$p'/' | \
            sed 's/VPIC_PARTICLE_Y.*/VPIC_PARTICLE_Y '$p'/' | \
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
    np=$2
    declare -a envs=("${!3}")
    hosts="$4"
    exe="$5"
    outfile="$6"

    if [ `which aprun` ]; then
        # This is likely a CRAY machine. Deploy an aprun job.
        if [ ${#envs[@]} -gt 0 ]; then
            envstr=`printf -- "-e %s=\"%s\" " ${envs[@]}`
        else
            envstr=""
        fi

        if [ $np -gt 0 ]; then
            npstr="-N $np"
        else
            npstr=""
        fi

        aprun -L $hosts -n $procs $npstr $envstr $exe 2>&1 | \
            tee -a $outfile

    elif [ `which mpirun.mpich` ]; then
        if [ ${#envs[@]} -gt 0 ]; then
            envstr=`printf -- "-env %s \"%s\" " ${envs[@]}`
        else
            envstr=""
        fi

        if [ $np -gt 0 ]; then
            die "MPICH does not support a fixed number of processes per node"
        fi

        mpirun.mpich -np $procs --host $hosts $envstr -prepend-rank $exe 2>&1 | \
            tee -a $outfile

    elif [ `which mpirun.openmpi` ]; then
        if [ ${#envs[@]} -gt 0 ]; then
            envstr=`printf -- "-x %s=%s " ${envs[@]}`
        else
            envstr=""
        fi

        if [ $np -gt 0 ]; then
            npstr="-npernode $np"
        else
            npstr=""
        fi

        mpirun.openmpi -np $procs $npstr --host $hosts $envstr -tag-output $exe 2>&1 | \
            tee -a "$outfile"

    else
        die "could not find a supported mpirun or aprun command"
    fi
}

# Run VPIC
# @1 in {"baseline", "deltafs"}
# @2 number of particles
do_run() {
    runtype=$1
    p=$2

    cd $output_dir || die "cd failed"
    mkdir "$output_dir/${runtype}_$p" || die "mkdir failed"
    cd $output_dir/${runtype}_$p || die "cd failed"

    # Define logfile before calling message()
    logfile="$output_dir/${runtype}_$p.log"

    clear_caches

    message ""
    message "=========================================================="
    message "Running VPIC ($runtype) with $(( p * p * 100 )) particles."
    message "=========================================================="
    message ""

    case $runtype in
    "baseline")
        vars=()

        do_mpirun $cores 0 vars[@] "$vpic_nodes" "$deck_dir/turbulence.op" $logfile
        if [ $? -ne 0 ]; then
            die "baseline: mpirun failed"
        fi

        echo -n "Output size: " >> $logfile
        du -b $output_dir/baseline_$p | tail -1 | cut -f1 >> $logfile
        ;;

    "deltafs")
        # Start BBOS servers and clients

        message "BBOS Per-core log size: $((bb_log_size / (2**20)))MB"
        
        bb_server_list=$(cat $output_dir/bbos.hosts | tr '\n' ' ')
        n=1
        for s in $bb_server_list; do
            container_dir=$output_dir/bbos/containers.$n
            mkdir -p $container_dir

            # Copying config files for every server
            new_server_config=$output_dir/bbos/server.$n
            cp $bb_server_cfg $new_server_config
            echo $s >> $new_server_config
            echo $container_dir >> $new_server_config

            do_mpirun 1 0 "" "$s" "$bb_server $new_server_config" "$logfile" &
            
            message "BBOS server started at $s"

            sleep 5

            # Copying config files for every client of this server
            cp $bb_client_cfg $output_dir/bbos/client.$n
            echo $s >> $output_dir/bbos/client.$n

            n=$((n + 1))
        done

        c=1
        while [ $c -le $bb_clients ]; do
            s=$(((c % bb_servers) + 1))
            cfg_file=$output_dir/bbos/client.$s
            do_mpirun 1 0 "" "$bbos_nodes" \
                "$bb_client $c.obj $cfg_file $bb_log_size $bb_sst_size" "$logfile" &

            message "BBOS client #$c started bound to server #$s"

            sleep 1

            c=$((c + 1))
        done

        # Start DeltaFS processes
        mkdir -p $output_dir/deltafs_$p/metadata || \
            die "deltafs metadata mkdir failed"
        mkdir -p $output_dir/deltafs_$p/data || \
            die "deltafs data mkdir failed"

        preload_lib_path="$umbrella_build_dir/deltafs-vpic-preload-prefix/src/"\
"deltafs-vpic-preload-build/src/libdeltafs-preload.so"
        deltafs_srvr_path="$umbrella_build_dir/deltafs-prefix/src/"\
"deltafs-build/src/server/deltafs-srvr"
        deltafs_srvr_ip=`hostname -i`

#        vars=("DELTAFS_MetadataSrvAddrs" "$deltafs_srvr_ip:10101"
#              "DELTAFS_FioName" "posix"
#              "DELTAFS_FioConf" "root=$output_dir/deltafs_$p/data"
#              "DELTAFS_Outputs" "$output_dir/deltafs_$p/metadata")
#
#        do_mpirun 1 0 vars[@] "$deltafs_nodes" "$deltafs_srvr_path" $logfile
#        if [ $? -ne 0 ]; then
#            die "deltafs server: mpirun failed"
#        fi
#
#        srvr_pid=$!

        vars=("LD_PRELOAD" "$preload_lib_path"
              "PRELOAD_Deltafs_root" "particle"
              "PRELOAD_Local_root" "${output_dir}"
              "PRELOAD_Bypass_deltafs_namespace" "1"
              "PRELOAD_Enable_verbose_error" "1"
              "SHUFFLE_Virtual_factor" "1024"
              "SHUFFLE_Mercury_proto" "bmi+tcp"
              "SHUFFLE_Subnet" "$ip_subnet")
#              "DELTAFS_MetadataSrvAddrs" "$deltafs_srvr_ip:10101"

        do_mpirun $cores 0 vars[@] "$vpic_nodes" "$deck_dir/turbulence.op" $logfile
        if [ $? -ne 0 ]; then
#            kill -KILL $srvr_pid
            die "deltafs: mpirun failed"
        fi

#        kill -KILL $srvr_pid

        echo -n "Output size: " >> $logfile
        du -b $output_dir/deltafs_$p | tail -1 | cut -f1 >> $logfile

        # Kill BBOS clients and servers
        message ""
        message "Killing BBOS servers"
        for s in $bb_server_list; do
            message "- Killing BBOS server: $s"
            do_mpirun 1 0 "" "$s" "pkill -SIGINT bbos_server" "$logfile"
        done

        ;;
    "shuffle-test")
        np=$2

        # Start DeltaFS processes
        mkdir -p $output_dir/deltafs_$p/metadata || \
            die "deltafs metadata mkdir failed"
        mkdir -p $output_dir/deltafs_$p/data || \
            die "deltafs data mkdir failed"

        preload_lib_path="$umbrella_build_dir/deltafs-vpic-preload-prefix/src/"\
"deltafs-vpic-preload-build/src/libdeltafs-preload.so"
        deltafs_srvr_path="$umbrella_build_dir/deltafs-prefix/src/"\
"deltafs-build/src/server/deltafs-srvr"
        deltafs_srvr_ip=`hostname -i`

#        vars=("DELTAFS_MetadataSrvAddrs" "$deltafs_srvr_ip:10101"
#              "DELTAFS_FioName" "posix"
#              "DELTAFS_FioConf" "root=$output_dir/deltafs_$p/data"
#              "DELTAFS_Outputs" "$output_dir/deltafs_$p/metadata")
#
#        do_mpirun 1 0 vars[@] "$deltafs_nodes" "$deltafs_srvr_path" $logfile
#        if [ $? -ne 0 ]; then
#            die "deltafs server: mpirun failed"
#        fi
#
#        srvr_pid=$!

        vars=("LD_PRELOAD" "$preload_lib_path"
              "PRELOAD_Deltafs_root" "particle"
              "PRELOAD_Local_root" "${output_dir}"
              "PRELOAD_Bypass_deltafs_namespace" "y"
              "PRELOAD_Bypass_write" "y"
              "PRELOAD_Enable_verbose_error" "y"
              "SHUFFLE_Virtual_factor" "1024"
              "SHUFFLE_Mercury_proto" "bmi+tcp"
              "SHUFFLE_Subnet" "$ip_subnet")
#              "DELTAFS_MetadataSrvAddrs" "$deltafs_srvr_ip:10101"

        do_mpirun $cores $np vars[@] "$vpic_nodes" "$deck_dir/turbulence.op" $logfile
        if [ $? -ne 0 ]; then
#            kill -KILL $srvr_pid
            die "deltafs: mpirun failed"
        fi

#        kill -KILL $srvr_pid

        echo -n "Output size: " >> $logfile
        du -b $output_dir/deltafs_$p | tail -1 | cut -f1 >> $logfile

        ;;
    esac
}
