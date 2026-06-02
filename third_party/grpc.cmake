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

include(${CMAKE_CURRENT_LIST_DIR}/openssl.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/re2.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/zlib.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cares.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/abseil-cpp.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/protobuf.cmake)
find_package(Threads)

# grpc config
set(GRPC_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/grpc)

set(GRPC_INCLUDE_DIR ${GRPC_INSTALL_PATH}/include)
if(NOT EXISTS ${GRPC_INCLUDE_DIR})
    file(MAKE_DIRECTORY "${GRPC_INCLUDE_DIR}")
endif()
set(GRPC_STATIC_LIB ${GRPC_INSTALL_PATH}/lib/libgrpc.a)
set(GRPCXX_STATIC_LIB ${GRPC_INSTALL_PATH}/lib/libgrpc++.a)
 
set(GRPC_INTERFACE_LINK_LIBRARIES
    ${GRPC_INSTALL_PATH}/lib/libupb_collections_lib.a
    ${GRPC_INSTALL_PATH}/lib/libupb_json_lib.a
    ${GRPC_INSTALL_PATH}/lib/libupb_textformat_lib.a
    ${GRPC_INSTALL_PATH}/lib/libutf8_range_lib.a
    ${GRPC_INSTALL_PATH}/lib/libupb.a
    ${GRPC_INSTALL_PATH}/lib/libre2.a
    ${GRPC_INSTALL_PATH}/lib/libz.a
    ${GRPC_INSTALL_PATH}/lib/libcares.a
    ${GRPC_INSTALL_PATH}/lib/libgpr.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_random_distributions.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_random_seed_sequences.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_random_internal_pool_urbg.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_random_internal_randen.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_random_internal_randen_hwaes.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_random_internal_randen_hwaes_impl.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_random_internal_randen_slow.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_random_internal_platform.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_random_internal_seed_material.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_random_seed_gen_exception.a
    ${GRPC_INSTALL_PATH}/lib/libaddress_sorting.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_statusor.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_internal_check_op.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_leak_check.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_die_if_null.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_internal_conditions.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_internal_message.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_internal_nullguard.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_examine_stack.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_internal_format.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_internal_proto.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_internal_log_sink_set.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_sink.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_entry.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_flags.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_flags_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_flags_marshalling.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_flags_reflection.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_flags_config.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_flags_program_name.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_flags_private_handle_accessor.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_flags_commandlineflag.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_flags_commandlineflag_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_initialize.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_globals.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_internal_globals.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_raw_hash_set.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_hash.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_city.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_low_level_hash.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_hashtablez_sampler.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_status.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_cord.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_cordz_info.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_cord_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_cordz_functions.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_exponential_biased.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_cordz_handle.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_crc_cord_state.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_crc32c.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_crc_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_crc_cpu_detect.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_bad_optional_access.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_str_format_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_strerror.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_synchronization.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_stacktrace.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_symbolize.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_debugging_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_demangle_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_graphcycles_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_kernel_timeout_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_malloc_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_time.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_civil_time.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_time_zone.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_bad_variant_access.a
    ${GRPC_INSTALL_PATH}/lib/libutf8_validity.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_strings.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_int128.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_string_view.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_throw_delegate.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_strings_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_base.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_spinlock_wait.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_raw_logging_internal.a
    ${GRPC_INSTALL_PATH}/lib/libabsl_log_severity.a
)
 	 
add_library(gRPC::grpc STATIC IMPORTED)
set_target_properties(gRPC::grpc PROPERTIES
    IMPORTED_LOCATION "${GRPC_STATIC_LIB}"
    INTERFACE_INCLUDE_DIRECTORIES "${GRPC_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "dl;m;Threads::Threads;rt;${GRPC_INTERFACE_LINK_LIBRARIES};OpenSSL::SSL;OpenSSL::Crypto"
)
 	 
add_library(gRPC::grpc++ STATIC IMPORTED)
set_target_properties(gRPC::grpc++ PROPERTIES
    IMPORTED_LOCATION "${GRPCXX_STATIC_LIB}"
    INTERFACE_INCLUDE_DIRECTORIES "${GRPC_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "dl;m;Threads::Threads;rt;gRPC::grpc;${GRPC_INSTALL_PATH}/lib/libprotobuf.a"
)
 	 
if(EXISTS ${GRPC_STATIC_LIB} AND EXISTS ${GRPCXX_STATIC_LIB})
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
                            # 低版本cmake无法通过DRE2_ROOT_DIR找到re2路径，拷贝一份到build路径下
                            COMMAND ${CMAKE_COMMAND} -E copy_directory ${CANN_3RD_LIB_PATH}/lib_cache/re2/re2 <SOURCE_DIR>/re2
                            COMMAND patch -p1 < ${CMAKE_CURRENT_LIST_DIR}/grpc-fix-compile-bug-in-device.patch
                        CONFIGURE_COMMAND ${CMAKE_COMMAND}
                            # zlib
                            -DgRPC_ZLIB_PROVIDER=module
                            -DZLIB_ROOT_DIR=${ZLIB_SRC_DIR}
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
                            -DPROTOBUF_ROOT_DIR=${PROTOBUF_SRC_DIR}
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
    add_dependencies(grpc_build openssl_project re2_build zlib_src cares_build abseil_build protobuf_src)
    add_dependencies(gRPC::grpc grpc_build)
    add_dependencies(gRPC::grpc++ grpc_build)
endif()

# protoc_grpc config
set(PROTOC_GRPC_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/protoc_grpc)
set(GRPC_CPP_PLUGIN_PROGRAM ${PROTOC_GRPC_INSTALL_PATH}/grpc_cpp_plugin)

add_executable(grpc_cpp_plugin IMPORTED)
set_target_properties(grpc_cpp_plugin PROPERTIES
    IMPORTED_LOCATION "${GRPC_CPP_PLUGIN_PROGRAM}"
)

if(EXISTS ${GRPC_CPP_PLUGIN_PROGRAM})
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
                            -DPROTOBUF_ROOT_DIR=${PROTOBUF_SRC_DIR}
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
    add_dependencies(protoc_grpc_build re2_build cares_build abseil_build protobuf_src)
    add_dependencies(grpc_cpp_plugin protoc_grpc_build)
endif()
