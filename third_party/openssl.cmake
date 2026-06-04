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

unset(openssl_FOUND CACHE)

if(PRODUCT_SIDE STREQUAL "device")
    set(OPENSSL_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/device/openssl)
    set(OPENSSL_PKG_PATH ${CANN_3RD_LIB_PATH}/pkg/device)
else()
    set(OPENSSL_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/openssl)
    set(OPENSSL_PKG_PATH ${CANN_3RD_LIB_PATH}/pkg)
endif()

find_path(OPENSSL_INCLUDE
    NAMES openssl/ssl.h
    PATH_SUFFIXES include
    PATHS ${OPENSSL_INSTALL_PATH}
    NO_DEFAULT_PATH
)

find_library(CRYPTO_LIB_PATH
    NAMES libcrypto.a
    PATH_SUFFIXES lib lib64
    PATHS ${OPENSSL_INSTALL_PATH}
    NO_DEFAULT_PATH
)

find_library(SSL_LIB_PATH
    NAMES libssl.a
    PATH_SUFFIXES lib lib64
    PATHS ${OPENSSL_INSTALL_PATH}
    NO_DEFAULT_PATH
)

# 在线编译查询 openssl 缓存
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(openssl
    FOUND_VAR
    openssl_FOUND 
    REQUIRED_VARS
    OPENSSL_INCLUDE
    CRYPTO_LIB_PATH
    SSL_LIB_PATH
)

if (openssl_FOUND AND NOT FORCE_REBUILD_CANN_3RD)
    message(STATUS "[ThirdPartyLib][openssl] use local libcrypto: ${CRYPTO_LIB_PATH}")
    # the key use for hcomm services online
    set(OPENSSL_INCLUDE_DIR ${OPENSSL_INSTALL_PATH}/include)
    add_custom_target(openssl_project)
else()
    # ========== 基本路径配置 ==========
    if (EXISTS ${CANN_3RD_LIB_PATH}/openssl-openssl-3.0.9.tar.gz)
        # local offline
        message(STATUS "[ThirdParty][openssl] Found local package in ${CANN_3RD_LIB_PATH}")
        set(REQ_URL ${CANN_3RD_LIB_PATH}/openssl-openssl-3.0.9.tar.gz)
    elseif(EXISTS ${CANN_3RD_LIB_PATH}/openssl/Configure)
        message(STATUS "[ThirdParty][openssl] Found local source code in ${CANN_3RD_LIB_PATH}/openssl")
        set(REQ_URL "${CANN_3RD_LIB_PATH}/openssl")
    else()
        message(STATUS "[ThirdParty][openssl] Downloading openssl.")
        set(REQ_URL https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/openssl/openssl-openssl-3.0.9.tar.gz)
    endif()

    # ========== 工具链配置（根据系统架构判断） ==========
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
        set(OPENSSL_PLATFORM linux-x86_64)
    elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
        set(OPENSSL_PLATFORM linux-aarch64)
    elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm")
        set(OPENSSL_PLATFORM linux-armv4)
    else()
        set(OPENSSL_PLATFORM linux-generic64)
    endif()

    # ========== 编译选项 ==========
    set(OPENSSL_OPTION "-fstack-protector-all -D_FORTIFY_SOURCE=2 -fvisibility=hidden -O2 -Wl,-z,relro,-z,now,-z,noexecstack -Wl,--build-id=none -s")

    find_program(CCACHE_PROGRAM ccache)
    if(CCACHE_PROGRAM)
        set(OPENSSL_CC "${CCACHE_PROGRAM} ${CMAKE_C_COMPILER}")
        set(OPENSSL_CXX "${CCACHE_PROGRAM} ${CMAKE_CXX_COMPILER}")
    else()
        set(OPENSSL_CC "${CMAKE_C_COMPILER}")
        set(OPENSSL_CXX "${CMAKE_CXX_COMPILER}")
    endif()

    # ========== Perl 路径(OpenSSL 的 configure 依赖 Perl)==========
    find_program(PERL_PATH perl REQUIRED)
    set(OPENSSL_CONFIGURE_PUB_COMMAND
        ${PERL_PATH} <SOURCE_DIR>/Configure
        ${OPENSSL_PLATFORM}
        no-afalgeng no-asm no-shared threads enable-ssl3-method no-tests
        ${OPENSSL_OPTION}
        --prefix=${OPENSSL_INSTALL_PATH}
        --libdir=lib
    )

    set(OPENSSL_CONFIGURE_COMMAND
        unset CROSS_COMPILE && export NO_OSSL_RENAME_VERSION=1 &&
        ${OPENSSL_CONFIGURE_PUB_COMMAND}
    )

    # ========== 构建命令 ==========
    set(OPENSSL_MAKE_CMD $(MAKE))
    set(OPENSSL_INSTALL_CMD $(MAKE) install_dev)
    # ========== ExternalProject_Add ==========
    include(ExternalProject)
    ExternalProject_Add(openssl_project
            URL ${REQ_URL}                        # 从本地 tar.gz 获取源
            URL_HASH SHA256=2eec31f2ac0e126ff68d8107891ef534159c4fcfb095365d4cd4dc57d82616ee  # 校验哈希压缩包正确性
            DOWNLOAD_DIR ${OPENSSL_PKG_PATH}
            CONFIGURE_COMMAND
                ${OPENSSL_CONFIGURE_COMMAND}
                CC=${OPENSSL_CC}
                CXX=${OPENSSL_CXX}
            BUILD_COMMAND ${OPENSSL_MAKE_CMD}
            INSTALL_COMMAND ${OPENSSL_INSTALL_CMD}
    )
    ExternalProject_Add_Step(openssl_project extra_install
        COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/crypto ${OPENSSL_INSTALL_PATH}/include/crypto
        COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/internal ${OPENSSL_INSTALL_PATH}/include/internal
        DEPENDEES install
    )

    set(OPENSSL_INCLUDE ${OPENSSL_INSTALL_PATH}/include)
    # the key use for hcomm services
    set(OPENSSL_INCLUDE_DIR ${OPENSSL_INCLUDE})

    set(CRYPTO_LIB_PATH "${OPENSSL_INSTALL_PATH}/lib/libcrypto.a")
    set(SSL_LIB_PATH "${OPENSSL_INSTALL_PATH}/lib/libssl.a")

    if(NOT EXISTS ${OPENSSL_INCLUDE})
        file(MAKE_DIRECTORY "${OPENSSL_INCLUDE}")
    endif()
endif()

message(STATUS "[ThirdPartyLib][openssl] libcrypto: ${CRYPTO_LIB_PATH} libssl: ${SSL_LIB_PATH} include: ${OPENSSL_INCLUDE}")
if(NOT TARGET crypto_static)
    add_library(crypto_static STATIC IMPORTED GLOBAL)
    add_dependencies(crypto_static openssl_project)
    set_target_properties(crypto_static PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE}"
        IMPORTED_LOCATION             "${CRYPTO_LIB_PATH}"
    )
    add_library(OpenSSL::Crypto ALIAS crypto_static)
else()
    message(STATUS "[ThirdParty][openssl] crypto_static already exist.")
endif()

if(NOT TARGET ssl_static)
    add_library(ssl_static STATIC IMPORTED GLOBAL)
    add_dependencies(ssl_static openssl_project)
    set_target_properties(ssl_static PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE}"
        IMPORTED_LOCATION             "${SSL_LIB_PATH}"
    )
    add_library(OpenSSL::SSL ALIAS ssl_static)
else()
    message(STATUS "[ThirdParty][openssl] ssl_static already exist.")
endif()
