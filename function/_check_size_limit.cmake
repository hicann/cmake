# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

# _check_size_limit.cmake
# Check if the output file size exceeds the specified limit (in KB)
#
# Inputs:
#   _OUTPUT_FILE   : required, absolute path to the output file
#   _SIZE_LIMIT_KB : required, size limit in KB

cmake_minimum_required(VERSION 3.16)

if(NOT _OUTPUT_FILE)
    message(FATAL_ERROR "_OUTPUT_FILE not set")
endif()

if(NOT _SIZE_LIMIT_KB)
    message(FATAL_ERROR "_SIZE_LIMIT_KB not set")
endif()

if(NOT EXISTS "${_OUTPUT_FILE}")
    message(FATAL_ERROR "Output file does not exist: ${_OUTPUT_FILE}")
endif()

file(SIZE "${_OUTPUT_FILE}" file_size_bytes)

math(EXPR size_limit_bytes "${_SIZE_LIMIT_KB} * 1024")

if(file_size_bytes GREATER size_limit_bytes)
    math(EXPR file_size_kb "${file_size_bytes} / 1024")
    message(FATAL_ERROR "File size (${file_size_kb}KB) exceeds limit (${_SIZE_LIMIT_KB}KB): ${_OUTPUT_FILE}")
endif()

message(STATUS "File size check passed: ${_OUTPUT_FILE}")