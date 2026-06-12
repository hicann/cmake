# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of 
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

include_guard(GLOBAL)

if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

if(PRODUCT_SIDE STREQUAL "device")
    set(RE2_INTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/device/re2)
    set(RE2_PKG_PATH ${CANN_3RD_LIB_PATH}/pkg/device)
else()
    set(RE2_INTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/re2)
    set(RE2_PKG_PATH ${CANN_3RD_LIB_PATH}/pkg)
endif()

set(RE2_FILE ${RE2_INTALL_PATH}/re2.h)
if (EXISTS ${RE2_FILE})
    message(STATUS "[ThirdPartyLib][re2] re2.h found.")
    add_custom_target(re2_build)
else()
    set(REQ_URL "${CANN_3RD_LIB_PATH}/re2/2024-02-01.tar.gz")
    set(REQ_URL_BACK "${CANN_3RD_LIB_PATH}/re2/re2-2024-02-01.tar.gz")
    if(EXISTS ${REQ_URL})
        message(STATUS "[ThirdPartyLib][re2] ${REQ_URL} found.")
    elseif(EXISTS ${REQ_URL_BACK})
        message(STATUS "[ThirdPartyLib][re2] ${REQ_URL_BACK} found.")
        set(REQ_URL ${REQ_URL_BACK})
    else()
        message(STATUS "[ThirdPartyLib][re2] ${REQ_URL} not found, need download.")
        set(REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/re2/re2-2024-02-01.tar.gz")
    endif()

    include(ExternalProject)
    ExternalProject_Add(re2_build
        URL ${REQ_URL}
        DOWNLOAD_DIR ${RE2_PKG_PATH}
        SOURCE_DIR ${RE2_INTALL_PATH}
        PATCH_COMMAND patch -N --batch --quiet -r - -p1 < ${CMAKE_CURRENT_LIST_DIR}/re2-add_compatible_functions.patch
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
        EXCLUDE_FROM_ALL TRUE
        DWONLOAD_NO_PROGRESS TRUE
    )
endif()