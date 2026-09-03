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

include(ExternalProject)

# feature-vpto patch: upstream LLVM 19.1.7 -> vpto fork (SimtEntry, float8).
# The vpto calling conventions are required by PTOAS. Environments that ship a
# pre-patched LLVM source (e.g. the "yellow zone" CI, which pre-patches the
# source and cannot reach the patch release asset) are detected by the
# SimtEntry marker in CallingConv.h and skip the patch entirely, including the
# download. When the source still needs the patch, reuse a cached copy first
# and fall back to downloading; a failed download is tolerated (the source may
# be pre-patched, or the later PTOAS build will fail with a missing SimtEntry).
set(LLVM_SOURCE_HAS_VPTO FALSE)
set(LLVM_SOURCE_VPTO_MARKER "${LLVM_SOURCE_PATH}/llvm/include/llvm/IR/CallingConv.h")
if(EXISTS "${LLVM_SOURCE_VPTO_MARKER}")
    file(STRINGS "${LLVM_SOURCE_VPTO_MARKER}" LLVM_SOURCE_VPTO_SIMT_LINE REGEX "SimtEntry")
    if(LLVM_SOURCE_VPTO_SIMT_LINE)
        set(LLVM_SOURCE_HAS_VPTO TRUE)
    endif()
endif()

set(LLVM_VPTO_PATCH_FILE "")
set(LLVM_VPTO_PATCH_READY FALSE)
if(NOT LLVM_SOURCE_HAS_VPTO)
    foreach(_vpto_cand
            ${CANN_3RD_LIB_PATH}/feature-vpto-last3.patch
            ${LLVM_DOWNLOAD_PATH}/feature-vpto-last3.patch)
        if(EXISTS ${_vpto_cand})
            set(LLVM_VPTO_PATCH_FILE ${_vpto_cand})
            set(LLVM_VPTO_PATCH_READY TRUE)
            message(STATUS "[ThirdParty][llvm] vpto patch use cache: ${LLVM_VPTO_PATCH_FILE}")
            break()
        endif()
    endforeach()
    if(NOT LLVM_VPTO_PATCH_READY)
        message(STATUS "[ThirdParty][llvm] vpto patch not cached, downloading to: ${LLVM_DOWNLOAD_PATH}/feature-vpto-last3.patch")
        file(MAKE_DIRECTORY ${LLVM_DOWNLOAD_PATH})
        # file(DOWNLOAD ... EXPECTED_HASH) hard-fails on any failed download
        # (the empty/partial target fails the hash check even with STATUS set),
        # which would abort the configure in sandboxed environments. Download
        # without a hash and verify afterwards.
        file(REMOVE "${LLVM_DOWNLOAD_PATH}/feature-vpto-last3.patch")
        file(DOWNLOAD
            "https://gitcode.com/cann-src-third-party/llvm/releases/download/19.1.7-h0/feature-vpto-last3.patch"
            "${LLVM_DOWNLOAD_PATH}/feature-vpto-last3.patch"
            TIMEOUT 60
            STATUS LLVM_VPTO_DL_STATUS
        )
        list(GET LLVM_VPTO_DL_STATUS 0 LLVM_VPTO_DL_CODE)
        if(NOT LLVM_VPTO_DL_CODE EQUAL 0 OR NOT EXISTS "${LLVM_DOWNLOAD_PATH}/feature-vpto-last3.patch")
            # The source does not carry SimtEntry, so the patch is required;
            # a failed download cannot be silently ignored.
            message(FATAL_ERROR "[ThirdParty][llvm] vpto patch download failed (code ${LLVM_VPTO_DL_CODE}) and the LLVM source lacks SimtEntry; the patch is required for the PTOAS build")
        endif()
        file(SHA256 "${LLVM_DOWNLOAD_PATH}/feature-vpto-last3.patch" LLVM_VPTO_DL_SHA256)
        if(LLVM_VPTO_DL_SHA256 STREQUAL "a49c1d3dd8ab78e93264712bc0d46deb536196a54abb2c2ee02abd914cd385e2")
            set(LLVM_VPTO_PATCH_FILE ${LLVM_DOWNLOAD_PATH}/feature-vpto-last3.patch)
            set(LLVM_VPTO_PATCH_READY TRUE)
            message(STATUS "[ThirdParty][llvm] vpto patch downloaded: ${LLVM_VPTO_PATCH_FILE}")
        else()
            message(FATAL_ERROR "[ThirdParty][llvm] vpto patch SHA256 mismatch (${LLVM_VPTO_DL_SHA256})")
        endif()
    endif()
endif()

if(LLVM_SOURCE_HAS_VPTO)
    message(STATUS "[ThirdParty][llvm] LLVM source already carries SimtEntry, skip vpto patch")
elseif(LLVM_VPTO_PATCH_READY)
    message(STATUS "[ThirdParty][llvm] vpto patch ready: ${LLVM_VPTO_PATCH_FILE}")
else()
    message(WARNING "[ThirdParty][llvm] vpto patch unavailable; PTOAS build may fail with missing SimtEntry")
endif()

# Stub dependency target so third_party_llvm's DEPENDS always resolves,
# even when no patch download is needed.
add_custom_target(llvm_vpto_patch)

set(LLVM_VPTO_PATCH_ARGS "")
if(NOT LLVM_SOURCE_HAS_VPTO AND LLVM_VPTO_PATCH_READY)
    set(LLVM_VPTO_PATCH_ARGS PATCH_COMMAND patch -p1 < ${LLVM_VPTO_PATCH_FILE})
endif()

ExternalProject_Add(third_party_llvm
    URL ${REQ_URL}
    URL_HASH SHA256=59abea1c22e64933fad4de1671a61cdb934098793c7a31b333ff58dc41bff36c
    TIMEOUT 600
    DOWNLOAD_DIR ${LLVM_DOWNLOAD_PATH}
    SOURCE_DIR ${LLVM_SOURCE_PATH}
    ${LLVM_VPTO_PATCH_ARGS}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    EXCLUDE_FROM_ALL TRUE
    DEPENDS llvm_vpto_patch
)
