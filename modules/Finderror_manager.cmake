# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of 
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------
if (error_manager_FOUND)
    message(STATUS "Package error_manager has been found.")
    return()
endif()

set(_cmake_targets_defined "")
set(_cmake_targets_not_defined "")
set(_cmake_expected_targets "")
foreach(_cmake_expected_target IN ITEMS error_manager stub_error_manager)
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

string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" _ARCH_LOW)
if (_ARCH_LOW MATCHES "x86_64|amd64")
    message(STATUS "Detected architecture: x86_64")
    set(TARGET_ARCH x86_64)
elseif (_ARCH_LOW MATCHES "aarch64|arm64|arm")
    message(STATUS "Detected architecture: aarch64")
    set(TARGET_ARCH aarch64)
else ()
    message(WARNING "Unknown architecture: ${CMAKE_SYSTEM_PROCESSOR}")
endif ()

find_path(ERROR_MANAGER_INCLUDE_DIR
    NAMES base/err_msg.h
    PATH_SUFFIXES include
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

find_library(ERROR_MANAGER_SHARED_LIBRARY
    NAMES liberror_manager.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

find_library(STUB_ERROR_MANAGER_SHARED_LIBRARY
        NAMES liberror_manager.so
        PATHS "${ASCEND_INSTALL_PATH}/devlib/linux/${TARGET_ARCH}"
        NO_CMAKE_SYSTEM_PATH
        NO_CMAKE_FIND_ROOT_PATH
)

include(CMakePrintHelpers)
message(STATUS "Variables ERROR_MANAGER_SHARED_LIBRARY in error_manager module: ${ERROR_MANAGER_SHARED_LIBRARY}")
message(STATUS "Variables STUB_ERROR_MANAGER_SHARED_LIBRARY in error_manager module: ${STUB_ERROR_MANAGER_SHARED_LIBRARY}")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(error_manager
    FOUND_VAR
        error_manager_FOUND
    REQUIRED_VARS
        ERROR_MANAGER_INCLUDE_DIR
        ERROR_MANAGER_SHARED_LIBRARY
)

if(error_manager_FOUND)
    add_library(error_manager_headers INTERFACE IMPORTED)
    set_target_properties(error_manager_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${ERROR_MANAGER_INCLUDE_DIR}"
    )

    add_library(error_manager SHARED IMPORTED)
    set_target_properties(error_manager PROPERTIES
        IMPORTED_LOCATION "${ERROR_MANAGER_SHARED_LIBRARY}"
        INTERFACE_LINK_LIBRARIES "error_manager_headers"
    )

    add_library(stub_error_manager SHARED IMPORTED)
    set_target_properties(stub_error_manager PROPERTIES
            IMPORTED_LOCATION "${STUB_ERROR_MANAGER_SHARED_LIBRARY}"
    )

    cmake_print_properties(TARGETS error_manager
            PROPERTIES IMPORTED_LOCATION
    )
    cmake_print_properties(TARGETS stub_error_manager
            PROPERTIES IMPORTED_LOCATION
    )
else ()
    message(FATAL_ERROR "error_manager shared library not found")
endif()