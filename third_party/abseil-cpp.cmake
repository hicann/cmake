# ----------------------------------------------------------------------------
# This program is free software, you can redistribute it and/or modify it.
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This file is a part of the CANN Open Software.
# Licensed under CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# ----------------------------------------------------------------------------
include_guard(GLOBAL)

if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

unset(abseil-cpp_FOUND CACHE)
unset(ABSL_SOURCE_DIR CACHE)

set(ABSEIL_VERSION_PKG abseil-cpp-20230802.1.tar.gz)

if(PRODUCT_SIDE STREQUAL "device")
    set(ABS_INSTALL_DIR ${CANN_3RD_LIB_PATH}/lib_cache/device/abseil-cpp CACHE INTERNAL "abseil cpp install dir")
    set(ABS_PKG_DIR ${CANN_3RD_LIB_PATH}/pkg/device CACHE INTERNAL "abseil cpp pkg dir")
else()
    set(ABS_INSTALL_DIR ${CANN_3RD_LIB_PATH}/lib_cache/abseil-cpp CACHE INTERNAL "abseil cpp install dir")
    set(ABS_PKG_DIR ${CANN_3RD_LIB_PATH}/pkg CACHE INTERNAL "abseil cpp pkg dir")
endif()

# use for online pipeline building acceleration
find_path(ABSL_SOURCE_DIR
    NAMES absl/log/absl_log.h
    PATHS ${ABS_INSTALL_DIR}
    NO_DEFAULT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(abseil-cpp
    FOUND_VAR
        abseil-cpp_FOUND
    REQUIRED_VARS
        ABSL_SOURCE_DIR
)

if(abseil-cpp_FOUND)
    message(STATUS "[ThirdParty][abseil-cpp] Found abseil-cpp in: ${ABS_INSTALL_DIR}")
    add_custom_target(abseil_build)
else()
    # 检查 abseil-cpp 路径
    if(EXISTS ${CANN_3RD_LIB_PATH}/abseil-cpp/${ABSEIL_VERSION_PKG})
        message(STATUS "[ThirdParty][abseil-cpp] found in ${CANN_3RD_LIB_PATH}/abseil-cpp/${ABSEIL_VERSION_PKG}.")
        set(REQ_URL ${CANN_3RD_LIB_PATH}/abseil-cpp/${ABSEIL_VERSION_PKG})
    elseif(EXISTS ${CANN_3RD_LIB_PATH}/${ABSEIL_VERSION_PKG})
        message(STATUS "[ThirdParty][abseil-cpp] Found abseil-cpp in ${CANN_3RD_LIB_PATH}")
        set(REQ_URL ${CANN_3RD_LIB_PATH}/${ABSEIL_VERSION_PKG})
    else()
        message(STATUS "[ThirdParty][abseil-cpp] not found, need download.")
        set(REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/abseil-cpp/abseil-cpp-20230802.1.tar.gz")
    endif()

    # use for offline
    if(EXISTS ${CANN_3RD_LIB_PATH}/abseil-cpp/backport-CVE-2025-0838.patch)
        set(ABSL_CVE_PATCH_FILE ${CANN_3RD_LIB_PATH}/abseil-cpp/backport-CVE-2025-0838.patch)
        message(STATUS "[ThirdParty][abseil-cpp] patch use cache: ${ABSL_CVE_PATCH_FILE}")
    else()
        # 路径不能与 abseil 源码目录相同,构建时会清理
        set(ABSL_CVE_PATCH_FILE ${ABS_PKG_DIR}/backport-CVE-2025-0838.patch)
        if(NOT EXISTS ${ABSL_CVE_PATCH_FILE})
            file(DOWNLOAD
                "https://gitcode.com/cann-src-third-party/abseil-cpp/releases/download/20230802.1-h0/backport-CVE-2025-0838.patch"
                ${ABSL_CVE_PATCH_FILE}
                TIMEOUT 60
            )
        endif()
        message(STATUS "[ThirdParty][abseil-cpp] patch use: ${ABSL_CVE_PATCH_FILE}")
    endif()

    include(ExternalProject)
    ExternalProject_Add(abseil_build
        URL ${REQ_URL}
        URL_HASH SHA256=987ce98f02eefbaf930d6e38ab16aa05737234d7afbab2d5c4ea7adbe50c28ed
        DOWNLOAD_DIR ${ABS_PKG_DIR}
        SOURCE_DIR ${ABS_INSTALL_DIR}
        PATCH_COMMAND patch -p1 < ${CMAKE_CURRENT_LIST_DIR}/protobuf-hide_absl_symbols.patch && patch -p1 < ${ABSL_CVE_PATCH_FILE}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
        EXCLUDE_FROM_ALL TRUE 
    )
endif()
