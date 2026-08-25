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
set(MAKESELF_TAR_PATH "${CANN_3RD_LIB_PATH}/makeself-release-2.5.0.tar.gz")
set(MAKESELF_PATCH_PATH "${CANN_3RD_LIB_PATH}/pkg/makeself-2.5.0.patch")
set(REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/makeself/makeself-release-2.5.0.tar.gz")
set(PATCH_REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/makeself/makeself-2.5.0.patch")

# 1. 已存在应用过patch的源码，跳过解压和应用patch
if (EXISTS "${MAKESELF_PATH}/makeself-header.sh" AND EXISTS "${MAKESELF_PATH}/makeself.sh")
    message(STATUS "[ThirdParty][makeself] found patched source in ${MAKESELF_PATH}, skip extract and patch")
# 2. 本地缓存：同时存在tar包和patch文件，走本地缓存逻辑
elseif (EXISTS "${MAKESELF_TAR_PATH}" AND EXISTS "${MAKESELF_PATCH_PATH}")
    message(STATUS "[ThirdParty][makeself] use local cache tar and patch")
    set(MAKESELF_NEED_EXTRACT TRUE)
# 3. 其余情况：下载tar包和patch包
else()
    message(STATUS "[ThirdParty][makeself] downloading tar and patch")
    file(MAKE_DIRECTORY "${CANN_3RD_LIB_PATH}/pkg")

    if (NOT EXISTS "${MAKESELF_TAR_PATH}")
        message(STATUS "[ThirdParty][makeself] downloading tar from ${REQ_URL}")
        file(DOWNLOAD "${REQ_URL}" "${MAKESELF_TAR_PATH}"
            TIMEOUT 300
            EXPECTED_HASH SHA256=705d0376db9109a8ef1d4f3876c9997ee6bed454a23619e1dbc03d25033e46ea
            STATUS TAR_DOWNLOAD_STATUS
        )
        list(GET TAR_DOWNLOAD_STATUS 0 TAR_DOWNLOAD_CODE)
        if(NOT TAR_DOWNLOAD_CODE EQUAL 0)
            message(FATAL_ERROR "[ThirdParty][makeself] failed to download tar: ${TAR_DOWNLOAD_STATUS}")
        endif()
    endif()

    if (NOT EXISTS "${MAKESELF_PATCH_PATH}")
        message(STATUS "[ThirdParty][makeself] downloading patch from ${PATCH_REQ_URL}")
        file(DOWNLOAD "${PATCH_REQ_URL}" "${MAKESELF_PATCH_PATH}"
            TIMEOUT 300
            EXPECTED_HASH SHA256=abb9efe26f95db61ce927a7d046ea2c73ec908cec984ea6316892b4c8b11d784
            STATUS PATCH_DOWNLOAD_STATUS
        )
        list(GET PATCH_DOWNLOAD_STATUS 0 PATCH_DOWNLOAD_CODE)
        if(NOT PATCH_DOWNLOAD_CODE EQUAL 0)
            message(FATAL_ERROR "[ThirdParty][makeself] failed to download patch: ${PATCH_DOWNLOAD_STATUS}")
        endif()
    endif()

    set(MAKESELF_NEED_EXTRACT TRUE)
endif()

# 解压和应用patch（分支2和分支3共用）
if(MAKESELF_NEED_EXTRACT)
    file(MAKE_DIRECTORY "${MAKESELF_PATH}")

    execute_process(
        COMMAND tar xzf "${MAKESELF_TAR_PATH}" -C "${MAKESELF_PATH}" --strip-components=1
        RESULT_VARIABLE EXTRACT_RESULT
        ERROR_VARIABLE EXTRACT_ERROR
    )
    if(NOT EXTRACT_RESULT EQUAL 0)
        message(FATAL_ERROR "[ThirdParty][makeself] failed to extract tar: ${EXTRACT_ERROR}")
    endif()
    message(STATUS "[ThirdParty][makeself] extracted to ${MAKESELF_PATH}")

    execute_process(
        COMMAND patch -N --batch --quiet -r - -p1
        WORKING_DIRECTORY "${MAKESELF_PATH}"
        INPUT_FILE "${MAKESELF_PATCH_PATH}"
        RESULT_VARIABLE PATCH_RESULT
        ERROR_VARIABLE PATCH_ERROR
    )
    if(NOT PATCH_RESULT EQUAL 0 AND NOT PATCH_RESULT EQUAL 1)
        message(FATAL_ERROR "[ThirdParty][makeself] failed to apply patch: ${PATCH_ERROR}")
    endif()
    message(STATUS "[ThirdParty][makeself] patch applied successfully")
endif()

# 设置执行权限
execute_process(
    COMMAND chmod 700 "${MAKESELF_PATH}/makeself.sh"
    COMMAND chmod 700 "${MAKESELF_PATH}/makeself-header.sh"
    RESULT_VARIABLE CHMOD_RESULT
    ERROR_VARIABLE CHMOD_ERROR
)
