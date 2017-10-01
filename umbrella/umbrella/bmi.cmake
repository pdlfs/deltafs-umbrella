#
# bmi.cmake  umbrella for BMI communications package
# 27-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  BMI_REPO - url of git repository
#  BMI_TAG  - tag to checkout of git
#  BMI_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET bmi)

#
# umbrella option variables
#
umbrella_defineopt (BMI_REPO "http://git.mcs.anl.gov/bmi.git"
                    STRING "BMI GIT repository")
umbrella_defineopt (BMI_TAG "master" STRING "BMI GIT tag")
umbrella_defineopt (BMI_TAR "bmi-${BMI_TAG}.tar.gz" STRING "BMI cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (BMI_DOWNLOAD bmi ${BMI_TAR}
                   GIT_REPOSITORY ${BMI_REPO}
                   GIT_TAG ${BMI_TAG})
umbrella_patchcheck (BMI_PATCHCMD bmi)

#
# create bmi target
#
ExternalProject_Add (bmi ${BMI_DOWNLOAD} ${BMI_PATCHCMD}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure ${UMBRELLA_COMP}
                      ${UMBRELLA_CPPFLAGS} ${UMBRELLA_LDFLAG}
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      --enable-shared --enable-bmi-only
    UPDATE_COMMAND "")

#
# add extra autogen prepare step
#
ExternalProject_Add_Step (bmi prepare
    COMMAND ${UMBRELLA_PREFIX}/ensure-autogen <SOURCE_DIR>/prepare
    COMMENT "preparing source for configure"
    DEPENDEES update
    DEPENDERS configure
    WORKING_DIRECTORY <SOURCE_DIR>)

endif (NOT TARGET bmi)
