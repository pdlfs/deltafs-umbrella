#
# psm.cmake  intel/qlogic psm interface to their ib network cards
# 18-Aug-2020  chuck@ece.cmu.edu
#

#
# config:
#  PSM_REPO - url of git repository
#  PSM_TAG  - tag to checkout of git
#  PSM_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET psm)

#
# umbrella option variables
#
# XXX: use our fork https://github.com/pdlfs/psm.git rather than
# https://github.com/intel/psm.git so we pick up some compile error
# fixes (intel doesn't seem to be maintaining psm anymore).
#
umbrella_defineopt (PSM_REPO "https://github.com/pdlfs/psm.git"
                    STRING "PSM GIT repository")
umbrella_defineopt (PSM_TAG "master" STRING "PSM GIT tag")
umbrella_defineopt (PSM_TAR "psm-${PSM_TAG}.tar.gz" STRING
                    "PSM cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (PSM_DOWNLOAD psm ${PSM_TAR}
                   GIT_REPOSITORY ${PSM_REPO}
                   GIT_TAG ${PSM_TAG})
umbrella_patchcheck (PSM_PATCHCMD psm)

#
# create psm target
#
ExternalProject_Add (psm ${PSM_DOWNLOAD} ${PSM_PATCHCMD}
    CONFIGURE_COMMAND ""
    BUILD_IN_SOURCE 1      # old school makefiles
    BUILD_COMMAND make ${UMBRELLA_COMP}
                       ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
    INSTALL_COMMAND
      mkdir -p ${CMAKE_INSTALL_PREFIX}/lib ${CMAKE_INSTALL_PREFIX}/include
      COMMAND cd <SOURCE_DIR> && 
      sh -c "tar cf - libpsm_infinipath.so* | (cd ${CMAKE_INSTALL_PREFIX}/lib && tar xf - )"
      COMMAND cd <SOURCE_DIR>/ipath && 
      sh -c "tar cf - libinfinipath.so* | (cd ${CMAKE_INSTALL_PREFIX}/lib && tar xf - )"
      COMMAND cp <SOURCE_DIR>/psm.h <SOURCE_DIR>/psm_mq.h
                                       ${CMAKE_INSTALL_PREFIX}/include
    UPDATE_COMMAND "")

endif (NOT TARGET psm)
