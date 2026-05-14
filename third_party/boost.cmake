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

unset(boost_FOUND CACHE)
unset(boost_INCLUDE CACHE)

if(NOT OPEN_PKG_PATH)
    set(OPEN_PKG_PATH ${CANN_3RD_LIB_PATH}/pkg)
endif()

set(BOOST_DOWNLOAD_PATH ${CANN_3RD_LIB_PATH}/pkg)
set(BOOST_SRC_PATH ${CANN_3RD_LIB_PATH}/boost)
set(BOOST_FILE "boost_1_87_0.tar.gz")
set(DOWNLOAD_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/boost/${BOOST_FILE}")

find_path(BOOST_INCLUDE
    NAMES boost/config.hpp
    PATHS ${BOOST_SRC_PATH}
    NO_DEFAULT_PATH)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(boost
    FOUND_VAR
    boost_FOUND
    REQUIRED_VARS
    BOOST_INCLUDE)

if(boost_FOUND AND NOT FORCE_REBUILD_CANN_3RD)
    message("[ThirdParty][boost] found in ${BOOST_SRC_PATH}, and not force rebuild cann third_party")
    # depends by mockcpp
    add_custom_target(third_party_boost)
else()
    if(EXISTS ${CANN_3RD_LIB_PATH}/boost/${BOOST_FILE})
        set(REQ_URL CANN_3RD_LIB_PATH/boost/${BOOST_FILE})
        message(STATUS "[ThirdParty][boost] Found local boost package: ${REQ_URL}")
    elseif(EXISTS ${CANN_3RD_LIB_PATH}/${BOOST_FILE})
        # 离线编译场景，优先使用已下载的包
        set(REQ_URL ${CANN_3RD_LIB_PATH}/${BOOST_FILE})
        message(STATUS "[ThirdParty][boost] Found local boost package: ${REQ_URL}")
    else()
        # 下载并解压
        message(STATUS "[ThirdParty][boost] Downloading ${BOOST_NAME} from ${DOWNLOAD_URL}")
        set(REQ_URL ${DOWNLOAD_URL})
    endif()

    ExternalProject_Add(third_party_boost
        URL ${REQ_URL}
        URL_HASH SHA256=f55c340aa49763b1925ccf02b2e83f35fdcf634c9d5164a2acb87540173c741d
        DOWNLOAD_NO_EXTRACT FALSE
        DOWNLOAD_NO_PROGRESS TRUE
        DOWNLOAD_DIR ${BOOST_DOWNLOAD_PATH}
        SOURCE_DIR ${BOOST_SRC_PATH}
        CONFIGURE_COMMAND ""    # 无需编译，只需解压
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
    )
endif()

# used for symengine_build
ExternalProject_Add(third_party_boost_headers
    SOURCE_DIR ${BOOST_SRC_PATH}
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND  cd <SOURCE_DIR> && sh bootstrap.sh --prefix=${CANN_3RD_LIB_PATH}/lib_cache/boost --with-libraries=headers
    BUILD_COMMAND   cd <SOURCE_DIR> &&  ./b2 headers install
    INSTALL_COMMAND ""
    EXCLUDE_FROM_ALL TRUE
)

# use for dvpp service
add_library(boost INTERFACE)

set_property(TARGET boost PROPERTY
    INTERFACE_INCLUDE_DIRECTORIES ${BOOST_SRC_PATH}
)

if(TARGET third_party_boost)
    add_dependencies(third_party_boost_headers third_party_boost)
    add_dependencies(boost third_party_boost)
endif()
