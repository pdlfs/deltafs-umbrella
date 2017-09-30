#
# mercury-runner.cmake  umbrella for mercury-runner tester/benchmark
# 29-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  MERCURY_RUNNER_REPO - url of git repository
#  MERCURY_RUNNER_TAG  - tag to checkout of git
#  MERCURY_RUNNER_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET mercury-runner)

#
# variables that users can set
#
set (MERCURY_RUNNER_REPO "https://github.com/pdlfs/mercury-runner.git"
     CACHE STRING "mercury-runner GIT repository")
set (MERCURY_RUNNER_TAG "773e6cc5"
     CACHE STRING "mercury-runner GIT tag") # Sep 2017
set (MERCURY_RUNNER_TAR "mercury-runner-${MERCURY_RUNNER_TAG}.tar.gz"
     CACHE STRING "mercury-runner cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (MERCURY_RUNNER_DOWNLOAD mercury-runner ${MERCURY_RUNNER_TAR}
                   GIT_REPOSITORY ${MERCURY_RUNNER_REPO}
                   GIT_TAG ${MERCURY_RUNNER_TAG})
umbrella_patchcheck (MERCURY_RUNNER_PATCHCMD mercury-runner)

#
# depends
#
include (umbrella/mercury)

#
# create mercury-runner target
#
ExternalProject_Add (mercury-runner DEPENDS mercury
    ${MERCURY_RUNNER_DOWNLOAD} ${MERCURY_RUNNER_PATCHCMD}
    CMAKE_ARGS -DMPI=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET mercury-runner)
