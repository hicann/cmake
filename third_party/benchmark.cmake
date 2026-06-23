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

set(BENCHMARK_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/benchmark)
set(BENCHMARK_DOWNLOAD_PATH ${CANN_3RD_LIB_PATH}/benchmark)
set(BENCHMARK_SHARED_LLIBRARY_DIR ${BENCHMARK_INSTALL_PATH}/lib/libbenchmark.so)
set(BENCHMARK_INCLUDE_DIR ${BENCHMARK_INSTALL_PATH}/incldue)
if(NOT EXISTS ${BENCHMARK_INCLUDE_DIR})
    file(MAKE_DIRECTORY "${BENCHMARK_INCLUDE_DIR}")
endif()

add_library(benchmark::benchmark SHARED IMPORTED)
set_target_properties(benchmark::benchmark PROPERTIES
    IMPORTED_LOCATION "${BENCHMARK_SHARED_LLIBRARY_DIR}"
    INTERFACE_INCLUDE_DIRECTORIES "${BENCHMARK_INCLUDE_DIR}"
)

if(EXISTS ${BENCHMARK_SHARED_LLIBRARY_DIR})
    message(STATUS "[ThirdParty][benchmark] benchmark found in: ${BENCHMARK_SHARED_LLIBRARY_DIR}")
    return()
endif()

message(STATUS "[ThirdParty][benchmark] benchmark not found, finding binary file.")

set(REQ_URL "${BENCHMARK_DOWNLOAD_PATH}/benchmark-1.8.3.tar.gz")
set(BENCHMARK_EXTRA_ARGS "")
if(EXISTS ${REQ_URL})
    message(STATUS "[ThirdParty][benchmark] ${REQ_URL} found.")
else()
    message(STATUS "[ThirdParty][benchmark] ${REQ_URL} not found, need download.")
    set(REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/benchmark/benchmark-1.8.3.tar.gz")
    list(APPEND BENCHMARK_EXTRA_ARGS
        DOWNLOAD_DIR ${CANN_3RD_LIB_PATH}/pkg
    )
endif()

include(ExternalProject)
set(benchmark_CXXFLAGS "-D_GLIBCXX_USE_CXX11_ABI=${USE_CXX11_ABI} -D_FORTIFY_SOURCE=2 -O2 -fstack-protector-all -Wl,-z,relro,-z,now,-z,noexecstack")
ExternalProject_Add(benchmark_build
    URL ${REQ_URL}
    URL_HASH SHA256=6bc180a57d23d4d9515519f92b0c83d61b05b5bab188961f36ac7b06b0d9e9ce
    ${BENCHMARK_EXTRA_ARGS}
    CONFIGURE_COMMAND ${CMAKE_COMMAND}
        -DBENCHMARK_ENABLE_GTEST_TESTS=OFF
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_CXX_FLAGS=${benchmark_CXXFLAGS}
        -DCMAKE_INSTALL_PREFIX=${BENCHMARK_INSTALL_PATH}
        -DCMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR}
        -DLLVM_PATH=${LLVM_PATH}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        -DBUILD_SHARED_LIBS=ON
        -DCMAKE_MACOSX_RPATH=TRUE
        <SOURCE_DIR>
    BUILD_COMMAND $(MAKE)
    INSTALL_COMMAND $(MAKE) install
    EXCLUDE_FROM_ALL TRUE
)
add_dependencies(benchmark::benchmark benchmark_build)
