# ----------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# ----------------------------------------------------------------------------

if(hcomm_FOUND)
    message(STATUS "Package hcomm has been found.")
    return()
endif()

set(_cmake_targets_defined "")
set(_cmake_targets_not_defined "")
set(_cmake_expected_targets "")
foreach(_cmake_expected_target IN ITEMS hcomm hcomm_headers)
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

find_path(_CANN_HCOMM_INCLUDE_DIR "hccl/hccl_comm.h"
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

find_path(_CANN_HCOMM_PKG_INCLUDE_DIR "hccl/base.h"
    PATH_SUFFIXES pkg_inc
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

find_library(_CANN_HCOMM_SHARED_LIBRARY
    NAMES libhcomm.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(hcomm
    FOUND_VAR
        hcomm_FOUND
    REQUIRED_VARS
        _CANN_HCOMM_INCLUDE_DIR
        _CANN_HCOMM_PKG_INCLUDE_DIR
        _CANN_HCOMM_SHARED_LIBRARY
)

if(hcomm_FOUND)
    # hcomm 库
    if(NOT TARGET hcomm)
        add_library(hcomm SHARED IMPORTED)
        set_target_properties(hcomm PROPERTIES
            INTERFACE_LINK_LIBRARIES "hcomm_headers"
            IMPORTED_LINK_DEPENDENT_LIBRARIES "c_sec;slog;mmpa;runtime;tsdclient;error_manager"
            IMPORTED_LOCATION "${_CANN_HCOMM_SHARED_LIBRARY}"
        )
    endif()

    # headers 头文件搜索路径
    if(NOT TARGET hcomm_headers)
        set(_INCLUDE_DIRS
            "${_CANN_HCOMM_INCLUDE_DIR}"
            "${_CANN_HCOMM_INCLUDE_DIR}/hccl"
            "${_CANN_HCOMM_PKG_INCLUDE_DIR}"
            "${_CANN_HCOMM_PKG_INCLUDE_DIR}/hccl"
        )
        if(EXISTS ${_CANN_HCOMM_INCLUDE_DIR}/hcomm)
            list(APPEND _INCLUDE_DIRS "${_CANN_HCOMM_INCLUDE_DIR}/hcomm")
        endif()
        if(EXISTS ${_CANN_HCOMM_INCLUDE_DIR}/hcomm/ccu)
            list(APPEND _INCLUDE_DIRS "${_CANN_HCOMM_INCLUDE_DIR}/hcomm/ccu")
        endif()
        if(EXISTS ${_CANN_HCOMM_PKG_INCLUDE_DIR}/hcomm)
            list(APPEND _INCLUDE_DIRS "${_CANN_HCOMM_PKG_INCLUDE_DIR}/hcomm")
        endif()
        if(EXISTS ${_CANN_HCOMM_PKG_INCLUDE_DIR}/hcomm/ccu)
            list(APPEND _INCLUDE_DIRS "${_CANN_HCOMM_PKG_INCLUDE_DIR}/hcomm/ccu")
        endif()
        
        add_library(hcomm_headers INTERFACE IMPORTED)
        set_target_properties(hcomm_headers PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${_INCLUDE_DIRS}"
        )
    endif()

    include(CMakePrintHelpers)
    cmake_print_properties(TARGETS hcomm
        PROPERTIES INTERFACE_LINK_LIBRARIES IMPORTED_LINK_DEPENDENT_LIBRARIES IMPORTED_LOCATION
    )
    cmake_print_properties(TARGETS hcomm_headers
        PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
    )
endif()