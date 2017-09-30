#
# umbrella-init.cmake  umbrella init, include this before "project"
# 27-Sep-2017  chuck@ece.cmu.edu
#

if(POLICY CMP0054)
    # avoid warn from CMakeDetermineCompilerABI about an "if" with ${CXX}
    # can be removed once cmake 3.1 is required
    cmake_policy(SET CMP0054 NEW)
endif()

#
# if CC/CXX is specified from the command line (vs. environment vars)
# we copy them to CMAKE_{C,CXX}_COMPILER early (before 'project') so
# that we probe the desired compiler.   note that cmake already honors
# ENV{CC}/ENV{CXX} so we don't need to do anything for those vars.
#
if (CC)
    set (CMAKE_C_COMPILER ${CC})
endif ()
if (CXX)
    set (CMAKE_CXX_COMPILER ${CXX})
endif ()

#
# let umbrella-main know we've run this
#
set (UMBRELLA_INIT_DONE 1)
