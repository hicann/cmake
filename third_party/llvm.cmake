# ------------------------------------------------------------------------------
# Unified LLVM Source Cache Module
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# ------------------------------------------------------------------------------
include_guard(GLOBAL)

unset(llvm_FOUND CACHE)
unset(LLVM_INCLUDE CACHE)
unset(LLVM_CORE_LIBRARY CACHE)
unset(MLIR_IR_LIBRARY CACHE)
unset(MLIR_SUPPORT_LIBRARY CACHE)

if(NOT LLVM_PROJECT_VERSION)
    set(LLVM_PROJECT_VERSION "19.1.7")
endif()

if(NOT LLVM_PROJECT_TAG)
    set(LLVM_PROJECT_TAG "llvmorg-${LLVM_PROJECT_VERSION}")
endif()

if(NOT LLVM_PROJECT_URL)
    set(LLVM_PROJECT_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/llvm/llvm-project-llvmorg-19.1.7.tar.gz")
endif()

if(NOT LLVM_REQUIRE_SOURCE)
    set(LLVM_REQUIRE_SOURCE OFF)
endif()

set(LLVM_SOURCE_PATH ${CANN_3RD_LIB_PATH}/llvm-19)
set(LLVM_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/llvm_${LLVM_PROJECT_VERSION})
set(LLVM_DOWNLOAD_PATH ${CANN_3RD_LIB_PATH}/pkg)
set(LLVM_ARCHIVE ${LLVM_DOWNLOAD_PATH}/llvm-project-${LLVM_PROJECT_TAG}.tar.gz)

message(STATUS "[ThirdParty][llvm] LLVM_SOURCE_PATH=${LLVM_SOURCE_PATH}")
message(STATUS "[ThirdParty][llvm] LLVM_INSTALL_PATH=${LLVM_INSTALL_PATH}")
message(STATUS "[ThirdParty][llvm] LLVM_DOWNLOAD_PATH=${LLVM_DOWNLOAD_PATH}")

if(NOT CMAKE_FIND_LIBRARY_PREFIXES)
    set(CMAKE_FIND_LIBRARY_PREFIXES "lib")
endif()

if(NOT CMAKE_FIND_LIBRARY_SUFFIXES)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".so" ".a")
endif()

find_path(LLVM_INCLUDE
    NAMES llvm/IR/Module.h
    PATHS ${LLVM_SOURCE_PATH}/llvm/include
    NO_DEFAULT_PATH
)

find_library(LLVM_CORE_LIBRARY
    NAMES LLVMCore libLLVMCore.so.19.1
    PATH_SUFFIXES lib lib64
    PATHS ${LLVM_INSTALL_PATH}/build-shared
    NO_DEFAULT_PATH
)

find_library(MLIR_IR_LIBRARY
    NAMES MLIRIR libMLIRIR.so.19.1
    PATH_SUFFIXES lib lib64
    PATHS ${LLVM_INSTALL_PATH}/build-shared
    NO_DEFAULT_PATH
)

find_library(MLIR_SUPPORT_LIBRARY
    NAMES MLIRSupport libMLIRSupport.so.19.1
    PATH_SUFFIXES lib lib64
    PATHS ${LLVM_INSTALL_PATH}/build-shared
    NO_DEFAULT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(llvm
    FOUND_VAR llvm_FOUND
    REQUIRED_VARS
    LLVM_INCLUDE
    LLVM_CORE_LIBRARY
    MLIR_IR_LIBRARY
    MLIR_SUPPORT_LIBRARY
)

message(STATUS "[ThirdParty][llvm] Found LLVM/MLIR install cache: ${llvm_FOUND}")
message(STATUS "[ThirdParty][llvm] LLVM_REQUIRE_SOURCE=${LLVM_REQUIRE_SOURCE}")

if(llvm_FOUND AND NOT FORCE_REBUILD_CANN_3RD AND NOT LLVM_REQUIRE_SOURCE)
    message(STATUS "[ThirdParty][llvm] LLVM/MLIR found in ${LLVM_INSTALL_PATH}, and not force rebuild")
    return()
endif()

if(EXISTS ${LLVM_SOURCE_PATH}/llvm/CMakeLists.txt)
    message(STATUS "[ThirdParty][llvm] LLVM source found in ${LLVM_SOURCE_PATH}, and not force rebuild")
    set(REQ_URL "")
elseif(EXISTS ${LLVM_ARCHIVE})
    set(REQ_URL ${LLVM_ARCHIVE})
else()
    message(STATUS "[ThirdParty][llvm] Downloading LLVM from ${LLVM_PROJECT_URL}")
    set(REQ_URL ${LLVM_PROJECT_URL})
endif()
message("[ThirdParty][llvm] valued url path: ${REQ_URL}.")

include(ExternalProject)
ExternalProject_Add(third_party_llvm
    URL ${REQ_URL}
    URL_HASH SHA256=59abea1c22e64933fad4de1671a61cdb934098793c7a31b333ff58dc41bff36c
    DOWNLOAD_DIR ${LLVM_DOWNLOAD_PATH}
    SOURCE_DIR ${LLVM_SOURCE_PATH}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    EXCLUDE_FROM_ALL TRUE
)

message(STATUS "[ThirdParty][llvm] configured successfully.")
