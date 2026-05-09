# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(acl_rt_FOUND)
    message(STATUS "Package acl_rt has been found.")
    return()
endif()

find_path(_ACL_RT_INCLUDE_DIR
    NAMES acl/acl.h
    PATH_SUFFIXES include
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(acl_rt_SHARED_LIBRARY
    NAMES libacl_rt.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(acl_rt
    FOUND_VAR
        acl_rt_FOUND
    REQUIRED_VARS
        _ACL_RT_INCLUDE_DIR
        acl_rt_SHARED_LIBRARY
)

if(acl_rt_FOUND)
    set(acl_rt_INCLUDE_DIR "${_ACL_RT_INCLUDE_DIR}")
    include(CMakePrintHelpers)
    message(STATUS "Variables in acl_rt module:")
    cmake_print_variables(acl_rt_INCLUDE_DIR)
    cmake_print_variables(acl_rt_SHARED_LIBRARY)

    add_library(acl_rt_headers INTERFACE IMPORTED)
    set_target_properties(acl_rt_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${acl_rt_INCLUDE_DIR}"
    )

    add_library(acl_rt SHARED IMPORTED)
    set_target_properties(acl_rt PROPERTIES
        INTERFACE_LINK_LIBRARIES "acl_rt_headers"
        IMPORTED_LOCATION "${acl_rt_SHARED_LIBRARY}"
    )

    include(CMakePrintHelpers)
    cmake_print_properties(TARGETS acl_rt_headers
        PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
    )
    cmake_print_properties(TARGETS acl_rt
        PROPERTIES INTERFACE_LINK_LIBRARIES IMPORTED_LOCATION
    )
endif()

# Cleanup temporary variables.
set(_ACL_RT_INCLUDE_DIR)
