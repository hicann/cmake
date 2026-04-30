# ----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# ----------------------------------------------------------------------------------------------------------
include_guard(GLOBAL)

set(MAKESELF_NAME "makeself")
set(MAKESELF_PATH "${CANN_3RD_LIB_PATH}/${MAKESELF_NAME}")
set(MAKESELF_TAR_PATH "${CANN_3RD_LIB_PATH}/makeself-release-2.5.0-patch1.tar.gz")

if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

# 新增：检查本地 tar.gz 包是否存在
if (EXISTS "${MAKESELF_TAR_PATH}")
    message(STATUS "[ThirdPartyLib][makeself] found local tar.gz package: ${MAKESELF_TAR_PATH}, extracting...")
    
    # 创建目标目录（如果不存在）
    file(MAKE_DIRECTORY "${MAKESELF_PATH}")
    
    # 解压本地的 tar.gz 包
    execute_process(
        COMMAND tar xzf "${MAKESELF_TAR_PATH}" -C "${MAKESELF_PATH}" --strip-components=1
        RESULT_VARIABLE EXTRACT_RESULT
        ERROR_VARIABLE EXTRACT_ERROR
    )
    
    if(NOT EXTRACT_RESULT EQUAL 0)
        message(FATAL_ERROR "[ThirdPartyLib][makeself] failed to extract local tar.gz: ${EXTRACT_ERROR}")
    endif()
    
    message(STATUS "[ThirdPartyLib][makeself] local tar.gz extracted successfully to ${MAKESELF_PATH}")
    
# 如果本地包不存在，再检查解压后的目录是否存在
elseif (NOT EXISTS "${MAKESELF_PATH}/makeself-header.sh" OR NOT EXISTS "${MAKESELF_PATH}/makeself.sh")
    set(MAKESELF_URL "https://gitcode.com/cann-src-third-party/makeself/releases/download/release-2.5.0-patch1.0/makeself-release-2.5.0-patch1.tar.gz")
    message(STATUS "[ThirdPartyLib][makeself] downloading ${MAKESELF_NAME} from ${MAKESELF_URL}")

    include(FetchContent)
    FetchContent_Declare(
        ${MAKESELF_NAME}
        URL ${MAKESELF_URL}
        URL_HASH SHA256=bfa730a5763cdb267904a130e02b2e48e464986909c0733ff1c96495f620369a
        SOURCE_DIR "${MAKESELF_PATH}"  # 直接解压到此目录
    )
    FetchContent_MakeAvailable(${MAKESELF_NAME})
endif()

# 设置执行权限（无论哪种方式获取，都需要执行）
execute_process(
    COMMAND chmod 700 "${MAKESELF_PATH}/makeself.sh"
    COMMAND chmod 700 "${MAKESELF_PATH}/makeself-header.sh"
    RESULT_VARIABLE CHMOD_RESULT
    ERROR_VARIABLE CHMOD_ERROR
)