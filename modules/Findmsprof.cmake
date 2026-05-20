# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of 
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if (msprof_FOUND)
    message(STATUS "Package msprof has been found.")
    return()
endif()

set(_cmake_targets_defined "")
set(_cmake_targets_not_defined "")
set(_cmake_expected_targets "")
foreach(_cmake_expected_target IN ITEMS msprofiler_fwk_share profapi profapi_share profimpl msprof_headers)
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

find_path(_CANN_MSPROF_INCLUDE_DIR
    NAMES profiling/aprof_pub.h
    PATH_SUFFIXES pkg_inc
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(_CANN_MSPROFILER_SHARED_LIBRARY
    NAMES libmsprofiler.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(_CANN_PROFAPI_SHARED_LIBRARY
    NAMES libprofapi.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(_CANN_PROFIMPL_SHARED_LIBRARY
    NAMES libprofimpl.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(msprof
    FOUND_VAR
        msprof_FOUND
    REQUIRED_VARS
        _CANN_MSPROF_INCLUDE_DIR
        _CANN_MSPROFILER_SHARED_LIBRARY
        _CANN_PROFAPI_SHARED_LIBRARY
        _CANN_PROFIMPL_SHARED_LIBRARY
)

if(msprof_FOUND)
    add_library(msprofiler_fwk_share SHARED IMPORTED)
    set_target_properties(msprofiler_fwk_share PROPERTIES
        INTERFACE_LINK_LIBRARIES "msprof_headers"
        IMPORTED_LOCATION "${_CANN_MSPROFILER_SHARED_LIBRARY}"
    )
    # cmake 3.16 does not support ALIAS IMPLIED target
    add_library(msprofiler SHARED IMPORTED)
    set_target_properties(msprofiler PROPERTIES
        INTERFACE_LINK_LIBRARIES "msprof_headers"
        IMPORTED_LOCATION "${_CANN_MSPROFILER_SHARED_LIBRARY}"
    )

    add_library(profapi_share SHARED IMPORTED)
    set_target_properties(profapi_share PROPERTIES
        INTERFACE_LINK_LIBRARIES "msprof_headers"
        IMPORTED_LOCATION "${_CANN_PROFAPI_SHARED_LIBRARY}"
    )
    # cmake 3.16 does not support ALIAS IMPLIED target
    add_library(profapi SHARED IMPORTED)
    set_target_properties(profapi PROPERTIES
        INTERFACE_LINK_LIBRARIES "msprof_headers"
        IMPORTED_LOCATION "${_CANN_PROFAPI_SHARED_LIBRARY}"
    )

    add_library(profimpl SHARED IMPORTED)
    set_target_properties(profimpl PROPERTIES
        INTERFACE_LINK_LIBRARIES "msprof_headers"
        IMPORTED_LOCATION "${_CANN_PROFIMPL_SHARED_LIBRARY}"
    )

    add_library(msprof_headers INTERFACE IMPORTED)
    set_target_properties(msprof_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_CANN_MSPROF_INCLUDE_DIR};${_CANN_MSPROF_INCLUDE_DIR}/profiling;${_CANN_MSPROF_INCLUDE_DIR}/toolchain"
    )
endif()
