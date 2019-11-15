#
# scons.cmake  umbrella for SCONS python build scripts
# 29-Aug-2019  chuck@ece.cmu.edu
#

#
# config:
#  SCONS_REPO - url of git repository
#  SCONS_TAG  - tag to checkout of git
#  SCONS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET scons)

#
# umbrella option variables
#
umbrella_defineopt (SCONS_REPO "https://github.com/SCons/scons.git"
                    STRING "SCONS GIT repository")
umbrella_defineopt (SCONS_TAG "master" STRING "SCONS GIT tag")
umbrella_defineopt (SCONS_TAR "scons-${SCONS_TAG}.tar.gz" STRING
                    "SCONS cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (SCONS_DOWNLOAD scons ${SCONS_TAR}
                   GIT_REPOSITORY ${SCONS_REPO}
                   GIT_TAG ${SCONS_TAG})
umbrella_patchcheck (SCONS_PATCHCMD scons)

#
# scons needs python - most systems should have it, so rather than
# building it we just check that it is in the path.
#
find_program (SCONS_PYTHON NAMES python)
if (SCONS_PYTHON)
    message (STATUS "  scons: building with python ${SCONS_PYTHON}")
else ()
    message (FATAL_ERROR "scons: can't find python in your PATH?")
endif ()

#
# create scons target
#
ExternalProject_Add (scons ${SCONS_DOWNLOAD} ${SCONS_PATCHCMD}
    CONFIGURE_COMMAND ""
    BUILD_IN_SOURCE 1      # old school build
    BUILD_COMMAND ${SCONS_PYTHON} bootstrap.py build/scons
    INSTALL_COMMAND ${SCONS_PYTHON} build/scons/setup.py 
                        install --prefix=${CMAKE_INSTALL_PREFIX}
    UPDATE_COMMAND "")

endif (NOT TARGET scons)
