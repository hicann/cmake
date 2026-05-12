# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(ascendc_runtime_FOUND)
    message(STATUS "Package ascendc_runtime has been found.")
    return()
endif()

find_path(_CANN_ascendc_runtime_INCLUDE_DIR
    NAMES acl/acl_rt_compile.h
    PATH_SUFFIXES include
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(_CANN_ascendc_runtime_STATIC_LIBRARY
    NAMES libascendc_runtime.a
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ascendc_runtime
    FOUND_VAR
        ascendc_runtime_FOUND
    REQUIRED_VARS
        _CANN_ascendc_runtime_INCLUDE_DIR
        _CANN_ascendc_runtime_STATIC_LIBRARY
)

if(ascendc_runtime_FOUND)
    add_library(ascendc_runtime STATIC IMPORTED)
    set_target_properties(ascendc_runtime PROPERTIES
        IMPORTED_LOCATION "${_CANN_ascendc_runtime_STATIC_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${_CANN_ascendc_runtime_INCLUDE_DIR}"
    )
endif()
