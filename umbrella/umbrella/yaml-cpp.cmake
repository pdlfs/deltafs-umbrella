#
# yaml-cpp.cmake  umbrella for google log package
# 04-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  YAML_CPP_REPO - url of git repository
#  YAML_CPP_TAG  - tag to checkout of git
#  YAML_CPP_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET yaml-cpp)

#
# umbrella option variables
#
umbrella_defineopt (YAML_CPP_REPO "https://github.com/jbeder/yaml-cpp.git"
     STRING "yaml-cpp GIT repository")
umbrella_defineopt (YAML_CPP_TAG "master" STRING "yaml-cpp GIT tag")
umbrella_defineopt (YAML_CPP_TAR "yaml-cpp-${YAML_CPP_TAG}.tar.gz"
     STRING "yaml-cpp cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (YAML_CPP_DOWNLOAD yaml-cpp ${YAML_CPP_TAR}
                   GIT_REPOSITORY ${YAML_CPP_REPO}
                   GIT_TAG ${YAML_CPP_TAG})
umbrella_patchcheck (YAML_CPP_PATCHCMD yaml-cpp)

#
# depends
#
include (umbrella/boost)

#
# create yaml-cpp target
#
ExternalProject_Add (yaml-cpp DEPENDS boost
    ${YAML_CPP_DOWNLOAD} ${YAML_CPP_PATCHCMD}
    CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET yaml-cpp)
