#
# rdma-core.cmake  umbrella for linux rdma core package
# 16-Jul-2020  chuck@ece.cmu.edu
#

#
# config:
#  RDMA_CORE_REPO - url of git repository
#  RDMA_CORE_TAG  - tag to checkout of git
#  RDMA_CORE_TAR  - cache tar file name (default should be ok)
#
# including this file always creates an rdma-core target
#
#  UMBRELLA_BUILD_RDMALIBS:
#   -  ON: we build and install RDMA libs ourselves
#   - OFF: the user must provide the RDMA libs, we will check for them(default)
#
# in addition, by convention, packages that can build with or without
# rdma-core have the option of sharing the following defineopt to
# conditionally include rdma-core:
#
#  UMBRELLA_REQUIRE_RDMALIBS:   (shared by other files, not used by us)
#   -  ON: include rmda-core
#   - OFF: RDMA libs are optional (use if there), no rdma-core target provided
#
# use something like this:
# umbrella_defineopt (UMBRELLA_REQUIRE_RDMALIBS "OFF" BOOL
#                    "Require RDMA libraries")
#

umbrella_defineopt (UMBRELLA_BUILD_RDMALIBS "OFF" BOOL
                    "Build required RDMA libraries")

if (NOT TARGET rdma-core)

#
# umbrella option variables
#
umbrella_defineopt (RDMA_CORE_REPO "https://github.com/linux-rdma/rdma-core"
                    STRING "RDMA_CORE GIT repository")
umbrella_defineopt (RDMA_CORE_TAG "master" STRING "RDMA_CORE GIT tag")
umbrella_defineopt (RDMA_CORE_TAR "rdma-core-${RDMA_CORE_TAG}.tar.gz"
                                STRING "RDMA_CORE cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (RDMA_CORE_DOWNLOAD rdma-core ${RDMA_CORE_TAR}
                   GIT_REPOSITORY ${RDMA_CORE_REPO}
                   GIT_TAG ${RDMA_CORE_TAG})
umbrella_patchcheck (RDMA_CORE_PATCHCMD rdma-core)

if (UMBRELLA_BUILD_RDMALIBS)
    #
    # depends
    #
    include (umbrella/libnl)

    #
    # rdma-core uses GNUInstallDirs.cmake.   that sometimes picks
    # $prefix/lib64 for lib installs, but that isn't something that
    # we need for umbrella builds.  ensure it is switched off by
    # setting DCMAKE_INSTALL_LIBDIR to $prefix/lib
    #
    # building rdma man pages from git requires rst2man and pandoc.
    # XXX: rather than add extra depends on those, just switch man
    # pages off for now.
    #
    set (RDMA_CORE_CMAKECACHE ${UMBRELLA_CMAKECACHE}
         -DCMAKE_INSTALL_LIBDIR:STRING=${CMAKE_INSTALL_PREFIX}/lib
         -DNO_MAN_PAGES:BOOL=on)

    #
    # create rdma-core target
    # XXX: needs PKG_CONFIG_USE_CMAKE_PREFIX_PATH because they use cmake 2.8
    # XXX: need to add "-L" and RPATH workarounds
    #
    ExternalProject_Add (rdma-core DEPENDS libnl
        ${RDMA_CORE_DOWNLOAD} ${RDMA_CORE_PATCHCMD}
        CMAKE_ARGS -DBUILD_SHARED_LIBS=ON -DPKG_CONFIG_USE_CMAKE_PREFIX_PATH=YES
        CMAKE_CACHE_ARGS ${RDMA_CORE_CMAKECACHE}
        UPDATE_COMMAND ""
    )

else ()

    include (FindPackageHandleStandardArgs)
    find_path(RDMACM_INC rdma/rdma_cma.h)
    find_library(RDMACM_LIB rdmacm)
    find_package_handle_standard_args (RDMACM DEFAULT_MSG
                                       RDMACM_INC RDMACM_LIB)
    find_path(IBUMAD_INC infiniband/umad.h)
    find_library(IBUMAD_LIB ibumad)
    find_package_handle_standard_args (IBUMAD DEFAULT_MSG
                                       IBUMAD_INC IBUMAD_LIB)
    find_path(IBVERBS_INC infiniband/verbs.h)
    find_library(IBVERBS_LIB ibverbs)
    find_package_handle_standard_args (IBVERBS DEFAULT_MSG
                                       IBVERBS_INC IBVERBS_LIB)

    if (NOT RDMACM_FOUND OR NOT IBUMAD_FOUND OR NOT IBVERBS_FOUND)
        message(FATAL_ERROR "

System provided RDMA libraries not found.  Either set UMBRELLA_BUILD_RDMALIBS
to build your own RDMA libraries, use the umbrella bootstrap to build RDMA
libraries, or use a package manager like apt or yum to install the missing
libraries.

")
    endif ()

    add_custom_target(rdma-core ALL
                      COMMAND ""
                      COMMENT "Using system provided RMA libraries")

endif ()

endif (NOT TARGET rdma-core)
