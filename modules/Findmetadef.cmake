# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(metadef_FOUND)
    message(STATUS "Package metadef has been found.")
    return()
endif()

set(_cmake_targets_defined "")
set(_cmake_targets_not_defined "")
set(_cmake_expected_targets "")
foreach(_cmake_expected_target IN ITEMS exe_graph register metadef opp_registry metadef_headers exe_graph_headers)
    list(APPEND _cmake_expected_targets "${_cmake_expected_target}")
    if(TARGET "${_cmake_expected_target}")
        list(APPEND _cmake_targets_defined "${_cmake_expected_target}")
    else()
        list(APPEND _cmake_targets_not_defined "${_cmake_expected_target}")
    endif()
endforeach()
unset(_cmake_expected_target)

if(_cmake_targets_defined STREQUAL _cmake_expected_targets)
    unset(_cmake_targets_defined)
    unset(_cmake_targets_not_defined)
    unset(_cmake_expected_targets)
    unset(CMAKE_IMPORT_FILE_VERSION)
    cmake_policy(POP)
    return()
endif()

if(NOT _cmake_targets_defined STREQUAL "")
    string(REPLACE ";" ", " _cmake_targets_defined_text "${_cmake_targets_defined}")
    string(REPLACE ";" ", " _cmake_targets_not_defined_text "${_cmake_targets_not_defined}")
    message(FATAL_ERROR "Some (but not all) targets in this export set were already defined.\nTargets Defined: ${_cmake_targets_defined_text}\nTargets not yet defined: ${_cmake_targets_not_defined_text}\n")
endif()
unset(_cmake_targets_defined)
unset(_cmake_targets_not_defined)
unset(_cmake_expected_targets)

find_path(_INCLUDE_DIR
    NAMES graph/graph.h
    PATH_SUFFIXES include
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

get_filename_component(_ROOT_DIR "${_INCLUDE_DIR}" DIRECTORY)

find_path(_PKG_INC_DIR
    NAMES common/checker.h
    HINTS "${_ROOT_DIR}/pkg_inc"
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(exe_graph_SHARED_LIBRARY
    NAMES libexe_graph.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(register_SHARED_LIBRARY
    NAMES libregister.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(metadef_SHARED_LIBRARY
    NAMES libmetadef.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(opp_registry_SHARED_LIBRARY
    NAMES libopp_registry.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(metadef
    FOUND_VAR
        metadef_FOUND
    REQUIRED_VARS
        _INCLUDE_DIR
        _PKG_INC_DIR
        exe_graph_SHARED_LIBRARY
        register_SHARED_LIBRARY
        metadef_SHARED_LIBRARY
        opp_registry_SHARED_LIBRARY
)

if(metadef_FOUND)
    set(metadef_INCLUDE_DIR "${_INCLUDE_DIR}")
    set(metadef_PKG_INC_DIR "${_PKG_INC_DIR}")
    set(metadef_ROOT_DIR "${_ROOT_DIR}")

    include(CMakePrintHelpers)
    message(STATUS "Variables in metadef module:")
    cmake_print_variables(metadef_INCLUDE_DIR)
    cmake_print_variables(metadef_PKG_INC_DIR)
    cmake_print_variables(exe_graph_SHARED_LIBRARY)
    cmake_print_variables(register_SHARED_LIBRARY)
    cmake_print_variables(metadef_SHARED_LIBRARY)
    cmake_print_variables(opp_registry_SHARED_LIBRARY)

    add_library(metadef_headers INTERFACE IMPORTED)
    set_target_properties(metadef_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES
            "${metadef_PKG_INC_DIR};${metadef_PKG_INC_DIR}/base"
    )

    add_library(exe_graph_headers INTERFACE IMPORTED)
    set_target_properties(exe_graph_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES
            "${metadef_INCLUDE_DIR}/exe_graph"
    )

    add_library(exe_graph SHARED IMPORTED)
    set_target_properties(exe_graph PROPERTIES
        INTERFACE_LINK_LIBRARIES "exe_graph_headers"
        IMPORTED_LOCATION "${exe_graph_SHARED_LIBRARY}"
    )

    add_library(register SHARED IMPORTED)
    set_target_properties(register PROPERTIES
        IMPORTED_LOCATION "${register_SHARED_LIBRARY}"
    )

    add_library(metadef SHARED IMPORTED)
    set_target_properties(metadef PROPERTIES
        INTERFACE_LINK_LIBRARIES "metadef_headers"
        IMPORTED_LOCATION "${metadef_SHARED_LIBRARY}"
    )

    add_library(opp_registry SHARED IMPORTED)
    set_target_properties(opp_registry PROPERTIES
        IMPORTED_LOCATION "${opp_registry_SHARED_LIBRARY}"
    )

    include(CMakePrintHelpers)
    cmake_print_properties(TARGETS metadef_headers exe_graph_headers
        PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
    )
    
    cmake_print_properties(TARGETS exe_graph register metadef opp_registry
        PROPERTIES INTERFACE_LINK_LIBRARIES IMPORTED_LOCATION
    )
endif()

# Cleanup temporary variables.
set(_INCLUDE_DIR)
set(_PKG_INC_DIR)
set(_ROOT_DIR)
