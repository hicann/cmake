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

# grpc config
set(GRPC_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/grpc)

find_path(PROTOBUF_GRPC_INCLUDE
    NAMES google/protobuf/api.pb.h
    PATH_SUFFIXES include
    PATHS ${GRPC_INSTALL_PATH}
    NO_DEFAULT_PATH
)

find_library(PROTOBUF_GRPC_LIBRARY
    NAMES libprotobuf.a
    PATH_SUFFIXES lib lib64
    PATHS ${GRPC_INSTALL_PATH}
    NO_DEFAULT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(grpc
    FOUND_VAR
        grpc_FOUND
    REQUIRED_VARS
        PROTOBUF_GRPC_INCLUDE
        PROTOBUF_GRPC_LIBRARY
)

if(grpc_FOUND)
    message(STATUS "[ThirdPartyLib][grpc] grpc found, skip compiling.")
else()
    message(STATUS "[ThirdPartyLib][grpc] grpc not found, finding binary file.")

    set(REQ_URL "${CANN_3RD_LIB_PATH}/grpc/grpc-1.60.0.tar.gz")
    # 初始化可选参数列表
    set(GRPC_EXTRA_ARGS "")
    if(EXISTS ${REQ_URL})
        message(STATUS "[ThirdPartyLib][grpc] ${REQ_URL} found.")
    else()
        message(STATUS "[ThirdPartyLib][grpc] ${REQ_URL} not found, need download.")
        set(REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/grpc/grpc-1.60.0.tar.gz")
        list(APPEND GRPC_EXTRA_ARGS
            DOWNLOAD_DIR ${CANN_3RD_LIB_PATH}/pkg
        )
    endif()
    
    set(GRPC_CXX_FLAGS "-Wl,-z,relro,-z,now,-z,noexecstack -D_FORTIFY_SOURCE=2 -O2 -fstack-protector-all -s -D_GLIBCXX_USE_CXX11_ABI=${USE_CXX11_ABI}")
    ExternalProject_Add(grpc_build
                        URL ${REQ_URL}
                        TLS_VERIFY OFF
                        ${GRPC_EXTRA_ARGS}
                        PATCH_COMMAND ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/third_party/opencensus-proto/src
                            COMMAND ${CMAKE_COMMAND} -E copy_directory ${CANN_3RD_LIB_PATH}/lib_cache/zlib <SOURCE_DIR>/third_party/zlib
                            # 低版本cmake无法通过DRE2_ROOT_DIR找到re2路径，拷贝一份到build路径下
                            COMMAND ${CMAKE_COMMAND} -E copy_directory ${CANN_3RD_LIB_PATH}/lib_cache/re2/re2 <SOURCE_DIR>/re2
                            COMMAND patch -p1 < ${CMAKE_CURRENT_LIST_DIR}/grpc-fix-compile-bug-in-device.patch
                        CONFIGURE_COMMAND ${CMAKE_COMMAND}
                            # zlib
                            -DgRPC_ZLIB_PROVIDER=module
                            # cares
                            -DgRPC_CARES_PROVIDER=module
                            -DCARES_ROOT_DIR=${CANN_3RD_LIB_PATH}/lib_cache/c-ares
                            -DCARES_BUILD_TOOLS=OFF
                            # re2
                            -DgRPC_RE2_PROVIDER=module
                            -DRE2_ROOT_DIR=${CANN_3RD_LIB_PATH}/lib_cache/re2
                            # absl
                            -DgRPC_ABSL_PROVIDER=module
                            -DABSL_ROOT_DIR=${CANN_3RD_LIB_PATH}/lib_cache/abseil-cpp
                            # protobuf
                            -DgRPC_PROTOBUF_PROVIDER=module
                            -DPROTOBUF_ROOT_DIR=${CANN_3RD_LIB_PATH}/protobuf_static/build
                            -Dprotobuf_BUILD_PROTOC_BINARIES=OFF
                            # ssl
                            -DgRPC_SSL_PROVIDER=package
                            -DOPENSSL_ROOT_DIR=${CANN_3RD_LIB_PATH}/lib_cache/openssl
                            -DOPENSSL_USE_STATIC_LIBS=TRUE
                            # grpc option
                            -DCMAKE_POLICY_VERSION_MINIMUM=3.5
                            -DCMAKE_CXX_STANDARD=14
                            -DCMAKE_CXX_FLAGS=${GRPC_CXX_FLAGS}
                            -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
                            -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
                            -DCMAKE_BUILD_TYPE=Release
                            -DgRPC_BUILD_TESTS=OFF
                            -DCMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR}
                            -DLLVM_PATH=${LLVM_PATH}
                            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
                            -DgRPC_BUILD_CSHARP_EXT=OFF
                            -DgRPC_BUILD_CODEGEN=OFF
                            -DgRPC_BUILD_GRPC_CPP_PLUGIN=OFF
                            -DCMAKE_INSTALL_PREFIX=${GRPC_INSTALL_PATH}
                            <SOURCE_DIR>
                        BUILD_COMMAND $(MAKE)
                        INSTALL_COMMAND $(MAKE) install && ${CMAKE_COMMAND} -E touch ${GRPC_INSTALL_PATH}/lib/cmake/grpc/gRPCPluginTargets.cmake
                        EXCLUDE_FROM_ALL TRUE
    )
    set(PROTOBUF_GRPC_INCLUDE "${GRPC_INSTALL_PATH}/include")
    set(PROTOBUF_GRPC_LIBRARY "${GRPC_INSTALL_PATH}/lib")
    add_dependencies(grpc_build openssl_project re2_build zlib_bin_build cares_build abseil_build protobuf_static_build)
endif()

set(PROTOBUF_GRPC_INCLUDE_DIR ${PROTOBUF_GRPC_INCLUDE})
message(STATUS "[ThirdPartyLib][grpc] PROTOBUF_GRPC_INCLUDE:${PROTOBUF_GRPC_INCLUDE}, PROTOBUF_GRPC_LIBRARY:${PROTOBUF_GRPC_LIBRARY}.")
if(NOT TARGET protobuf::libprotobuf)
    add_library(protobuf::libprotobuf STATIC IMPORTED)
    set_target_properties(protobuf::libprotobuf PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${PROTOBUF_GRPC_INCLUDE}"
        IMPORTED_LOCATION             "${PROTOBUF_GRPC_LIBRARY}"
    )
else()
    message(STATUS "[ThirdPartyLib][grpc] protobuf::libprotobuf already exist.")
endif()

# protoc_grpc config
set(PROTOC_GRPC_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/protoc_grpc)

find_program(GRPC_CPP_PLUGIN_PROGRAM
    NAMES grpc_cpp_plugin
    PATHS ${PROTOC_GRPC_INSTALL_PATH}
    NO_DEFAULT_PATH)

if(GRPC_CPP_PLUGIN_PROGRAM)
    set(protoc_grpc_FOUND TRUE)
else()
    set(protoc_grpc_FOUND FALSE)
endif()

if(protoc_grpc_FOUND)
    message(STATUS "[ThirdPartyLib][protoc grpc] protoc_grpc found, skip compiling.")
else()
    message(STATUS "[ThirdPartyLib][protoc grpc] protoc_grpc not found, finding binary file.")
    set(REQ_URL "${CANN_3RD_LIB_PATH}/grpc/grpc-1.60.0.tar.gz")
    # 初始化可选参数列表
    set(GRPC_EXTRA_ARGS "")
    if(EXISTS ${REQ_URL})
        message(STATUS "[ThirdPartyLib][protoc grpc] ${REQ_URL} found, start compile.")
    else()
        message(STATUS "[ThirdPartyLib][protoc grpc] ${REQ_URL} not found, need download.")
        set(REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/grpc/grpc-1.60.0.tar.gz")
        list(APPEND GRPC_EXTRA_ARGS
            DOWNLOAD_DIR ${CANN_3RD_LIB_PATH}/pkg
        )
    endif()

    set(GRPC_CXX_FLAGS "-Wl,-z,relro,-z,now,-z,noexecstack -D_FORTIFY_SOURCE=2 -O2 -fstack-protector-all -s -D_GLIBCXX_USE_CXX11_ABI=${USE_CXX11_ABI}")

    ExternalProject_Add(protoc_grpc_build
                        URL ${REQ_URL}
                        TLS_VERIFY OFF
                        ${GRPC_EXTRA_ARGS}
                        PATCH_COMMAND ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/third_party/opencensus-proto/src
                            COMMAND patch -p1 < ${CMAKE_CURRENT_LIST_DIR}/grpc-fix-compile-bug-in-device.patch
                        CONFIGURE_COMMAND ${CMAKE_COMMAND}
                            # zlib
                            -DgRPC_ZLIB_PROVIDER=none
                            # cares
                            -DgRPC_CARES_PROVIDER=module
                            -DCARES_ROOT_DIR=${CANN_3RD_LIB_PATH}/lib_cache/c-ares
                            # re2
                            -DgRPC_RE2_PROVIDER=module
                            -DRE2_ROOT_DIR=${CANN_3RD_LIB_PATH}/lib_cache/re2
                            # absl
                            -DgRPC_ABSL_PROVIDER=module
                            -DABSL_ROOT_DIR=${CANN_3RD_LIB_PATH}/lib_cache/abseil-cpp
                            # protobuf
                            -DgRPC_PROTOBUF_PROVIDER=module
                            -DPROTOBUF_ROOT_DIR=${CANN_3RD_LIB_PATH}/protobuf_static/build
                            # ssl
                            -DgRPC_SSL_PROVIDER=none
                            # grpc option
                            -DCMAKE_POLICY_VERSION_MINIMUM=3.5
                            -DCMAKE_CXX_STANDARD=14
                            -DCMAKE_CXX_FLAGS=${GRPC_CXX_FLAGS}
                            -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
                            -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
                            -DCMAKE_BUILD_TYPE=Release
                            -DgRPC_BUILD_TESTS=OFF
                            -DCMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR}
                            -DgRPC_BUILD_CSHARP_EXT=OFF
                            -DCMAKE_INSTALL_PREFIX=${PROTOC_GRPC_INSTALL_PATH}
                            <SOURCE_DIR>
                        BUILD_COMMAND $(MAKE) protoc grpc_cpp_plugin
                        INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory ${PROTOC_GRPC_INSTALL_PATH} && ${CMAKE_COMMAND} -E copy <BINARY_DIR>/grpc_cpp_plugin ${PROTOC_GRPC_INSTALL_PATH}
                        EXCLUDE_FROM_ALL TRUE
    )

    add_dependencies(protoc_grpc_build re2_build cares_build abseil_build protobuf_static_build)
endif()

message(STATUS "[ThirdPartyLib][protoc grpc] grpc_cpp_plugin:${PROTOC_GRPC_INSTALL_PATH}.")
if(NOT TARGET grpc_cpp_plugin)
    add_executable(grpc_cpp_plugin IMPORTED)
    set_target_properties(grpc_cpp_plugin PROPERTIES
        IMPORTED_LOCATION "${PROTOC_GRPC_INSTALL_PATH}"
    )
else()
    message(STATUS "[ThirdPartyLib][protoc grpc] grpc_cpp_plugin already exist.")
endif()