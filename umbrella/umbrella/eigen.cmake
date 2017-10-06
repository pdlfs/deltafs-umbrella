#
# eigen.cmake  umbrella for eigen linear algebra package
# 05-Oct-2017  chuck@ece.cmu.edu
#

#
# config:
#  EIGEN_REPO    - url of git repository
#  EIGEN_TAG     - tag to checkout of hg
#  EIGEN_URL     - URL of source tar file
#  EIGEN_URL_MD5 - MD5 of above
#  EIGEN_USEURL  - off=use git repo, on=use url instead
#  EIGEN_TAR     - cache tar file name (default should be ok)
#


if (NOT TARGET eigen)

#
# umbrella option variables
#
umbrella_defineopt (EIGEN_REPO "https://bitbucket.org/eigen/eigen"
                    STRING "EIGEN HG repository")
umbrella_defineopt (EIGEN_TAG "tip" STRING "EIGEN HG tag")

umbrella_defineopt (EIGEN_URL
     "http://bitbucket.org/eigen/eigen/get/3.3.4.tar.gz"
     STRING "EIGEN release download URL")
umbrella_defineopt (EIGEN_URL_MD5 "1a47e78efe365a97de0c022d127607c3"
     STRING "EIGEN download URL md5")

# not everyone has mercurial hg installed, so use URL by default
umbrella_defineopt (EIGEN_USEURL "ON" BOOLEAN "Use URL to download EIGEN")

umbrella_defineopt (EIGEN_TAR "eigen-${EIGEN_TAG}.tar.gz" 
    STRING "EIGEN cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
if (EIGEN_USEURL)
    set (EIGEN_FETCH URL ${EIGEN_URL} URL_MD5 ${EIGEN_URL_MD5} TIMEOUT 100)
else ()
    set (EIGEN_FETCH HG_REPOSITORY ${EIGEN_REPO} HG_TAG ${EIGEN_TAG})
endif ()

umbrella_download (EIGEN_DOWNLOAD eigen ${EIGEN_TAR} ${EIGEN_FETCH})
umbrella_patchcheck (EIGEN_PATCHCMD eigen)

#
# create eigen target
#
ExternalProject_Add (eigen ${EIGEN_DOWNLOAD} ${EIGEN_PATCHCMD}
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND "")

endif (NOT TARGET eigen)
