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

find_path(_CANN_GRAPH_INCLUDE_DIR
    NAMES graph/graph.h
    PATH_SUFFIXES include
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(_CANN_graph_SHARED_LIBRARY
    NAMES libgraph.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(_CANN_graph_base_SHARED_LIBRARY
    NAMES libgraph_base.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(_CANN_register_SHARED_LIBRARY
    NAMES libregister.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(graph
    FOUND_VAR
        graph_FOUND
    REQUIRED_VARS
        _CANN_GRAPH_INCLUDE_DIR
        _CANN_graph_SHARED_LIBRARY
        _CANN_graph_base_SHARED_LIBRARY
        _CANN_register_SHARED_LIBRARY
)

if(graph_FOUND)
    add_library(graph_headers INTERFACE IMPORTED)
    set_target_properties(graph_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES
            "${_CANN_GRAPH_INCLUDE_DIR};${_CANN_GRAPH_INCLUDE_DIR}/transformer/"
    )

    add_library(graph SHARED IMPORTED)
    set_target_properties(graph PROPERTIES
        INTERFACE_LINK_LIBRARIES "graph_headers"
        IMPORTED_LOCATION "${_CANN_graph_SHARED_LIBRARY}"
    )

    add_library(graph_base SHARED IMPORTED)
    set_target_properties(graph_base PROPERTIES
        INTERFACE_LINK_LIBRARIES "graph_headers"
        IMPORTED_LOCATION "${_CANN_graph_base_SHARED_LIBRARY}"
    )

    add_library(register SHARED IMPORTED)
    set_target_properties(register PROPERTIES
        IMPORTED_LOCATION "${_CANN_register_SHARED_LIBRARY}"
    )
endif()
