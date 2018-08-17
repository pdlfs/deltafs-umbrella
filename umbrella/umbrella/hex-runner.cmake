#
# hex-runner.cmake  umbrella for hex-runner
# 17-Aug-2018
#

#
# config:
#  HEX_RUNNER_REPO - url of git repository
#  HEX_RUNNER_TAG  - tag to checkout of git
#  HEX_RUNNER_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET hex-runner)

#
# umbrella option variables
#
umbrella_defineopt (HEX_RUNNER_REPO
     "https://github.com/pdlfs/hex-runner.git"
     STRING "hex-runner GIT repository")
umbrella_defineopt (HEX_RUNNER_TAG "master" STRING "hex-runner GIT tag")
umbrella_defineopt (HEX_RUNNER_TAR
     "hex-runner-${HEX_RUNNER_TAG}.tar.gz"
     STRING "hex-runner cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (HEX_RUNNER_DOWNLOAD hex-runner ${HEX_RUNNER_TAR}
                   GIT_REPOSITORY ${HEX_RUNNER_REPO}
                   GIT_TAG ${HEX_RUNNER_TAG})
umbrella_patchcheck (HEX_RUNNER_PATCHCMD hex-runner)


#
# create the hex-runner target
#
ExternalProject_Add (hex-runner ${HEX_RUNNER_DOWNLOAD} ${HEX_RUNNER_PATCHCMD}
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET hex-runner)
