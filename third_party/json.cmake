# ---------------------------------------------------------------------------- 
# This program is free software, you can redistribute it and/or modify. 
# Copyright (c) 2025 Huawei Technologies Co., Ltd. 
# This file is a part of the CANN Open Software. 
# Licensed under CANN Open Software License Agreement Version 2.0 (the "License"). 
# Please refer to the License for details. You may not use this file except in compliance with the License. 
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. 
# See LICENSE in the root of the software repository for the full text of the License. 
# ---------------------------------------------------------------------------- 
unset(json_FOUND CACHE)
unset(JSON_SOURCE CACHE)

if(NOT OPEN_PKG_PATH)
  set(OPEN_PKG_PATH ${CANN_3RD_LIB_PATH}/pkg)
endif()

set(JSON_INCLUDE ${CANN_3RD_LIB_PATH}/json/include)
find_path(JSON_SOURCE
    NAMES json.hpp
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
    PATHS ${JSON_INCLUDE}/nlohmann
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(json
    FOUND_VAR
    json_FOUND
    REQUIRED_VARS
    JSON_SOURCE
)

if(NOT json_FOUND OR FORCE_REBUILD_CANN_3RD)
    if(EXISTS "${CANN_3RD_LIB_PATH}/include.zip")
        # Users's offline scene.
        message("[ThirdPartyLib][json] use local zip cache.")
        set(REQ_URL ${CANN_3RD_LIB_PATH}/include.zip)
    else()
        message("[ThirdPartyLib][json] not use cache, download json source.")
        set(REQ_URL "https://gitcode.com/cann-src-third-party/json/releases/download/v3.11.3/include.zip")
    endif()

    set(JSON_DOWNLOAD_PATH ${CANN_3RD_LIB_PATH}/pkg)
    set(JSON_INSTALL_PATH ${CMAKE_BINARY_DIR}/json)
    set(JSON_INCLUDE ${JSON_INSTALL_PATH}/include)
    include(ExternalProject) 
    ExternalProject_Add(third_party_json 
            URL ${REQ_URL}
            TLS_VERIFY OFF
            DOWNLOAD_DIR ${JSON_DOWNLOAD_PATH}
            SOURCE_DIR ${JSON_INSTALL_PATH}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND ""
            INSTALL_COMMAND ""
            UPDATE_COMMAND ""
    )
endif()

add_library(json INTERFACE)
add_dependencies(json third_party_json)
target_include_directories(json INTERFACE ${JSON_INCLUDE})