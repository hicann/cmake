# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of 
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------
if (tilingdata_base_FOUND)
    return()
endif()

find_library(_CANN_TILINGDATA_BASE_STATIC_LIBRARY
    NAME libtilingdata_base.a
    PATH_SUFFIXES PATH_SUFFIXES lib64/device/lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(tilingdata_base
    REQUIRED_VARS
        _CANN_TILINGDATA_BASE_STATIC_LIBRARY
)

if(tilingdata_base_FOUND)
    add_library(tilingdata_base STATIC IMPORTED)
    set_target_properties(tilingdata_base PROPERTIES
        IMPORTED_LOCATION "${_CANN_TILINGDATA_BASE_STATIC_LIBRARY}"
    )
    if(tilingdata_base_FIND_REQUIRED_OBJECTS)
        execute_process(COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/tilingdata_base_objs)
        execute_process(COMMAND rm -rf ${CMAKE_CURRENT_BINARY_DIR}/tilingdata_base_objs/*)
        execute_process(COMMAND ${CMAKE_AR} -x ${_CANN_TILINGDATA_BASE_STATIC_LIBRARY} --output=${CMAKE_CURRENT_BINARY_DIR}/tilingdata_base_objs
            RESULT_VARIABLE _CANN_AR_RESULT
        )
        if(NOT _CANN_AR_RESULT EQUAL 0)
            message(FATAL_ERROR "${CMAKE_AR} -x ${_CANN_TILINGDATA_BASE_STATIC_LIBRARY} failed!")
        endif()
        file(GLOB _CANN_TILINGDATA_BASE_OBJECTS
            ${CMAKE_CURRENT_BINARY_DIR}/tilingdata_base_objs/*.o
        )
        add_library(tilingdata_base_objs OBJECT IMPORTED)
        set_target_properties(tilingdata_base_objs PROPERTIES
            IMPORTED_OBJECTS "${_CANN_TILINGDATA_BASE_OBJECTS}"
        )
    endif()
endif()
