# BASEDIR=/mnt/lt20/jobs-big-run/vpic-carp8m
TRACEDIR=/mnt/lustre/carp-big-run/particle.compressed
TRACECNT=12

# EXPDIR=$BASEDIR/carp_P3584M_intvl$INTVL
VPICDIR=$EXPDIR/vpic
PLFSDIR=$EXPDIR/plfs
INFODIR=$EXPDIR/exp-info

PARTCNT=3584

mkdir -p $VPICDIR
mkdir -p $PLFSDIR/particle
mkdir -p $INFODIR

mpirun.mpich -np 512 -ppn 16 -f hosts.txt \
 -env LD_PRELOAD /users/ankushj/range/carp-umb/carp-build/lib/libdeltafs-preload.so \
 -env VPIC_current_working_dir $VPICDIR \
 -env PRELOAD_Ignore_dirs : \
 -env PRELOAD_Deltafs_mntp particle \
 -env PRELOAD_Local_root $PLFSDIR \
 -env PRELOAD_Log_home $INFODIR \
 -env PRELOAD_Pthread_tap 0 \
 -env PRELOAD_Papi_events 'PAPI_L2_TCM;PAPI_L2_TCA' \
 -env PRELOAD_Bypass_deltafs_namespace 1 \
 -env PRELOAD_Bypass_shuffle 0 \
 -env PRELOAD_Bypass_write 0 \
 -env PRELOAD_Bypass_placement 1 \
 -env PRELOAD_Skip_mon 0 \
 -env PRELOAD_Skip_papi 1 \
 -env PRELOAD_Skip_sampling 0 \
 -env PRELOAD_Sample_threshold 64 \
 -env PRELOAD_No_sys_probing 0 \
 -env PRELOAD_No_paranoid_checks 1 \
 -env PRELOAD_No_paranoid_barrier 0 \
 -env PRELOAD_No_paranoid_post_barrier 0 \
 -env PRELOAD_No_paranoid_pre_barrier 0 \
 -env PRELOAD_No_epoch_pre_flushing 0 \
 -env PRELOAD_No_epoch_pre_flushing_wait 1 \
 -env PRELOAD_No_epoch_pre_flushing_sync 1 \
 -env PRELOAD_Print_meminfo 0 \
 -env PRELOAD_Enable_verbose_mode 1 \
 -env PRELOAD_Enable_bg_pause 0 \
 -env PRELOAD_Bg_threads 4 \
 -env PRELOAD_Enable_bloomy 0 \
 -env PRELOAD_Enable_CARP 1 \
 -env PRELOAD_Enable_wisc 0 \
 -env PRELOAD_Particle_buf_size 2097152 \
 -env PRELOAD_Particle_id_size 8 \
 -env PRELOAD_Particle_size 48 \
 -env PRELOAD_Particle_extra_size 0 \
 -env PRELOAD_Number_particles_per_rank 7000000 \
 -env SHUFFLE_Mercury_proto bmi+tcp \
 -env SHUFFLE_Mercury_progress_timeout 100 \
 -env SHUFFLE_Mercury_progress_warn_interval 1000 \
 -env SHUFFLE_Mercury_cache_handles 0 \
 -env SHUFFLE_Mercury_rusage 0 \
 -env SHUFFLE_Mercury_nice 0 \
 -env SHUFFLE_Mercury_max_errors 1 \
 -env SHUFFLE_Buffer_per_queue 32768 \
 -env SHUFFLE_Num_outstanding_rpc 16 \
 -env SHUFFLE_Use_worker_thread 1 \
 -env SHUFFLE_Force_sync_rpc 0 \
 -env SHUFFLE_Placement_protocol ring \
 -env SHUFFLE_Virtual_factor 1024 \
 -env SHUFFLE_Subnet 10.94 \
 -env SHUFFLE_Finalize_pause 0 \
 -env SHUFFLE_Force_global_barrier 0 \
 -env SHUFFLE_Local_senderlimit 16 \
 -env SHUFFLE_Remote_senderlimit 16 \
 -env SHUFFLE_Local_maxrpc 16 \
 -env SHUFFLE_Relay_maxrpc 16 \
 -env SHUFFLE_Remote_maxrpc 16 \
 -env SHUFFLE_Local_buftarget 32768 \
 -env SHUFFLE_Relay_buftarget 32768 \
 -env SHUFFLE_Remote_buftarget 32768 \
 -env SHUFFLE_Dq_min 1024 \
 -env SHUFFLE_Dq_max 4096 \
 -env SHUFFLE_Log_file / \
 -env SHUFFLE_Force_rpc 0 \
 -env SHUFFLE_Hash_sig 0 \
 -env SHUFFLE_Paranoid_checks 0 \
 -env SHUFFLE_Random_flush 0 \
 -env SHUFFLE_Recv_radix 0 \
 -env SHUFFLE_Use_multihop 1 \
 -env PLFSDIR_Skip_checksums 1 \
 -env PLFSDIR_Memtable_size 48MiB \
 -env PLFSDIR_Compaction_buf_size 4MiB \
 -env PLFSDIR_Data_min_write_size 6MiB \
 -env PLFSDIR_Data_buf_size 8MiB \
 -env PLFSDIR_Index_min_write_size 2MiB \
 -env PLFSDIR_Index_buf_size 2MiB \
 -env PLFSDIR_Key_size 8 \
 -env PLFSDIR_Filter_bits_per_key 12 \
 -env PLFSDIR_Lg_parts 2 \
 -env PLFSDIR_Force_leveldb_format 0 \
 -env PLFSDIR_Unordered_storage 0 \
 -env PLFSDIR_Use_plaindb 0 \
 -env PLFSDIR_Use_leveldb 0 \
 -env PLFSDIR_Use_rangedb 1 \
 -env PLFSDIR_Ldb_force_l0 0 \
 -env PLFSDIR_Ldb_use_bf 0 \
 -env PLFSDIR_Env_name posix.unbufferedio \
 -env NEXUS_ALT_LOCAL na+sm \
 -env NEXUS_BYPASS_LOCAL 1 \
 -env DELTAFS_TC_RATE 0 \
 -env DELTAFS_TC_SERIALIO 0 \
 -env DELTAFS_TC_SYNCONCLOSE 0 \
 -env DELTAFS_TC_IGNORESYNC 0 \
 -env DELTAFS_TC_DROPDATA 0 \
 -env RANGE_Enable_dynamic 0 \
 -env RANGE_Reneg_interval $INTVL \
 -env RANGE_Pvtcnt_s1 256 \
 -env RANGE_Pvtcnt_s2 256 \
 -env RANGE_Pvtcnt_s3 256 -bind-to=none /users/ankushj/range/carp-umb/carp-build/bin/range-runner -b 32 -s 2 -i $TRACEDIR -t 6000 file-per-particle trecon-part/turbulence $PARTCNT 10000 1 512 1 1 $TRACECNT $TRACECNT
