# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------
if(aicpu_FOUND)
    return()
endif()

if(TARGET aicpu_headers)
    return()
endif()

find_path(_CANN_AICPU_INCLUDE_DIR
    NAMES aicpu_engine_struct.h
    PATH_SUFFIXES pkg_inc/aicpu
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(aicpu
    REQUIRED_VARS
        _CANN_AICPU_INCLUDE_DIR
)

if(aicpu_FOUND)
    set(_CANN_AICPU_INCLUDE_DIRECTORIES
        ${_CANN_AICPU_INCLUDE_DIR}/..
        ${_CANN_AICPU_INCLUDE_DIR}
        ${_CANN_AICPU_INCLUDE_DIR}/aicpu_schedule
        ${_CANN_AICPU_INCLUDE_DIR}/common
        ${_CANN_AICPU_INCLUDE_DIR}/cpu_kernels
        ${_CANN_AICPU_INCLUDE_DIR}/queue_schedule
        ${_CANN_AICPU_INCLUDE_DIR}/tsd
    )

    add_library(aicpu_headers INTERFACE IMPORTED)
    set_target_properties(aicpu_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_CANN_AICPU_INCLUDE_DIRECTORIES}"
    )

    unset(_CANN_AICPU_INCLUDE_DIRECTORIES)
endif()
