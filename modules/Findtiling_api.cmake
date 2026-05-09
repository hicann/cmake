# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(tiling_api_FOUND)
    message(STATUS "Package tiling_api has been found.")
    return()
endif()

find_library(tiling_api_STATIC_LIBRARY
    NAMES libtiling_api.a
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(tiling_api
    FOUND_VAR
        tiling_api_FOUND
    REQUIRED_VARS
        tiling_api_STATIC_LIBRARY
)

if(tiling_api_FOUND)
    include(CMakePrintHelpers)
    message(STATUS "Variables in tiling_api module:")
    cmake_print_variables(tiling_api_STATIC_LIBRARY)

    add_library(tiling_api STATIC IMPORTED)
    set_target_properties(tiling_api PROPERTIES
        IMPORTED_LOCATION "${tiling_api_STATIC_LIBRARY}"
    )

    include(CMakePrintHelpers)
    cmake_print_properties(TARGETS tiling_api
        PROPERTIES INTERFACE_LINK_LIBRARIES IMPORTED_LOCATION
    )
endif()

set(tiling_api_STATIC_LIBRARY)
