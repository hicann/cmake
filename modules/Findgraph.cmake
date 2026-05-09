# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(graph_FOUND)
    message(STATUS "Package graph has been found.")
    return()
endif()

find_path(_GRAPH_INCLUDE_DIR
    NAMES graph/graph.h
    PATH_SUFFIXES include
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(graph_SHARED_LIBRARY
    NAMES libgraph.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(graph_base_SHARED_LIBRARY
    NAMES libgraph_base.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(graph
    FOUND_VAR
        graph_FOUND
    REQUIRED_VARS
        _GRAPH_INCLUDE_DIR
        graph_SHARED_LIBRARY
        graph_base_SHARED_LIBRARY
)

if(graph_FOUND)
    set(graph_INCLUDE_DIR "${_GRAPH_INCLUDE_DIR}")

    include(CMakePrintHelpers)
    message(STATUS "Variables in graph module:")
    cmake_print_variables(graph_INCLUDE_DIR)
    cmake_print_variables(graph_SHARED_LIBRARY)
    cmake_print_variables(graph_base_SHARED_LIBRARY)

    add_library(graph_headers INTERFACE IMPORTED)
    set_target_properties(graph_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES
            "${graph_INCLUDE_DIR};${graph_INCLUDE_DIR}/transformer/"
    )

    add_library(graph SHARED IMPORTED)
    set_target_properties(graph PROPERTIES
        INTERFACE_LINK_LIBRARIES "graph_headers"
        IMPORTED_LOCATION "${graph_SHARED_LIBRARY}"
    )

    add_library(graph_base SHARED IMPORTED)
    set_target_properties(graph_base PROPERTIES
        INTERFACE_LINK_LIBRARIES "graph_headers"
        IMPORTED_LOCATION "${graph_base_SHARED_LIBRARY}"
    )

    include(CMakePrintHelpers)
    cmake_print_properties(TARGETS graph_headers
        PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
    )
    cmake_print_properties(TARGETS graph graph_base
        PROPERTIES INTERFACE_LINK_LIBRARIES IMPORTED_LOCATION
    )
endif()

set(_GRAPH_INCLUDE_DIR)
set(graph_SHARED_LIBRARY)
set(graph_base_SHARED_LIBRARY)
