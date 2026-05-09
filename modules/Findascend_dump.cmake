# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(ascend_dump_FOUND)
    message(STATUS "Package ascend_dump has been found.")
    return()
endif()

find_library(ascend_dump_SHARED_LIBRARY
    NAMES libascend_dump.so
    PATH_SUFFIXES lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ascend_dump
    FOUND_VAR
        ascend_dump_FOUND
    REQUIRED_VARS
        ascend_dump_SHARED_LIBRARY
)

if(ascend_dump_FOUND)
    include(CMakePrintHelpers)
    message(STATUS "Variables in ascend_dump module:")
    cmake_print_variables(ascend_dump_SHARED_LIBRARY)

    add_library(ascend_dump SHARED IMPORTED)
    set_target_properties(ascend_dump PROPERTIES
        IMPORTED_LOCATION "${ascend_dump_SHARED_LIBRARY}"
    )

    include(CMakePrintHelpers)
    cmake_print_properties(TARGETS ascend_dump
        PROPERTIES IMPORTED_LOCATION
    )
endif()

# Cleanup temporary variables.
set(ascend_dump_SHARED_LIBRARY)
