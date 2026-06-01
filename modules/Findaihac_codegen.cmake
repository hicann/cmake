# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

find_path(_CANN_AIHAC_CODEGEN_AUTOFUSE_INCLUDE_DIR
    NAMES fusion/fusion_decider.h
    PATH_SUFFIXES pkg_inc/autofuse include/autofuse
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

find_library(_CANN_AIHAC_CODEGEN_SHARED_LIBRARY
    NAMES libaihac_codegen.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(aihac_codegen
    REQUIRED_VARS
        _CANN_AIHAC_CODEGEN_AUTOFUSE_INCLUDE_DIR
        _CANN_AIHAC_CODEGEN_SHARED_LIBRARY
)

if(aihac_codegen_FOUND)
    set(_CANN_INCLUDE_DIRECTORIES
        ${_CANN_AIHAC_CODEGEN_AUTOFUSE_INCLUDE_DIR}
        ${_CANN_AIHAC_CODEGEN_AUTOFUSE_INCLUDE_DIR}/ascir
        ${_CANN_AIHAC_CODEGEN_AUTOFUSE_INCLUDE_DIR}/ascir/ascendc_ir/ascendc_ir_core
        ${_CANN_AIHAC_CODEGEN_AUTOFUSE_INCLUDE_DIR}/ascir/meta
        ${_CANN_AIHAC_CODEGEN_AUTOFUSE_INCLUDE_DIR}/common
        ${_CANN_AIHAC_CODEGEN_AUTOFUSE_INCLUDE_DIR}/graph_metadef
        ${_CANN_AIHAC_CODEGEN_AUTOFUSE_INCLUDE_DIR}/graph_metadef/graph
        ${_CANN_AIHAC_CODEGEN_AUTOFUSE_INCLUDE_DIR}/graph_metadef/graph/ascendc_ir/ascendc_ir_core
    )

    add_library(aihac_codegen_headers INTERFACE IMPORTED)
    set_target_properties(aihac_codegen_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_CANN_INCLUDE_DIRECTORIES}"
    )

    add_library(aihac_codegen SHARED IMPORTED)
    set_target_properties(aihac_codegen PROPERTIES
        INTERFACE_LINK_LIBRARIES "aihac_codegen_headers"
        IMPORTED_LOCATION "${_CANN_AIHAC_CODEGEN_SHARED_LIBRARY}"
    )

    unset(_CANN_INCLUDE_DIRECTORIES)
endif()
