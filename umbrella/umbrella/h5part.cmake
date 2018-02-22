#
# h5part.cmake  umbrella for h5part package
# 22-Feb-2018  chuck@ece.cmu.edu
#

#
# config:
#  H5PART_BASEURL - base url of h5part
#  H5PART_URLFILE - tar file within urldir
#  H5PART_URLMD5  - md5 of tar file
#

if (NOT TARGET h5part)

#
# umbrella option variables
#
umbrella_defineopt (H5PART_BASEURL
    "https://codeforge.lbl.gov/frs/download.php/file/387"
    STRING "base url for h5part")
umbrella_defineopt (H5PART_URLFILE "H5Part-1.6.6.tar.gz"
    STRING "h5part tar file name")
umbrella_defineopt (H5PART_URLMD5 "327c63d198e38a12565b74cffdf1f9d7"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (H5PART_DOWNLOAD h5part ${H5PART_URLFILE}
    URL "${H5PART_BASEURL}/${H5PART_URLFILE}"
    URL_MD5 ${H5PART_URLMD5})
umbrella_patchcheck (H5PART_PATCHCMD h5part)

# requirements
include (umbrella/hdf5)

#
# create h5part target
#
ExternalProject_Add (h5part DEPENDS hdf5
    ${H5PART_DOWNLOAD} ${H5PART_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --enable-shared
                      --with-hdf5=${CMAKE_INSTALL_PREFIX}
                      --prefix=${CMAKE_INSTALL_PREFIX}
    BUILD_IN_SOURCE 1
    UPDATE_COMMAND "")

endif (NOT TARGET h5part)
