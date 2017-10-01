#
# trecon-reader.cmake  umbrella trecon-reader (lives in vpic)
# 29-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  TRECON_READER_VPICSRC - vpic source dir override
#

if (NOT TARGET trecon-reader)

#
# umbrella option variables
#
umbrella_defineopt (TRECON_READER_VPICSRC
     "${CMAKE_BINARY_DIR}/vpic-prefix/src/vpic"
     STRING "vpic source directory")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_patchcheck (TRECON_READER_PATCHCMD trecon-reader)

#
# depends
#
include (umbrella/vpic)

#
# create trecon-reader target
#
ExternalProject_Add (trecon-reader DEPENDS vpic
    DOWNLOAD_COMMAND true  # no need to download, comes with vpic
    ${TRECON_READER_PATCHCMD}
    SOURCE_DIR ${TRECON_READER_VPICSRC}/decks/trecon-reader
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET trecon-reader)
