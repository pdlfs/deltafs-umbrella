#
# ofi.cmake  umbrella for OFI communications package
# 28-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  OFI_REPO - url of git repository
#  OFI_TAG  - tag to checkout of git
#  OFI_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET ofi)

#
# umbrella option variables
#
umbrella_defineopt (OFI_REPO "https://github.com/ofiwg/libfabric.git"
     STRING "OFI (libfabric) GIT repository")
umbrella_defineopt (OFI_TAG "master" STRING "OFI GIT tag")
umbrella_defineopt (OFI_TAR "ofi-${OFI_TAG}.tar.gz" STRING "OFI cache tar file")

umbrella_defineopt (UMBRELLA_REQUIRE_RDMALIBS "OFF" BOOL
                   "Require RDMA libraries")


#
# XXX: we are currently hardwiring extra stuff on the cray
# XXX: have to explicitly disable verbs on ANL theta or we get link errors
#
if ("${CMAKE_C_COMPILER_WRAPPER}" STREQUAL "CrayPrgEnv" AND
    NOT DEFINED OFI_CRAY_EXTRA)
    set (OFI_CRAY_EXTRA --enable-gni --enable-ugni-static --enable-sockets
         --disable-rxd --disable-rxm --disable-udp --disable-usnic
         --disable-verbs --with-kdreg=no)
endif ()

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (OFI_DOWNLOAD ofi ${OFI_TAR}
                   GIT_REPOSITORY ${OFI_REPO}
                   GIT_TAG ${OFI_TAG})
umbrella_patchcheck (OFI_PATCHCMD ofi)

if (UMBRELLA_REQUIRE_RDMALIBS)
    #
    # depends
    #
    include (umbrella/rdma-core)
    set (ofi_xtra DEPENDS rdma-core)
else ()
    unset (ofi_xtra)
endif()

#
# create ofi target
#
ExternalProject_Add (ofi ${ofi_xtra}
    ${OFI_DOWNLOAD} ${OFI_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      ${OFI_CRAY_EXTRA}
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (ofi prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.sh
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET ofi)
