# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(ge_compiler_FOUND)
    message(STATUS "Package ge_compiler has been found.")
    return()
endif()

find_library(_CANN_GE_COMPILER_SHARED_LIBRARY
    NAMES libge_compiler.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ge_compiler
    FOUND_VAR
        ge_compiler_FOUND
    REQUIRED_VARS
        _CANN_GE_COMPILER_SHARED_LIBRARY
)

if(ge_compiler_FOUND)
    add_library(ge_compiler SHARED IMPORTED)
    set_target_properties(ge_compiler PROPERTIES
        IMPORTED_LOCATION "${_CANN_GE_COMPILER_SHARED_LIBRARY}"
    )
endif()
