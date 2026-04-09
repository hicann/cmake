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

set(BENCHMARK_CMAKE_PATH ${ASCEND_3RD_LIB_PATH}/benchmark-1.8.3/lib/cmake/benchmark/benchmarkConfig.cmake)
if(EXISTS ${BENCHMARK_CMAKE_PATH})
    message(STATUS "[ThirdPartyLib][benchmark] ${BENCHMARK_CMAKE_PATH} found, benchmark is ready after compile.")
    find_package(benchmark CONFIG REQUIRED)
else()
    message(STATUS "[ThirdPartyLib][benchmark] ${BENCHMARK_CMAKE_PATH} not found, benchmark download.")
    set(BENCHMARK_FILE_PATH ${ASCEND_3RD_LIB_PATH}/benchmark-1.8.3)
    set(REQ_URL "${CMAKE_THIRD_PARTY_LIB_DIR}/benchmark/benchmark-1.8.3.tar.gz")
    set(BENCHMARK_EXTRA_ARGS "")
    if(EXISTS ${REQ_URL})
        message(STATUS "[ThirdPartyLib][benchmark] ${REQ_URL} found.")
    else()
        message(STATUS "[ThirdPartyLib][benchmark] ${REQ_URL} not found, need download.")
        set(REQ_URL "https://gitcode.com/cann-src-third-party/benchmark/releases/download/v1.8.3/benchmark-1.8.3.tar.gz")
        list(APPEND BENCHMARK_EXTRA_ARGS
             DOWNLOAD_DIR ${BENCHMARK_FILE_PATH}
        )
    endif()

    set(benchmark_CXXFLAGS "-D_GLIBCXX_USE_CXX11_ABI=${USE_CXX11_ABI} -D_FORTIFY_SOURCE=2 -O2 -fstack-protector-all -Wl,-z,relro,-z,now,-z,noexecstack")
    include(ExternalProject)
    ExternalProject_Add(benchmark_build
                        URL ${REQ_URL}
                        TLS_VERIFY OFF
                        ${BENCHMARK_EXTRA_ARGS}
                        CONFIGURE_COMMAND ${CMAKE_COMMAND}
                            -DBENCHMARK_ENABLE_GTEST_TESTS=OFF
                            -DCMAKE_BUILD_TYPE=Release
                            -DCMAKE_CXX_FLAGS=${benchmark_CXXFLAGS}
                            -DCMAKE_INSTALL_PREFIX=${BENCHMARK_FILE_PATH}
                            -DCMAKE_INSTALL_LIBDIR=${CMAKE_BINARY_DIR}
                            -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
                            -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
                            -DCMAKE_POSITION_INDEPENDENT_CODE=ON
                            -DBUILD_SHARED_LIBS=ON
                            -DCMAKE_MACOSX_RPATH=TRUE
                            <SOURCE_DIR>
                        BUILD_COMMAND $(MAKE)
                        INSTALL_COMMAND $(MAKE) install
                        EXCLUDE_FROM_ALL TRUE
    )

    if (NOT EXISTS ${BENCHMARK_FILE_PATH}/include)
        file(MAKE_DIRECTORY "${BENCHMARK_FILE_PATH}/include")
    endif ()
    # Create imported target benchmark::benchmark
    add_library(benchmark::benchmark SHARED IMPORTED)
    add_dependencies(benchmark::benchmark benchmark_build)
    set_target_properties(benchmark::benchmark PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES ${BENCHMARK_FILE_PATH}/include
        INTERFACE_LINK_LIBRARIES ${BENCHMARK_FILE_PATH}/lib/libbenchmark.so
    )

    # Create imported target benchmark::benchmark_main
    add_library(benchmark::benchmark_main SHARED IMPORTED)
    add_dependencies(benchmark::benchmark_main benchmark::benchmark_main)
    set_target_properties(benchmark::benchmark_main PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${BENCHMARK_FILE_PATH}/include"
        INTERFACE_LINK_LIBRARIES "benchmark::benchmark"
    )
endif()
