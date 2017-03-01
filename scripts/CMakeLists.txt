#
# CMakeLists.txt  deltafs-umbrella scripts
# 28-Feb-2017  chuck@ece.cmu.edu


# command line config:
#
# -DCMAKE_INSTALL_PREFIX=/tmp/delta       # where to install
#                                         # defaults to /usr/local
#

cmake_minimum_required (VERSION 3.0)
project (deltafs-umbrella-scripts NONE)

set (install-files README.md vpic_plots.R)
set (install-programs common.sh process_logs.sh run_bbos_test.sh
     run_shuffle_test.sh run_sndrcv_test.sh run_trinity.sh
     run_vpic_test.sh)

#
# we could run these through configure_file if we wanted to expand
# some cmake vars in them...
#

#
# "make install" rules
#
install (FILES ${install-files} DESTINATION scripts)
install (PROGRAMS ${install-programs} DESTINATION scripts)

