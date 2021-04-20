#
# keyutils.cmake  umbrella for utils for linux kernel key management system
# 19-Apr-2021  chuck@ece.cmu.edu
#

#
# config:
#  KEYUTILS_REPO - url of git repository
#  KEYUTILS_TAG  - tag to checkout of git
#  KEYUTILS_TAR  - cache tar file name (default should be ok)
#

if (NOT TARGET keyutils)

#
# umbrella option variables
#
umbrella_defineopt (KEYUTILS_REPO 
    "https://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils.git"
    STRING "KEYUTILS GIT repository")
umbrella_defineopt (KEYUTILS_TAG "master" STRING "KEYUTILS GIT tag")
umbrella_defineopt (KEYUTILS_TAR "keyutils-${KEYUTILS_TAG}.tar.gz" 
    STRING "KEYUTILS cache tar file")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_download (KEYUTILS_DOWNLOAD keyutils ${KEYUTILS_TAR}
                   GIT_REPOSITORY ${KEYUTILS_REPO}
                   GIT_TAG ${KEYUTILS_TAG})
umbrella_patchcheck (KEYUTILS_PATCHCMD keyutils)

#
# settings to make the Makefile do the correct thing for us.
# have to hack -I. back into CPPFLAGS...
#
set(keyutils-cppflags "${UMBRELLA_CPPFLAGS} -I.")
set(keyutil-makeargs ${UMBRELLA_COMP} ${keyutils-cppflags} ${UMBRELLA_LDFLAGS}
    DESTDIR=${CMAKE_INSTALL_PREFIX} LIBDIR=/lib
    MANDIR=/share/man SHAREDIR=/share/keyutils INCLUDEDIR=/include)

#
# create keyutils target
#
ExternalProject_Add (keyutils ${KEYUTILS_DOWNLOAD} ${KEYUTILS_PATCHCMD}
    BUILD_IN_SOURCE 1      # old school makefiles

    #
    # XXX: fix install bug in Makefile for making libkeyutils.so sym link
    # XXX: had quoting issues with trying to put the sed expression on
    # XXX: the COMMAND line.   put it in keyutils.sed to work around the
    # XXX: issue...  there's prob a better way to do this.
    #
    CONFIGURE_COMMAND cp ${UMBRELLA_PREFIX}/umbrella/keyutils.sed <SOURCE_DIR>
    COMMAND cp <SOURCE_DIR>/Makefile <SOURCE_DIR>/Makefile.orig
    COMMAND cd <SOURCE_DIR> && sed -f keyutils.sed  Makefile > Makefile.new
    COMMAND cp <SOURCE_DIR>/Makefile.new <SOURCE_DIR>/Makefile

    BUILD_COMMAND make ${keyutil-makeargs}
    INSTALL_COMMAND make ${keyutil-makeargs} install
    UPDATE_COMMAND "")

endif (NOT TARGET keyutils)
