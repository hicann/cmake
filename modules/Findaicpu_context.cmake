# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(aicpu_context_FOUND)
    return()
endif()

# 注意，部分编译场景device侧没有aicpu，libaicpu_context.a不是必然存在

find_library(_CANN_AICPU_CONTEXT_STATIC_LIBRARY
    NAMES libaicpu_context.a
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

find_package_handle_standard_args(aicpu_context
    REQUIRED_VARS
        _CANN_AICPU_CONTEXT_STATIC_LIBRARY
)

if(aicpu_context_FOUND)
    add_library(aicpu_context STATIC IMPORTED)
    set_target_properties(aicpu_context PROPERTIES
        IMPORTED_LOCATION "${_CANN_AICPU_CONTEXT_STATIC_LIBRARY}"
    )
endif()
