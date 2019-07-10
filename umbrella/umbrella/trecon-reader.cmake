#
# trecon-reader.cmake  umbrella trecon-reader (lives in vpic407)
# 29-Sep-2017  chuck@ece.cmu.edu
#

#
# config:
#  TRECON_READER_VPIC407SRC - vpic407 source dir override
#

if (NOT TARGET trecon-reader)

#
# umbrella option variables
#
umbrella_defineopt (TRECON_READER_VPIC407SRC
     "${CMAKE_BINARY_DIR}/vpic407-prefix/src/vpic407"
     STRING "vpic407 source directory")

#
# generate parts of the ExternalProject_Add args...
#
umbrella_patchcheck (TRECON_READER_PATCHCMD trecon-reader)

#
# depends
#
include (umbrella/vpic407)

#
# create trecon-reader target
#
ExternalProject_Add (trecon-reader DEPENDS vpic407
    DOWNLOAD_COMMAND true  # no need to download, comes with vpic407
    ${TRECON_READER_PATCHCMD}
    SOURCE_DIR ${TRECON_READER_VPIC407SRC}/decks/trecon-reader
    CMAKE_CACHE_ARGS ${UMBRELLA_CMAKECACHE}
    UPDATE_COMMAND ""
)

endif (NOT TARGET trecon-reader)
