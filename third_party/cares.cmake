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
    set(CARES_INTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/device/c-ares)
    set(CARES_PKG_PATH ${CANN_3RD_LIB_PATH}/pkg/device)
else()
    set(CARES_INTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/c-ares)
    set(CARES_PKG_PATH ${CANN_3RD_LIB_PATH}/pkg)
endif()

set(CARES_FILE ${CARES_INTALL_PATH}/include/ares.h)
if (EXISTS ${CARES_FILE})
    message(STATUS "[ThirdPartyLib][c-ares] ${CARES_FILE} found.")
    add_custom_target(cares_build)
else()

    if(EXISTS ${CANN_3RD_LIB_PATH}/c-ares/c-ares-1.19.1.tar.gz)
        set(REQ_URL "${CANN_3RD_LIB_PATH}/c-ares/c-ares-1.19.1.tar.gz")
        message(STATUS "[ThirdPartyLib][c-ares] ${REQ_URL} found.")
    elseif(EXISTS ${CANN_3RD_LIB_PATH}/c-ares-1.19.1.tar.gz)
        set(REQ_URL "${CANN_3RD_LIB_PATH}/c-ares-1.19.1.tar.gz")
        message(STATUS "[ThirdPartyLib][c-ares] ${REQ_URL} found.")
    else()
        message(STATUS "[ThirdPartyLib][c-ares] ${REQ_URL} not found, need download.")
        set(REQ_URL "https://gitcode.com/cann-src-third-party/c-ares/releases/download/v1.19.1/c-ares-1.19.1.tar.gz")
    endif()

    include(ExternalProject)
    ExternalProject_Add(cares_build
        URL ${REQ_URL}
        DOWNLOAD_DIR ${CARES_PKG_PATH}
        SOURCE_DIR ${CARES_INTALL_PATH}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
        EXCLUDE_FROM_ALL TRUE
        DWONLOAD_NO_PROGRESS TRUE
    )
endif()
