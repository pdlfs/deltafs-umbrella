#
# Copyright (c) 2019 Carnegie Mellon University,
# Copyright (c) 2019 Triad National Security, LLC, as operator of
#     Los Alamos National Laboratory.
#
# All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.
#

#
# CMakeLists.txt  deltafs-umbrella scripts
# 28-Feb-2017  chuck@ece.cmu.edu
#

# command line config:
#
# -DCMAKE_INSTALL_PREFIX=/tmp/delta       # where to install
#                                         # defaults to /usr/local
#

cmake_minimum_required (VERSION 3.0)
project (deltafs-umbrella-scripts NONE)

# data files to install  (non-executable)
set (install-files vpic_plots.R)

# executable scripts to install
set (install-programs basic-bb.sh cbatch cobalt_nodefile ethq.pl
     process_logs.sh process_runner.pl report_runner.pl slurm_nodefile
     vpic_common.sh vpic_report.sh vpic_cleanup.pl)

# executable scripts to @-expand and then install
set (install-programs-in anl_do_combo_mercrunner.sh.in common.sh.in
     lanl_do_combo_mercrunner.sh.in
     run_bbos_test.sh.in run_combo_mercury_runner.sh.in
     run_vpic_test.sh.in vpic_mkcombo.pl.in vpicexpt_gen.pl.in)

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
