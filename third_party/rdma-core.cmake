# ------------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# ------------------------------------------------------------------------------------------------------------
include_guard(GLOBAL)
include(ExternalProject)
unset(rdma_core_FOUND CACHE)
unset(RDMA_CORE_INCLUDE CACHE)

if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

if(PRODUCT_SIDE STREQUAL "device")
    set(RDMA_CORE_SRC_DIR ${CANN_3RD_LIB_PATH}/lib_cache/device/rdma_core_src)
    set(RDMA_CORE_BUILD_DIR ${CANN_3RD_LIB_PATH}/lib_cache/device/rdma_core_build)
    set(RDMA_CORE_PKG_DIR ${CANN_3RD_LIB_PATH}/pkg/device)
else()
    set(RDMA_CORE_SRC_DIR ${CANN_3RD_LIB_PATH}/lib_cache/rdma_core_src)
    set(RDMA_CORE_BUILD_DIR ${CANN_3RD_LIB_PATH}/lib_cache/rdma_core_build)
    set(RDMA_CORE_PKG_DIR ${CANN_3RD_LIB_PATH}/pkg)
endif()


# 查找目录下是否已经安装，避免重复编译安装
find_path(RDMA_CORE_INCLUDE
    NAMES rdma/rdma_user_cm.h
    PATH_SUFFIXES include
    PATHS ${RDMA_CORE_BUILD_DIR}
    NO_DEFAULT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(rdma_core
    FOUND_VAR
        rdma_core_FOUND
    REQUIRED_VARS
        RDMA_CORE_INCLUDE
)

set(RDMA_CORE_FILE "rdma-core-42.7.tar.gz")
set(RDMA_CORE_PATCH_FILE "rdma-core-42.7.patch")
set(RDMA_CORE_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/rdma-core/${RDMA_CORE_FILE}")
set(RDMA_CORE_PATCH_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/rdma-core/${RDMA_CORE_PATCH_FILE}")

add_library(rdma_core_headers INTERFACE)

if(rdma_core_FOUND AND NOT FORCE_REBUILD_CANN_3RD)
    set(RDMA_CORE_INCLUDE_DIR "${RDMA_CORE_INCLUDE}")
    message(STATUS "[ThirdPartyLib][rdma-core] rdma-core found in ${RDMA_CORE_BUILD_PATH}, and not force rebuild cann third_party")
else()
    if(EXISTS "${RDMA_CORE_PKG_DIR}/${RDMA_CORE_PATCH_FILE}")
        set(RDMA_CORE_PATCH "${RDMA_CORE_PKG_DIR}/${RDMA_CORE_PATCH_FILE}")
    elseif(EXISTS "${CANN_3RD_LIB_PATH}/${RDMA_CORE_PATCH_FILE}")
        set(RDMA_CORE_PATCH "${CANN_3RD_LIB_PATH}/${RDMA_CORE_PATCH_FILE}")
    elseif(EXISTS "${CANN_3RD_LIB_PATH}/rdma-core/${RDMA_CORE_PATCH_FILE}")
        set(RDMA_CORE_PATCH "${CANN_3RD_LIB_PATH}/rdma-core/${RDMA_CORE_PATCH_FILE}")
    else()
        set(RDMA_CORE_PATCH_PROJECT_URL "${RDMA_CORE_PATCH_URL}")
    endif()

    if(RDMA_CORE_PATCH_PROJECT_URL)
 	    ExternalProject_Add(rdma_core_patch
            URL ${RDMA_CORE_PATCH_PROJECT_URL}
 	        URL_HASH SHA256=54ca56b3b68bc465a78dd5839cd7110610745c7152a1dc3a72b265deeebb905f
 	        DOWNLOAD_DIR ${RDMA_CORE_PKG_DIR}
 	        UPDATE_COMMAND ""
 	        CONFIGURE_COMMAND ""
 	        BUILD_COMMAND ""
 	        INSTALL_COMMAND ""
 	        DOWNLOAD_NO_EXTRACT TRUE
 	        DOWNLOAD_NO_PROGRESS TRUE
 	        EXCLUDE_FROM_ALL TRUE
 	    )
        set(RDMA_CORE_PATCH "${RDMA_CORE_PKG_DIR}/${RDMA_CORE_PATCH_FILE}")
    else()
        add_custom_target(rdma_core_patch)
    endif()

    if(EXISTS "${CANN_3RD_LIB_PATH}/rdma-core/CMakeLists.txt")
        set(RDMA_CORE_SRC_DIR ${CANN_3RD_LIB_PATH}/rdma-core)
        message(STATUS "[ThirdPartyLib][rdma-core] use local rdma-core cache ${RDMA_CORE_SRC_DIR}.")
    elseif(EXISTS "${CANN_3RD_LIB_PATH}/${RDMA_CORE_FILE}")
        set(RDMA_CORE_PROJECT_URL "${CANN_3RD_LIB_PATH}/${RDMA_CORE_FILE}")
        message(STATUS "[ThirdPartyLib][rdma-core] use local rdma-core cache ${RDMA_CORE_PROJECT_URL}.")
    elseif(EXISTS "${CANN_3RD_LIB_PATH}/rdma-core/${RDMA_CORE_FILE}")
        set(RDMA_CORE_PROJECT_URL "${CANN_3RD_LIB_PATH}/rdma-core/${RDMA_CORE_FILE}")
        message(STATUS "[ThirdPartyLib][rdma-core] pipeline use rdma-core cache ${RDMA_CORE_PROJECT_URL}.")
    else()
        set(RDMA_CORE_PROJECT_URL "${RDMA_CORE_URL}")
        message(STATUS "[ThirdPartyLib][rdma-core] not use cache, download rdma-core ${RDMA_CORE_URL}.")
    endif()

    if(RDMA_CORE_PROJECT_URL)
        ExternalProject_Add(rdma_core_src
            URL ${RDMA_CORE_PROJECT_URL}
            URL_HASH SHA256=aa935de1fcd07c42f7237b0284b5697b1ace2a64f2bcfca3893185bc91b8c74d
            SOURCE_DIR ${RDMA_CORE_SRC_DIR}
            DOWNLOAD_DIR ${RDMA_CORE_PKG_DIR}
            PATCH_COMMAND patch -p1 -i "${RDMA_CORE_PATCH}"
            CONFIGURE_COMMAND ""
            BUILD_COMMAND ""
            INSTALL_COMMAND ""
            DOWNLOAD_NO_PROGRESS TRUE
            EXCLUDE_FROM_ALL TRUE
            DEPENDS rdma_core_patch
        )
    else()
        add_custom_target(rdma_core_src)
    endif()

    ExternalProject_Add(rdma_core_build
        SOURCE_DIR ${RDMA_CORE_SRC_DIR}
        BINARY_DIR ${RDMA_CORE_BUILD_DIR}
        DOWNLOAD_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
            -DNO_MAN_PAGES=1
            -DENABLE_RESOLVE_NEIGH=0
            -DCMAKE_SKIP_RPATH=True
            -DNO_PYVERBS=1
            <SOURCE_DIR>
        BUILD_COMMAND $(MAKE) kern-abi
        INSTALL_COMMAND ""
        EXCLUDE_FROM_ALL TRUE
        DEPENDS rdma_core_src
    )

    set(RDMA_CORE_INCLUDE_DIR "${RDMA_CORE_BUILD_DIR}/include")
    add_dependencies(rdma_core_headers rdma_core_build)
endif()

target_include_directories(rdma_core_headers INTERFACE
    ${RDMA_CORE_INCLUDE_DIR}
)
