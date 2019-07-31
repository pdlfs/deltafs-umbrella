#
# osu-micro-benchmarks.cmake  umbrella for osu-micro-benchmarks
# 29-Jul-2019  chuck@ece.cmu.edu
#

#
# XXX: currently no umbrella support for adding CUDA enable flags...
#      can be added later, if needed
# XXX: will use git repo if specified, otherwise will ftp from OSU
#

#
# config:
#  OSU_MICRO_BENCHMARKS_BASEURL - base url of osu benchmarks
#  OSU_MICRO_BENCHMARKS_URLDIR  - subdir in base where benchmarks lives
#  OSU_MICRO_BENCHMARKS_URLFILE - tar file within urldir
#  OSU_MICRO_BENCHMARKS_URLMD5  - md5 of tar file
#  OSU_MICRO_BENCHMARKS_REPO    - url of git repository
#  OSU_MICRO_BENCHMARKS_TAG     - tag to checkout of git
#

if (NOT TARGET osu-micro-benchmarks)

#
# umbrella option variables
#
umbrella_defineopt (OSU_MICRO_BENCHMARKS_BASEURL
    "http://mvapich.cse.ohio-state.edu/download/mvapich"
    STRING "base url for osu benchmarks")
umbrella_defineopt (OSU_MICRO_BENCHMARKS_URLFILE 
    "osu-micro-benchmarks-5.6.1.tar.gz" STRING "benchmark tar file name")
umbrella_defineopt (OSU_MICRO_BENCHMARKS_URLMD5 
    "0d2389d93ec2a0be60f21b0aecd14345" STRING "MD5 of tar file")
umbrella_defineopt (OSU_MICRO_BENCHMARKS_REPO "" STRING "benchmark repo")
umbrella_defineopt (OSU_MICRO_BENCHMARKS_TAG "master" 
    STRING "benchmark git tag")

#
# generate parts of the ExternalProject_Add args...  we use the repo
# if provided...
#
if ("${OSU_MICRO_BENCHMARKS_REPO}" STREQUAL "")
    umbrella_download (OSU_MICRO_BENCHMARKS_DOWNLOAD osu-micro-benchmarks 
        ${OSU_MICRO_BENCHMARKS_URLFILE}
        URL "${OSU_MICRO_BENCHMARKS_BASEURL}/${OSU_MICRO_BENCHMARKS_URLFILE}"
        URL_MD5 ${OSU_MICRO_BENCHMARKS_URLMD5})
else()
    umbrella_download (OSU_MICRO_BENCHMARKS_DOWNLOAD osu-micro-benchmarks 
        ${OSU_MICRO_BENCHMARKS_URLFILE}
        GIT_REPOSITORY "${OSU_MICRO_BENCHMARKS_REPO}"
        GIT_TAG "${OSU_MICRO_BENCHMARKS_TAG}")
endif()
umbrella_patchcheck (OSU_MICRO_BENCHMARKS_PATCHCMD osu-micro-benchmarks)

#
# create osu-micro-benchmarks target
#
ExternalProject_Add (osu-micro-benchmarks 
    ${OSU_MICRO_BENCHMARKS_DOWNLOAD}
    ${OSU_MICRO_BENCHMARKS_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_MPICOMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      ${UMBRELLA_PKGCFGPATH}
                      --prefix=${CMAKE_INSTALL_PREFIX}
    BUILD_IN_SOURCE 1   # XXX: -I's do not support out of tree builds ...
    UPDATE_COMMAND "")

#
# add extra autogen prepare step to avoid rerunning configure during
# the build step due to the timestamps getting messed up.  not using
# ensure-autogen because the tar file does come with a configure script.
#
if (NOT "${OSU_MICRO_BENCHMARKS_REPO}" STREQUAL "")
    ExternalProject_Add_Step (osu-micro-benchmarks prepare
        COMMAND autoreconf -fi
        COMMENT "preparing source for configure"
        DEPENDEES update
        DEPENDERS configure
        WORKING_DIRECTORY <SOURCE_DIR>)
endif()

endif (NOT TARGET osu-micro-benchmarks)
