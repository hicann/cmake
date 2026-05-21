# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(asc_devkit_FOUND)
    return()
endif()

find_path(_CANN_ASC_HOST_INCLUDE_DIR
    NAMES hccl_tiling_msg.h
    PATH_SUFFIXES pkg_inc/asc/hccl/internal
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

find_path(_CANN_ASC_KERNEL_TILING_INCLUDE_DIR
    NAMES kernel_tiling/kernel_tiling.h
    PATH_SUFFIXES include
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

find_path(_CANN_ASC_KERNEL_INCLUDE_DIR
    NAMES include/basic_api/kernel_common.h
    PATH_SUFFIXES asc
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(asc_devkit
    FOUND_VAR
        asc_devkit_FOUND
    REQUIRED_VARS
        _CANN_ASC_HOST_INCLUDE_DIR
        _CANN_ASC_KERNEL_TILING_INCLUDE_DIR
        _CANN_ASC_KERNEL_INCLUDE_DIR
)

if(asc_devkit_FOUND)
    add_library(asc_host_headers INTERFACE IMPORTED)
    set_target_properties(asc_host_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_CANN_ASC_HOST_INCLUDE_DIR}"
    )

    add_library(kernel_tiling_headers INTERFACE IMPORTED)
    set_target_properties(kernel_tiling_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_CANN_ASC_KERNEL_TILING_INCLUDE_DIR}"
    )

    add_library(asc_kernel_headers INTERFACE IMPORTED)
    set_target_properties(asc_kernel_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_CANN_ASC_KERNEL_INCLUDE_DIR};${_CANN_ASC_KERNEL_INCLUDE_DIR}/include;${_CANN_ASC_KERNEL_INCLUDE_DIR}/include/basic_api;${_CANN_ASC_KERNEL_INCLUDE_DIR}/include/simt_api;${_CANN_ASC_KERNEL_INCLUDE_DIR}/impl/basic_api;${_CANN_ASC_KERNEL_INCLUDE_DIR}/impl/simt_api"
    )
endif()
