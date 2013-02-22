# Based on FindProtobuffer.cmake from cmake 2.8.10

# TODO: description
# TODO: license

# PROTOBUF_SRC_ROOT_FOLDER
# NANOPB_SRC_ROOT_FOLDER
# NANOPB_IMPORT_DIRS
# NANOPB_GENERATE_CPP_APPEND_PATH

# NANOPB_INCLUDE_DIRS
#


function(NANOPB_GENERATE_CPP SRCS HDRS)
  if(NOT ARGN)
    return()
  endif()

  if(NANOPB_GENERATE_CPP_APPEND_PATH)
    # Create an include path for each file specified
    foreach(FIL ${ARGN})
      get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
      get_filename_component(ABS_PATH ${ABS_FIL} PATH)

      list(FIND _nanobp_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _nanobp_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  else()
    set(_nanobp_include_path -I ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  if(DEFINED NANOPB_IMPORT_DIRS)
    foreach(DIR ${NANOPB_IMPORT_DIRS})
      get_filename_component(ABS_PATH ${DIR} ABSOLUTE)
      list(FIND _nanobp_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _nanobp_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  endif()

  set(${SRCS})
  set(${HDRS})
  get_filename_component(GENERATOR_PATH ${NANOPB_GENERATOR_EXECUTABLE} PATH)

  foreach(FIL ${ARGN})
    get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
    get_filename_component(FIL_WE ${FIL} NAME_WE)

    list(APPEND ${SRCS} "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.c")
    list(APPEND ${HDRS} "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.h")

    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb"
      COMMAND  ${PROTOBUF_PROTOC_EXECUTABLE}
      ARGS -I${GENERATOR_PATH} -I${CMAKE_CURRENT_BINARY_DIR} ${_nanobp_include_path} -o${FIL_WE}.pb ${ABS_FIL}
      DEPENDS ${ABS_FIL}
      COMMENT "Running C++ protocol buffer compiler on ${FIL}"
      VERBATIM )

    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.c"
             "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.h"
      COMMAND python
      ARGS ${NANOPB_GENERATOR_EXECUTABLE} ${FIL_WE}.pb
      DEPENDS ${FIL_WE}.pb
      COMMENT "Running nanopb generator on ${FIL_WE}.pb"
      VERBATIM )
  endforeach()

  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} ${NANOPB_SRCS} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} ${NANOPB_HDRS} PARENT_SCOPE)

endfunction()



#
# Main.
#

# By default have NANOPB_GENERATE_CPP macro pass -I to protoc
# for each directory where a proto file is referenced.
if(NOT DEFINED NANOPB_GENERATE_CPP_APPEND_PATH)
  set(NANOPB_GENERATE_CPP_APPEND_PATH TRUE)
endif()

# Find the include directory
find_path(NANOPB_INCLUDE_DIRS
    pb.h
    PATHS ${NANOPB_SRC_ROOT_FOLDER}
)
mark_as_advanced(NANOPB_INCLUDE_DIRS)

# Find nanopb source files
set(NANOPB_SRCS)
set(NANOPB_HDRS)
list(APPEND _nanopb_srcs pb_decode.c pb_encode.c)
list(APPEND _nanopb_hdrs pb_decode.h pb_encode.h pb.h)

foreach(FIL ${_nanopb_srcs})
  find_file(${FIL}__nano_pb_file NAMES ${FIL} PATHS ${NANOPB_SRC_ROOT_FOLDER} ${NANOPB_INCLUDE_DIRS})
  list(APPEND NANOPB_SRCS "${${FIL}__nano_pb_file}")
  mark_as_advanced(${FIL}__nano_pb_file)
endforeach()

foreach(FIL ${_nanopb_hdrs})
  find_file(${FIL}__nano_pb_file NAMES ${FIL} PATHS ${NANOPB_INCLUDE_DIRS})
  mark_as_advanced(${FIL}__nano_pb_file)
  list(APPEND NANOPB_HDRS "${${FIL}__nano_pb_file}")
endforeach()

# Find the protoc Executable
find_program(PROTOBUF_PROTOC_EXECUTABLE
    NAMES protoc
    DOC "The Google Protocol Buffers Compiler"
    PATHS
    ${PROTOBUF_SRC_ROOT_FOLDER}/vsprojects/Release
    ${PROTOBUF_SRC_ROOT_FOLDER}/vsprojects/Debug
)
mark_as_advanced(PROTOBUF_PROTOC_EXECUTABLE)

# Find nanopb generator
find_file(NANOPB_GENERATOR_EXECUTABLE
    NAMES nanopb_generator.py
    DOC "nanopb generator"
    PATHS
    ${NANOPB_SRC_ROOT_FOLDER}/generator
)
mark_as_advanced(NANOPB_GENERATOR_EXECUTABLE)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(NANOPB DEFAULT_MSG
  NANOPB_INCLUDE_DIRS
  NANOPB_SRCS NANOPB_HDRS
  NANOPB_GENERATOR_EXECUTABLE
  PROTOBUF_PROTOC_EXECUTABLE
  )
