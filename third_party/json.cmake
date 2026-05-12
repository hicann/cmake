# ---------------------------------------------------------------------------- 
# This program is free software, you can redistribute it and/or modify. 
# Copyright (c) 2025 Huawei Technologies Co., Ltd. 
# This file is a part of the CANN Open Software. 
# Licensed under CANN Open Software License Agreement Version 2.0 (the "License"). 
# Please refer to the License for details. You may not use this file except in compliance with the License. 
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. 
# See LICENSE in the root of the software repository for the full text of the License. 
# ---------------------------------------------------------------------------- 
include_guard(GLOBAL)

if(TARGET json)
    return()
endif()

unset(json_FOUND CACHE)
unset(JSON_SOURCE CACHE)
if(NOT OPEN_PKG_PATH)
  set(OPEN_PKG_PATH ${CANN_3RD_LIB_PATH}/pkg)
endif()

if(NOT CANN_3RD_LIB_PATH)
    set(CANN_3RD_LIB_PATH ${CMAKE_SOURCE_DIR}/third_party)
endif()

set(JSON_DOWNLOAD_PATH ${CANN_3RD_LIB_PATH}/pkg)
set(JSON_SOURCE_PATH ${CANN_3RD_LIB_PATH}/json)

find_path(JSON_SOURCE
    NAMES nlohmann/json.hpp
    PATHS ${JSON_SOURCE_PATH}/include
    NO_DEFAULT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(json
    FOUND_VAR
    json_FOUND
    REQUIRED_VARS
    JSON_SOURCE
)

if(NOT json_FOUND OR FORCE_REBUILD_CANN_3RD)
    if(EXISTS "${CANN_3RD_LIB_PATH}/json-3.11.3.tar.gz")
        # Users's offline scene.
        message("[ThirdPartyLib][json] use local json cache.")
        set(REQ_URL ${CANN_3RD_LIB_PATH}/json-3.11.3.tar.gz)
    elseif(EXISTS "${CANN_3RD_LIB_PATH}/json/json-3.11.3.tar.gz")
        message("[ThirdPartyLib][json] pipeline use json cache.")
        set(REQ_URL ${CANN_3RD_LIB_PATH}/json-3.11.3.tar.gz)
    else()
        message("[ThirdPartyLib][json] not use cache, download json source.")
        set(REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/json/json-3.11.3.tar.gz")
    endif()

    include(ExternalProject) 
    ExternalProject_Add(third_party_json 
        URL ${REQ_URL}
        URL_HASH SHA256=0d8ef5af7f9794e3263480193c491549b2ba6cc74bb018906202ada498a79406
        DOWNLOAD_DIR ${JSON_DOWNLOAD_PATH}
        SOURCE_DIR ${JSON_SOURCE_PATH}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
        UPDATE_COMMAND ""
    )
endif()

message("[ThirdPartyLib][json] build json end, JSON_SOURCE_PATH: ${JSON_SOURCE_PATH}.")
add_library(json INTERFACE)
add_dependencies(json third_party_json)
# use for transformer service's reference path
set(JSON_INCLUDE_DIR ${JSON_SOURCE_PATH}/include)
target_include_directories(json INTERFACE ${JSON_SOURCE_PATH}/include)
target_compile_definitions(json INTERFACE
    nlohmann=ascend_nlohmann  # 如果需要命名空间重映射
)