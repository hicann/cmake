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
include(ExternalProject)
include(FindPackageHandleStandardArgs)

if(CMAKE_GENERATOR MATCHES "Makefiles")
    set(CSEC_BUILD_JOB_SERVER_AWARE TRUE)
else()
    set(CSEC_BUILD_JOB_SERVER_AWARE FALSE)
endif()

set(ABL_CSEC ${CANN_3RD_LIB_PATH}/libc_sec)

add_library(c_sec_headers INTERFACE)
if (EXISTS "${ABL_CSEC}" AND IS_DIRECTORY "${ABL_CSEC}")
    message(STATUS "[ThirdParty][csec] libc_sec detected")
    add_subdirectory(${ABL_CSEC} ${CMAKE_BINARY_DIR}/libc_sec)
    target_compile_options(static_c_sec PRIVATE -fstack-protector-strong)
    target_link_options(static_c_sec PRIVATE -Wl,-z,now)
    target_link_options(static_c_sec PRIVATE -s)
    target_compile_options(shared_c_sec PRIVATE -fstack-protector-strong)
    target_link_options(shared_c_sec PRIVATE -Wl,-z,now)
    target_link_options(shared_c_sec PRIVATE -s)
    set(LIBC_SEC_HEADER ${ABL_CSEC}/include)
    add_library(c_sec ALIAS shared_c_sec)
    add_library(c_sec_static ALIAS static_c_sec)
else()
    # ==========================================================================================================
    # 1. 路径配置：install 到 lib_cache 持久化目录，支持二进制缓存复用
    # ==========================================================================================================
    if(PRODUCT_SIDE STREQUAL "device")
        set(CSEC_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/device/csec)
        set(CSEC_DOWNLOAD_DIR ${CANN_3RD_LIB_PATH}/pkg/device)
    else()
        set(CSEC_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/csec)
        set(CSEC_DOWNLOAD_DIR ${CANN_3RD_LIB_PATH}/pkg)
    endif()

    # ==========================================================================================================
    # 2. 检测预构建产物（参考 openssl.cmake / gtest_shared.cmake 的缓存复用模式）
    # ==========================================================================================================
    find_path(CSEC_INCLUDE_DIR
        NAMES securec.h
        PATH_SUFFIXES include
        PATHS ${CSEC_INSTALL_PATH}
        NO_DEFAULT_PATH
    )
    find_library(CSEC_SHARED_LIB
        NAMES libc_sec.so
        PATH_SUFFIXES lib lib64
        PATHS ${CSEC_INSTALL_PATH}
        NO_DEFAULT_PATH
    )
    find_library(CSEC_STATIC_LIB
        NAMES libc_sec.a
        PATH_SUFFIXES lib lib64
        PATHS ${CSEC_INSTALL_PATH}
        NO_DEFAULT_PATH
    )

    find_package_handle_standard_args(csec
        FOUND_VAR
        csec_FOUND
        REQUIRED_VARS
        CSEC_INCLUDE_DIR
        CSEC_SHARED_LIB
        CSEC_STATIC_LIB
    )

    if(csec_FOUND AND NOT FORCE_REBUILD_CANN_3RD)
        message(STATUS "[ThirdParty][csec] use cache: ${CSEC_INSTALL_PATH}")
        add_custom_target(csec_build)
        set(LIBC_SEC_HEADER ${CSEC_INCLUDE_DIR})
        set(CSEC_SHARED_LIB_PATH ${CSEC_SHARED_LIB})
        set(CSEC_STATIC_LIB_PATH ${CSEC_STATIC_LIB})
    else()
        # ======================================================================================================
        # 3. 源码获取：本地 tar.gz 优先，否则远程下载
        # ======================================================================================================
        set(CSEC_EXTRA_CFLAGS "-fstack-protector-strong")
        set(CSEC_EXTRA_LDFLAGS "-Wl,-z,now -s")

        if(EXISTS "${CANN_3RD_LIB_PATH}/libboundscheck-v1.1.16.tar.gz")
            set(REQ_URL "${CANN_3RD_LIB_PATH}/libboundscheck-v1.1.16.tar.gz")
            message(STATUS "[ThirdParty][csec] ${REQ_URL} found.")
        else()
            set(REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/libboundscheck/libboundscheck-v1.1.16.tar.gz")
            message(STATUS "[ThirdParty][csec] ${REQ_URL} not found, need download.")
        endif()

        ExternalProject_Add(csec_build
            URL ${REQ_URL}
            URL_HASH SHA256=aee8368ef04a42a499edd5bfebce529e7f32dd138bfed383d316e48af4e45d2c
            TIMEOUT 300
            DOWNLOAD_DIR ${CSEC_DOWNLOAD_DIR}
            PATCH_COMMAND ${CMAKE_COMMAND}
                -D CSEC_SOURCE_DIR=<SOURCE_DIR>
                -P ${CMAKE_CURRENT_LIST_DIR}/csec_patch.cmake
            CONFIGURE_COMMAND ""
            BUILD_IN_SOURCE 1
            BUILD_JOB_SERVER_AWARE ${CSEC_BUILD_JOB_SERVER_AWARE}
            BUILD_COMMAND ${CMAKE_MAKE_PROGRAM}
                -C <SOURCE_DIR> lib
                CC=${CMAKE_C_COMPILER}
                AR=${CMAKE_AR}
                LINK=${CMAKE_C_COMPILER}
                CFLAGS="${CSEC_EXTRA_CFLAGS}"
                LDFLAGS="${CSEC_EXTRA_LDFLAGS}"
            INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory ${CSEC_INSTALL_PATH}/lib
                COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/lib/libc_sec.so ${CSEC_INSTALL_PATH}/lib/libc_sec.so
                COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/lib/libc_sec.a ${CSEC_INSTALL_PATH}/lib/libc_sec.a
                COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include ${CSEC_INSTALL_PATH}/include
        )

        set(LIBC_SEC_HEADER ${CSEC_INSTALL_PATH}/include)
        set(CSEC_SHARED_LIB_PATH ${CSEC_INSTALL_PATH}/lib/libc_sec.so)
        set(CSEC_STATIC_LIB_PATH ${CSEC_INSTALL_PATH}/lib/libc_sec.a)
        if(NOT EXISTS "${LIBC_SEC_HEADER}")
            file(MAKE_DIRECTORY ${LIBC_SEC_HEADER})
        endif()
    endif()

    add_library(shared_c_sec SHARED IMPORTED GLOBAL)
    set_property(TARGET shared_c_sec PROPERTY
        IMPORTED_LOCATION ${CSEC_SHARED_LIB_PATH}
    )

    add_library(static_c_sec STATIC IMPORTED GLOBAL)
    set_property(TARGET static_c_sec PROPERTY
        IMPORTED_LOCATION ${CSEC_STATIC_LIB_PATH}
    )

    add_dependencies(shared_c_sec csec_build)
    add_dependencies(static_c_sec csec_build)
    add_dependencies(c_sec_headers csec_build)

    add_library(c_sec ALIAS shared_c_sec)
    add_library(c_sec_static ALIAS static_c_sec)
endif()

target_include_directories(c_sec_headers INTERFACE
    $<BUILD_INTERFACE:${LIBC_SEC_HEADER}>
)
target_link_libraries(shared_c_sec INTERFACE c_sec_headers)
target_link_libraries(static_c_sec INTERFACE c_sec_headers)
