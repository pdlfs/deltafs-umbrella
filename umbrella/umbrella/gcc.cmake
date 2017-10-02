#
# gcc.cmake  umbrella for gcc package
# 01-Oct-2017  chuck@ece.cmu.edu
#

# *** NOTE ** gcc requires these packages to be installed prior to compile:
# libgmp-dev
# libmpfr-dev
# libmpc-dev
#
# this gcc is designed for being compiled in our travis environment.
# see the pdlfs/prebuild-cache repository.
#

#
# config:
#  GCC_BASEURL - base url of gcc
#  GCC_URLDIR  - subdir in base where gcc lives
#  GCC_URLFILE - tar file within urldir
#  GCC_URLMD5  - md5 of tar file
#

if (NOT TARGET gcc)

#
# umbrella option variables
#
umbrella_defineopt (GCC_BASEURL
    "https://ftp.gnu.org/gnu/gcc" STRING "base url for gcc")
umbrella_defineopt (GCC_URLDIR "gcc-7.2.0" STRING "gcc subdir")
umbrella_defineopt (GCC_URLFILE "gcc-7.2.0.tar.gz"
    STRING "gcc tar file name")
umbrella_defineopt (GCC_URLMD5 "2e4be17c604ea555e0dff4a8f81ffe44"
    STRING "MD5 of tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (GCC_DOWNLOAD gcc ${GCC_URLFILE}
    URL "${GCC_BASEURL}/${GCC_URLDIR}/${GCC_URLFILE}"
    URL_MD5 ${GCC_URLMD5})
umbrella_patchcheck (GCC_PATCHCMD gcc)

#
# create gcc target -- this is fairly customized for our usage
#
ExternalProject_Add (gcc ${GCC_DOWNLOAD} ${GCC_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}/gcc
                      --disable-bootstrap --enable-languages=c,c++
                      --enable-shared --enable-threads=posix
                      --enable-checking=release --with-system-zlib
                      --enable-linker-build-id --with-linker-hash-style=gnu
                      --enable-initfini-array --disable-libgcj
                      --without-isl --enable-gnu-indirect-function
                      --with-tune=generic --disable-multilib
                      UPDATE_COMMAND "")

endif (NOT TARGET gcc)
