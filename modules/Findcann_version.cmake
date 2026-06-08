# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(cann_version_FOUND)
    return()
endif()

find_path(_CANN_VERSION_INCLUDE_DIR
    NAMES version/runtime_version.h version/metadef_version.h version/asc_devkit_version.h
    PATH_SUFFIXES include
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(cann_version
    REQUIRED_VARS
        _CANN_VERSION_INCLUDE_DIR
)

if(cann_version_FOUND)
    # 子仓在同时调用gen_cann_version_header和find_cann_package(cann_version)时，可能出现target冲突
    # add_library时需要添加保护
    if(NOT TARGET cann_version_headers)
        add_library(cann_version_headers INTERFACE)
    endif()
    target_include_directories(cann_version_headers INTERFACE
        $<BUILD_INTERFACE:${_CANN_VERSION_INCLUDE_DIR}>
    )
endif()
