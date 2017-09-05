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

# data files to install  (non-executable)
set (install-files README.md vpic_plots.R)

# executable scripts to install
set (install-programs basic-bb.sh ethq.pl process_logs.sh
     process_runner.pl report_runner.pl)

# executable scripts to @-expand and then install
set (install-programs-in common.sh.in
     run_local_mercury_runner.sh.in  run_mercury_runner.sh.in
     run_sndrcv_test.sh.in run_minimal.sh.in run_narwhal.sh.in
     run_vpic_test.sh.in run_bbos_test.sh.in lanl_do_mercury_runner.sh.in
     lanl_do_minimal_vpic.sh.in lanl_do_vpic_test.sh.in
     vpicexpt_gen.pl.in)

#
# expand ${install-programs-in} and build a list of output files for install
#
foreach (lcv ${install-programs-in})
    string (REGEX REPLACE "\\.in$" "" out "${lcv}")
    configure_file (${lcv} ${out} @ONLY)
    list (APPEND install-programs-in-done ${CMAKE_CURRENT_BINARY_DIR}/${out})
endforeach ()

#
# "make install" rules
#
install (FILES ${install-files} DESTINATION scripts)
install (PROGRAMS ${install-programs} DESTINATION scripts)
install (PROGRAMS ${install-programs-in-done} DESTINATION scripts)
