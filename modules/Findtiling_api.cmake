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
    return()
endif()

find_path(_CANN_TILING_API_INCLUDE_DIR
    NAMES tiling/tiling_api.h
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

find_library(_CANN_tiling_api_STATIC_LIBRARY
    NAMES libtiling_api.a
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(tiling_api
    REQUIRED_VARS
        _CANN_TILING_API_INCLUDE_DIR
        _CANN_tiling_api_STATIC_LIBRARY
)

if(tiling_api_FOUND)
    add_library(tiling_api_headers INTERFACE IMPORTED)
    set_target_properties(tiling_api_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_CANN_TILING_API_INCLUDE_DIR}"
    )

    add_library(tiling_api STATIC IMPORTED)
    set_target_properties(tiling_api PROPERTIES
        INTERFACE_LINK_LIBRARIES "tiling_api_headers"
        IMPORTED_LOCATION "${_CANN_tiling_api_STATIC_LIBRARY}"
    )
endif()
