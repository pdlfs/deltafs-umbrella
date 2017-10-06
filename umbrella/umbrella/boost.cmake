#
# boost.cmake  umbrella for the massive boost package
# 01-Oct-2017  chuck@ece.cmu.edu
#

#
# boost is big.  really big.  massive.  you really don't want
# to git clone this because it takes _forever_ to clone all
# the submodules.  let's just get a tar file, but be warned
# that even unpacking that is going to take ages.
#

#
# config:
#  BOOST_BASEURL - base url of boost
#  BOOST_URLDIR  - subdir in base where util-linux lives
#  BOOST_URLFILE - tar file within urldir
#  BOOST_URLMD5  - md5 of tar file
#

if (NOT TARGET boost)

#
# umbrella option variables
#
umbrella_defineopt (BOOST_BASEURL
    "https://dl.bintray.com/boostorg/release" STRING "base url for boost")
umbrella_defineopt (BOOST_URLDIR "1.65.1/source" STRING "boost subdir")
umbrella_defineopt (BOOST_URLFILE "boost_1_65_1.tar.gz"
    STRING "boost tar file name")
umbrella_defineopt (BOOST_URLMD5 "ee64fd29a3fe42232c6ac3c419e523cf"
    STRING "MD5 of tar file")

umbrella_defineopt (BOOST_WITHLIBS "system,thread,date_time,program_options"
    STRING "boost --with-libraries bootstrap.sh flag")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (BOOST_DOWNLOAD boost ${BOOST_URLFILE}
    URL "${BOOST_BASEURL}/${BOOST_URLDIR}/${BOOST_URLFILE}"
    URL_MD5 ${BOOST_URLMD5})
umbrella_patchcheck (BOOST_PATCHCMD boost)

#
# create boost target
#
ExternalProject_Add (boost ${BOOST_DOWNLOAD} ${BOOST_PATCHCMD}
    CONFIGURE_COMMAND cd <SOURCE_DIR> && 
        ${UMBRELLA_COMP} ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
          ./bootstrap.sh --with-libraries=${BOOST_WITHLIBS}
                       --prefix=${CMAKE_INSTALL_PREFIX}
    BUILD_COMMAND cd <SOURCE_DIR> && 
        ./b2 --prefix=${CMAKE_INSTALL_PREFIX} --build-dir=<BINARY_DIR> install
    INSTALL_COMMAND true
    UPDATE_COMMAND "")

endif (NOT TARGET boost)
