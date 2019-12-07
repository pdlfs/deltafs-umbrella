#
# nexus-runner.cmake  umbrella for nexus-runner tester/benchmark
# 26-Nov-2017  chuck@ece.cmu.edu
#

#
# config:
#  NEXUS_RUNNER_REPO - url of git repository
#  NEXUS_RUNNER_TAG  - tag to checkout of git
#  NEXUS_RUNNER_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET nexus-runner)

#
# umbrella option variables
#
umbrella_defineopt (NEXUS_RUNNER_REPO
     "https://github.com/pdlfs/nexus-runner.git"
     STRING "nexus-runner GIT repository")
umbrella_defineopt (NEXUS_RUNNER_TAG "master" STRING "nexus-runner GIT tag")
umbrella_defineopt (NEXUS_RUNNER_TAR 
     "nexus-runner-${NEXUS_RUNNER_TAG}.tar.gz"
     STRING "nexus-runner cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (NEXUS_RUNNER_DOWNLOAD nexus-runner ${NEXUS_RUNNER_TAR}
                   GIT_REPOSITORY ${NEXUS_RUNNER_REPO}
                   GIT_TAG ${NEXUS_RUNNER_TAG})
umbrella_patchcheck (NEXUS_RUNNER_PATCHCMD nexus-runner)

#
# depends
#
include (umbrella/deltafs-nexus)
include (umbrella/deltafs-shuffle)
include (umbrella/mercury)

#
# create nexus-runner target
#
ExternalProject_Add (nexus-runner DEPENDS mercury deltafs-nexus deltafs-shuffle
    ${NEXUS_RUNNER_DOWNLOAD} ${NEXUS_RUNNER_PATCHCMD}
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET nexus-runner)
