#
# h5part.cmake  umbrella for h5part package
# 22-Feb-2018  chuck@ece.cmu.edu
#

#
# config:
#  H5PART_REPO    - url of git repository
#  H5PART_TAG     - tag to checkout of git
#  H5PART_BASEURL - base url of h5part
#  H5PART_URLFILE - tar file within urldir
#  H5PART_URLMD5  - md5 of tar file
#  H5PART_USEURL  - off=use git repo, on=use url instead
#  H5PART_TAR     - cache tar file name
#

if (NOT TARGET h5part)

#
# umbrella option variables
#
umbrella_defineopt (H5PART_REPO "git@dev.pdl.cmu.edu:deltavol/h5part"
    STRING "h5part GIT repository")
umbrella_defineopt (H5PART_TAG "master" STRING "h5part git tag")
umbrella_defineopt (H5PART_BASEURL
    "https://codeforge.lbl.gov/frs/download.php/file/387"
    STRING "base url for h5part")
umbrella_defineopt (H5PART_URLFILE "H5Part-1.6.6.tar.gz"
    STRING "h5part tar file name")
umbrella_defineopt (H5PART_URLMD5 "327c63d198e38a12565b74cffdf1f9d7"
    STRING "MD5 of tar file")

umbrella_defineopt (H5PART_USEURL "ON" BOOL "Use URL to download h5part")

umbrella_defineopt (H5PART_TAR "h5part-${H5PART_TAG}.tar.gz"
    STRING "h5part cache tar file")

if (H5PART_USEURL)
    set (H5PART_FETCH URL "${H5PART_BASEURL}/${H5PART_URLFILE}"
                      URL_MD5 ${H5PART_URLMD5} TIMEOUT 100)
else ()
    set (H5PART_FETCH GIT_REPOSITORY ${H5PART_REPO}
                      GIT_TAG ${H5PART_TAG})
endif ()

#
# build options -- we trigger off HDF5_ENABLE_PARALLEL
#
if (HDF5_ENABLE_PARALLEL)
    set (h5part-umb-comp ${UMBRELLA_MPICOMP})
    set (h5part-parallel-flag --enable-parallel)
else ()
    set (h5part-umb-comp ${UMBRELLA_COMP})
    set (h5part-parallel-flag --disable-parallel)
endif ()

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (H5PART_DOWNLOAD h5part ${H5PART_TAR} ${H5PART_FETCH})
umbrella_patchcheck (H5PART_PATCHCMD h5part)

# requirements
include (umbrella/hdf5)

#
# create h5part target
#
ExternalProject_Add (h5part DEPENDS hdf5
    ${H5PART_DOWNLOAD} ${H5PART_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${h5part-umb-comp}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAGS}
                      --enable-shared ${h5part-parallel-flag}
                      --with-hdf5=${CMAKE_INSTALL_PREFIX}
                      --prefix=${CMAKE_INSTALL_PREFIX}
    BUILD_IN_SOURCE 1
    UPDATE_COMMAND "")

endif (NOT TARGET h5part)
