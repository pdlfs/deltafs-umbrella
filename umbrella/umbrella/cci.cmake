#
# cci.cmake  umbrella for CCI communications package
# 28-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  CCI_REPO    - url of git repository
#  CCI_TAG     - tag to checkout of git
#  CCI_URL     - URL of source tar file
#  CCI_URL_MD5 - MD5 of above
#  CCI_USEURL  - off=use git repo, on=use url instead
#  CCI_TAR     - cache tar file name (default should be ok)
#
#  CCI_GNI        - set true to compile GNI plugin
#  CCI_GNI_PREFIX - GNI prefix dir (optional)
#  CCI_GNI_LIBDIR - GNI libdir (optional)
#
#  CCI_VERBS        - set true to compile VERBS plugin
#  CCI_VERBS_PREFIX - VERBS prefix dir (optional)
#  CCI_VERBS_LIBDIR -  VERBS libdir (optional)
#


if (NOT TARGET cci)

#
# umbrella option variables
#
umbrella_defineopt (CCI_REPO "https://github.com/CCI/cci"
                    STRING "CCI GIT repository")
umbrella_defineopt (CCI_TAG "master" STRING "CCI GIT tag")

umbrella_defineopt (CCI_URL
     "http://cci-forum.com/wp-content/uploads/2016/06/cci-2.0.tar.gz"
     STRING "CCI release download URL")
umbrella_defineopt (CCI_URL_MD5 "070b2ba4eca92a846c093f2cd000d3b2"
     STRING "CCI download URL md5")

umbrella_defineopt (CCI_USEURL "OFF" BOOLEAN "Use URL to download CCI")

umbrella_defineopt (CCI_TAR "cci-${CCI_TAG}.tar.gz" STRING "CCI cache tar file")

umbrella_defineopt (CCI_GNI "OFF" BOOLEAN "Enable GNI backend in CCI")
umbrella_defineopt (CCI_GNI_PREFIX "" STRING "GNI prefix for CCI")
umbrella_defineopt (CCI_GNI_LIBDIR "" STRING "GNI libdir flag for CCI")

umbrella_defineopt (CCI_VERBS "OFF" BOOLEAN "Enable verbs backend in CCI")
umbrella_defineopt (CCI_VERBS_PREFIX "" STRING "verbs prefix for CCI")
umbrella_defineopt (CCI_VERBS_LIBDIR "" STRING "verbs libdir flag for CCI")

#
# build extra autoconfig flags
#
if (CCI_GNI)
    if ("${CCI_GNI_PREFIX}" STREQUAL "")
        set (CCI_GNIAC "--with-gni")
    else ()
        set (CCI_GNIAC "--with-gni=${CCI_GNI_PREFIX}")
    endif ()
    if (NOT "${CCI_GNI_LIBDIR}" STREQUAL "")
        set (CCI_GNIAC "${CCI_GNIAC} --with-gni-libdir=${CCI_GNI_LIBDIR}")
    endif ()
else ()
    set (CCI_GNIAC "--without-gni")
endif ()

if (CCI_VERBS)
    if ("${CCI_VERBS_PREFIX}" STREQUAL "")
        set (CCI_VERBSAC "--with-verbs")
    else ()
        set (CCI_VERBSAC "--with-verbs=${CCI_VERBS_PREFIX}")
    endif ()
    if (NOT "${CCI_VERBS_LIBDIR}" STREQUAL "")
        set (CCI_VERBSAC
               "${CCI_VERBSAC} --with-verbs-libdir=${CCI_VERBS_LIBDIR}")
    endif ()
else ()
    set (CCI_VERBSAC "--without-verbs")
endif ()

message (STATUS "  CCI transport config: ${CCI_GNIAC} ${CCI_VERBSAC}")

#
# generate parts of the ExternalProject_Add args...
#
if (CCI_USEURL)
    set (CCI_FETCH URL ${CCI_URL} URL_MD5 ${CCI_URL_MD5} TIMEOUT 100)
else ()
    set (CCI_FETCH GIT_REPOSITORY ${CCI_REPO} GIT_TAG ${CCI_TAG})
endif ()

umbrella_download (CCI_DOWNLOAD cci ${CCI_TAR} ${CCI_FETCH})
umbrella_patchcheck (CCI_PATCHCMD cci)

#
# create cci target
#
ExternalProject_Add (cci ${CCI_DOWNLOAD} ${CCI_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      ${CCI_GNIAC} ${CCI_VERBSAC}
                      UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (cci prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/autogen.pl
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET cci)
