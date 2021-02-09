#
# psm2.cmake  intel omnipath psm2 interface to their ib network cards
# 09-Feb-2021  chuck@ece.cmu.edu
#

#
# config:
#  PSM2_REPO - url of git repository
#  PSM2_TAG  - tag to checkout of git
#  PSM2_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET psm2)

#
# umbrella option variables
#
# XXX: for testing use chuck's "combo" version (has extra fixes)
# XXX: doesn't install psm compat lib or include/hfi1diag files
#
umbrella_defineopt (PSM2_REPO "https://github.com/chuckcranor/opa-psm2.git"
                    STRING "PSM2 GIT repository")
umbrella_defineopt (PSM2_TAG "combo" STRING "PSM2 GIT tag")
umbrella_defineopt (PSM2_TAR "psm2-${PSM2_TAG}.tar.gz" STRING
                    "PSM2 cache tar file")
umbrella_defineopt (PSM2_USE_AVX2 "ON" BOOL
    "Compile with AVX2 instructions (requires cpu support)")

if (PSM2_USE_AVX2)
    message(STATUS "  psm2 - using AVX2 instructions")
else()
    message(STATUS "  psm2 - disable AVX2 instructions")
    set(xtra_cfg "PSM_DISABLE_AVX2=1")
endif()

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (PSM2_DOWNLOAD psm2 ${PSM2_TAR}
                   GIT_REPOSITORY ${PSM2_REPO}
                   GIT_TAG ${PSM2_TAG})
umbrella_patchcheck (PSM2_PATCHCMD psm2)

#
# create psm2 target
#
ExternalProject_Add (psm2 ${PSM2_DOWNLOAD} ${PSM2_PATCHCMD}
    CONFIGURE_COMMAND ""
    BUILD_IN_SOURCE 1      # old school makefiles
    BUILD_COMMAND make ${UMBRELLA_COMP}
                       ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS} ${xtra_cfg}
    INSTALL_COMMAND
      mkdir -p ${CMAKE_INSTALL_PREFIX}/lib ${CMAKE_INSTALL_PREFIX}/include
      COMMAND cd <SOURCE_DIR>/build_release &&
      sh -c "tar cf - libpsm2.* | (cd ${CMAKE_INSTALL_PREFIX}/lib && tar xf - )"
      COMMAND cp <SOURCE_DIR>/psm2.h <SOURCE_DIR>/psm2_mq.h
                                     <SOURCE_DIR>/psm2_am.h
                                       ${CMAKE_INSTALL_PREFIX}/include
    UPDATE_COMMAND "")

endif (NOT TARGET psm2)
