# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(autofuse_FOUND)
    message(STATUS "Package autofuse has been found.")
    return()
endif()

find_path(_CANN_AUTOFUSE_CONFIG_INCLUDE_DIR
    NAMES utils/auto_fuse_config.h
    PATH_SUFFIXES pkg_inc pkg_inc/autofuse
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_path(_CANN_AUTOFUSE_ATTRS_INCLUDE_DIR
    NAMES fusion/autofuse_attrs.h
    PATH_SUFFIXES pkg_inc pkg_inc/autofuse
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_path(_CANN_AUTOFUSE_ASCENDIR_INCLUDE_DIR
    NAMES ascendc_ir.h
    PATH_SUFFIXES pkg_inc/autofuse/graph_metadef/graph/ascendc_ir/ascendc_ir_core
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(autofuse
    FOUND_VAR
        autofuse_FOUND
    REQUIRED_VARS
        _CANN_AUTOFUSE_CONFIG_INCLUDE_DIR
        _CANN_AUTOFUSE_ATTRS_INCLUDE_DIR
        _CANN_AUTOFUSE_ASCENDIR_INCLUDE_DIR
)

if(autofuse_FOUND)
    add_library(autofuse_headers INTERFACE IMPORTED)
    set_target_properties(autofuse_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_CANN_AUTOFUSE_CONFIG_INCLUDE_DIR};${_CANN_AUTOFUSE_ATTRS_INCLUDE_DIR};${_CANN_AUTOFUSE_ASCENDIR_INCLUDE_DIR}"
    )
    include(CMakePrintHelpers)
    cmake_print_properties(TARGETS autofuse_headers
        PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
    )
endif()