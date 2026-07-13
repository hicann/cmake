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

if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

include(ExternalProject)
include(GNUInstallDirs)
include(${CMAKE_CURRENT_LIST_DIR}/abseil-cpp.cmake)

# ==========================================================================================================
# 1. Paths & Directories Setup
# ==========================================================================================================
set(PROTOBUF_STATIC_PKG_DIR ${CANN_3RD_LIB_PATH}/lib_cache/protobuf_static)
set(PROTOBUF_SHARED_PKG_DIR ${CANN_3RD_LIB_PATH}/lib_cache/protobuf_shared)
set(PROTOBUF_HOST_STATIC_PKG_DIR ${CANN_3RD_LIB_PATH}/lib_cache/protobuf_host_static)
set(PROTOBUF_HOST_PROTOC_DIR ${CANN_3RD_LIB_PATH}/lib_cache/protoc)

set(LIB_SUB_DIR "lib64")
set(PROTOBUF_STATIC_FILE_NAME "libhost_ascend_protobuf.a")
if(PRODUCT_SIDE STREQUAL "device")
    set(PROTOBUF_STATIC_FILE_NAME "libascend_protobuf.a")
    set(LIB_SUB_DIR "lib64/device/lib64")

    # in device mode, need another path to save lib.
    message("[ThirdParty][protobuf] device mode set protobuf lib path")
    set(PROTOBUF_STATIC_PKG_DIR ${CANN_3RD_LIB_PATH}/lib_cache/device/protobuf_static)
    set(PROTOBUF_SHARED_PKG_DIR ${CANN_3RD_LIB_PATH}/lib_cache/device/protobuf_shared)
    set(PROTOBUF_HOST_STATIC_PKG_DIR ${CANN_3RD_LIB_PATH}/lib_cache/device/protobuf_host_static)
    set(PROTOBUF_HOST_PROTOC_DIR ${CANN_3RD_LIB_PATH}/lib_cache/device/protoc)
endif()

if(DEFINED ENV{ASCEND_HOME_PATH})
    set(LD_LIB_PATHS "$ENV{ASCEND_HOME_PATH}/${LIB_SUB_DIR}")
    set(LD_BIN_PATHS "$ENV{ASCEND_HOME_PATH}/bin")
endif()

# ==========================================================================================================
# 2. Compile Flags & Optimization
# ==========================================================================================================
set(SECURITY_COMPILE_OPT "-Wl,-z,relro,-z,now,-z,noexecstack -s -Wl,-Bsymbolic")
set(DEV_PROTOBUF_SHARED_CXXFLAGS "${SECURITY_COMPILE_OPT} -Wno-maybe-uninitialized -Wno-unused-parameter -fPIC -fstack-protector-all -D_FORTIFY_SOURCE=2 -D_GLIBCXX_USE_CXX11_ABI=1 -O2 -Dgoogle=ascend_private")
set(HOST_PROTOBUF_SHARED_CXXFLAGS "${SECURITY_COMPILE_OPT} -Wno-maybe-uninitialized -Wno-unused-parameter -fPIC -fstack-protector-all -D_FORTIFY_SOURCE=2 -D_GLIBCXX_USE_CXX11_ABI=0 -O2 -Dgoogle=ascend_private")
set(DEV_PROTOBUF_STATIC_CXXFLAGS "-fvisibility=hidden -fvisibility-inlines-hidden -Wno-maybe-uninitialized -Wno-unused-parameter -fPIC -fstack-protector-all -D_FORTIFY_SOURCE=2 -D_GLIBCXX_USE_CXX11_ABI=1 -O2 -Dgoogle=ascend_private")
set(HOST_PROTOBUF_STATIC_CXXFLAGS "-fvisibility=hidden -fvisibility-inlines-hidden -Wno-maybe-uninitialized -Wno-unused-parameter -fPIC -fstack-protector-all -D_FORTIFY_SOURCE=2 -D_GLIBCXX_USE_CXX11_ABI=0 -O2 -Dgoogle=ascend_private")

message("[ThirdParty][protobuf] PRODUCT_SIDE: ${PRODUCT_SIDE}")
message("[ThirdParty][protobuf] CMAKE_TOOLCHAIN_FILE: ${CMAKE_TOOLCHAIN_FILE}")
if(PRODUCT_SIDE STREQUAL "device")
    set(HOST_PROTOBUF_SHARED_CXXFLAGS ${DEV_PROTOBUF_SHARED_CXXFLAGS})
    set(HOST_PROTOBUF_STATIC_CXXFLAGS ${DEV_PROTOBUF_STATIC_CXXFLAGS})
    set(PROTOBUF_TOOLCHAIN_ARGS
        -DTOOLCHAIN_DIR=${TOOLCHAIN_DIR}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    )
elseif(CMAKE_TOOLCHAIN_FILE)
    # used for ge
    set(PROTOBUF_TOOLCHAIN_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DLLVM_PATH=${LLVM_PATH}
    )
else()
    set(PROTOBUF_TOOLCHAIN_ARGS)
endif()

include(${CMAKE_CURRENT_LIST_DIR}/protobuf_sym_rename.cmake)
set(HOST_PROTOBUF_SHARED_CXXFLAGS "${HOST_PROTOBUF_SHARED_CXXFLAGS} ${PROTOBUF_SYM_RENAME}")
set(HOST_PROTOBUF_STATIC_CXXFLAGS "${HOST_PROTOBUF_STATIC_CXXFLAGS} ${PROTOBUF_SYM_RENAME}")

# ==========================================================================================================
# 3. Find Existing Libraries & Protoc
# ==========================================================================================================
find_program(PROTOC_PROGRAM 
    NAMES protoc 
    PATHS ${PROTOBUF_HOST_PROTOC_DIR} ${LD_BIN_PATHS} 
    NO_DEFAULT_PATH
)

find_library(ASCEND_PROTOBUF_STATIC_LIB
    NAMES libascend_protobuf.a
    PATH_SUFFIXES lib lib64
    PATHS ${PROTOBUF_STATIC_PKG_DIR} ${LD_LIB_PATHS}
    NO_DEFAULT_PATH
)

find_path(ASCEND_PROTOBUF_STATIC_INCLUDE
    NAMES google/protobuf/any.h
    PATH_SUFFIXES include
    PATHS ${PROTOBUF_STATIC_PKG_DIR} ${LD_LIB_PATHS}
    NO_DEFAULT_PATH
)

find_library(HOST_PROTOBUF_STATIC_LIB
    NAMES ${PROTOBUF_STATIC_FILE_NAME}
    PATH_SUFFIXES lib lib64
    PATHS ${PROTOBUF_HOST_STATIC_PKG_DIR} ${LD_LIB_PATHS}
    NO_DEFAULT_PATH
)

find_path(HOST_PROTOBUF_STATIC_INCLUDE
    NAMES google/protobuf/any.h
    PATH_SUFFIXES include
    PATHS ${PROTOBUF_HOST_STATIC_PKG_DIR} ${LD_LIB_PATHS}
    NO_DEFAULT_PATH
)

find_library(ASCEND_PROTOBUF_SHARED_LIB
    NAMES libascend_protobuf.so
    PATH_SUFFIXES lib lib64
    PATHS ${PROTOBUF_SHARED_PKG_DIR} ${LD_LIB_PATHS}
    NO_DEFAULT_PATH
)

find_path(ASCEND_PROTOBUF_SHARED_INCLUDE
    NAMES google/protobuf/any.h
    PATH_SUFFIXES include
    PATHS ${PROTOBUF_SHARED_PKG_DIR} ${LD_LIB_PATHS}
    NO_DEFAULT_PATH
)

message("[ThirdParty][protobuf] PROTOC_PROGRAM : ${PROTOC_PROGRAM}.")
message("[ThirdParty][protobuf] ASCEND_PROTOBUF_STATIC_LIB : ${ASCEND_PROTOBUF_STATIC_LIB}.")
message("[ThirdParty][protobuf] HOST_PROTOBUF_STATIC_LIB : ${HOST_PROTOBUF_STATIC_LIB}.")
message("[ThirdParty][protobuf] ASCEND_PROTOBUF_SHARED_LIB : ${ASCEND_PROTOBUF_SHARED_LIB}.")

# 解析 protobuf 源码包路径
if (EXISTS ${CANN_3RD_LIB_PATH}/protobuf-all-25.1.tar.gz)
    set(REQ_URL ${CANN_3RD_LIB_PATH}/protobuf-all-25.1.tar.gz)
elseif (EXISTS ${CANN_3RD_LIB_PATH}/protobuf-25.1.tar.gz)
    set(REQ_URL ${CANN_3RD_LIB_PATH}/protobuf-25.1.tar.gz)
elseif (EXISTS ${CANN_3RD_LIB_PATH}/protobuf/protobuf-all-25.1.tar.gz)
    set(REQ_URL ${CANN_3RD_LIB_PATH}/protobuf/protobuf-all-25.1.tar.gz)
else()
    set(REQ_URL ${CANN_3RD_LIB_PATH}/protobuf/protobuf-25.1.tar.gz)
endif()

if(NOT EXISTS ${REQ_URL})
    message("[ThirdParty][protobuf] ${REQ_URL} not found, need download.")
    set(REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/protobuf/protobuf-25.1.tar.gz")
endif()

# 避免host和device同时编译时下载路径冲突
if(PRODUCT_SIDE STREQUAL "device")
    set(PROTOBUF_DOWNLOAD_DIR ${CANN_3RD_LIB_PATH}/pkg)
else()
    set(PROTOBUF_DOWNLOAD_DIR ${CANN_3RD_LIB_PATH}/protobuf)
endif()

ExternalProject_Add(protobuf_src
    URL ${REQ_URL}
    URL_HASH SHA256=9bd87b8280ef720d3240514f884e56a712f2218f0d693b48050c836028940a42
    DOWNLOAD_DIR ${PROTOBUF_DOWNLOAD_DIR}
    PATCH_COMMAND patch --forward --batch -p1 < ${CMAKE_CURRENT_LIST_DIR}/protobuf_25.1_change_version.patch
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    EXCLUDE_FROM_ALL TRUE
    DEPENDS abseil_build
)

ExternalProject_Get_Property(protobuf_src SOURCE_DIR)
set(PROTOBUF_SRC_DIR ${SOURCE_DIR} CACHE INTERNAL "protobuf src dir")

# ---------------------------------------------------------
# Target: ascend_protobuf (Shared)
# ---------------------------------------------------------
add_library(ascend_protobuf SHARED IMPORTED GLOBAL)
add_library(ascend_protobuf_shared_headers INTERFACE IMPORTED GLOBAL)
if(ASCEND_PROTOBUF_SHARED_INCLUDE AND ASCEND_PROTOBUF_SHARED_LIB)
    message("[ThirdParty][protobuf] protobuf_shared use cache.")
    set_target_properties(ascend_protobuf PROPERTIES
        IMPORTED_LOCATION ${ASCEND_PROTOBUF_SHARED_LIB}
        INTERFACE_INCLUDE_DIRECTORIES ${ASCEND_PROTOBUF_SHARED_INCLUDE}
    )
    set(_ASCEND_PROTOBUF_SHARED_INCLUDE ${ASCEND_PROTOBUF_SHARED_INCLUDE})
else()
    message("[ThirdParty][protobuf] protobuf_shared build.")
    ExternalProject_Add(protobuf_shared_build
        DEPENDS protobuf_src
        SOURCE_DIR ${PROTOBUF_SRC_DIR}
        DOWNLOAD_COMMAND ""
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
            -G ${CMAKE_GENERATOR}
            ${PROTOBUF_TOOLCHAIN_ARGS}
            -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
            -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
            -DCMAKE_POLICY_VERSION_MINIMUM=3.5
            -DCMAKE_INSTALL_LIBDIR=lib
            -DBUILD_SHARED_LIBS=ON
            -DCMAKE_CXX_STANDARD=14
            -Dprotobuf_WITH_ZLIB=OFF
            -DLIB_PREFIX=ascend_
            -DCMAKE_SKIP_RPATH=TRUE
            -Dprotobuf_BUILD_TESTS=OFF
            -DCMAKE_CXX_FLAGS=${HOST_PROTOBUF_SHARED_CXXFLAGS}
            -DCMAKE_INSTALL_PREFIX=${PROTOBUF_SHARED_PKG_DIR}
            -Dprotobuf_BUILD_PROTOC_BINARIES=OFF
            -DABSL_ROOT_DIR=${ABS_INSTALL_DIR}
            <SOURCE_DIR>
        BUILD_COMMAND $(MAKE)
        INSTALL_COMMAND $(MAKE) install
        EXCLUDE_FROM_ALL TRUE
    )
    set(_ASCEND_PROTOBUF_SHARED_INCLUDE ${PROTOBUF_SHARED_PKG_DIR}/include)
    set_target_properties(ascend_protobuf PROPERTIES
        IMPORTED_LOCATION ${PROTOBUF_SHARED_PKG_DIR}/lib/libascend_protobuf.so
        INTERFACE_INCLUDE_DIRECTORIES "${_ASCEND_PROTOBUF_SHARED_INCLUDE}"
    )
    add_dependencies(ascend_protobuf protobuf_shared_build)
    add_dependencies(ascend_protobuf_shared_headers protobuf_shared_build)
endif()
target_include_directories(ascend_protobuf_shared_headers INTERFACE ${PROTOBUF_SHARED_PKG_DIR}/include)
create_imported_interface_include_directories(ascend_protobuf)

# use for runtime: PROTOBUF_SHARED_LIB_DIR
set(PROTOBUF_SHARED_LIB_DIR "${PROTOBUF_SHARED_PKG_DIR}/lib")

# ---------------------------------------------------------
# Target: host_protoc
# ---------------------------------------------------------
add_executable(host_protoc IMPORTED GLOBAL)
if(PROTOC_PROGRAM)
    message("[ThirdParty][protobuf] protoc use cache.")
    set_target_properties(host_protoc PROPERTIES IMPORTED_LOCATION ${PROTOC_PROGRAM})
else()
    message("[ThirdParty][protobuf] protoc build.")
    ExternalProject_Add(protobuf_host_build
        DEPENDS protobuf_src
        SOURCE_DIR ${PROTOBUF_SRC_DIR}
        DOWNLOAD_COMMAND ""
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
            -DCMAKE_CXX_STANDARD=14
            -DCMAKE_POLICY_VERSION_MINIMUM=3.5
            -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
            -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
            -DCMAKE_INSTALL_PREFIX=${PROTOBUF_HOST_PROTOC_DIR}
            -Dprotobuf_BUILD_TESTS=OFF
            -Dprotobuf_WITH_ZLIB=OFF
            -DABSL_ROOT_DIR=${ABS_INSTALL_DIR}
            <SOURCE_DIR>
        BUILD_COMMAND $(MAKE)
        INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory ${PROTOBUF_HOST_PROTOC_DIR}
            COMMAND cp <BINARY_DIR>/protoc ${PROTOBUF_HOST_PROTOC_DIR}/protoc
        EXCLUDE_FROM_ALL TRUE
    )
    set_target_properties(host_protoc PROPERTIES IMPORTED_LOCATION ${PROTOBUF_HOST_PROTOC_DIR}/protoc)
    add_dependencies(host_protoc protobuf_host_build)
endif()
# use for math
set(HOST_PROTOC_SRC ${PROTOBUF_SRC_DIR}/src)
set(HOST_PROTOC_PATH ${PROTOBUF_HOST_PROTOC_DIR})
# used for ge
add_custom_target(protoc DEPENDS host_protoc)

# ---------------------------------------------------------
# Target: ascend_protobuf_static
# ---------------------------------------------------------
add_library(ascend_protobuf_static STATIC IMPORTED GLOBAL)
add_library(ascend_protobuf_static_headers INTERFACE IMPORTED)
if(ASCEND_PROTOBUF_STATIC_INCLUDE AND ASCEND_PROTOBUF_STATIC_LIB)
    message("[ThirdParty][protobuf] protobuf_static use cache.")
    set_target_properties(ascend_protobuf_static PROPERTIES
        IMPORTED_LOCATION ${ASCEND_PROTOBUF_STATIC_LIB}
        INTERFACE_INCLUDE_DIRECTORIES ${ASCEND_PROTOBUF_STATIC_INCLUDE}
    )
    set(_ASCEND_PROTOBUF_STATIC_INCLUDE ${ASCEND_PROTOBUF_STATIC_INCLUDE})
    set(PROTOBUF_STATIC_FINAL_PATH ${ASCEND_PROTOBUF_STATIC_LIB})
else()
    message("[ThirdParty][protobuf] protobuf_static build.")
    ExternalProject_Add(protobuf_static_build
        DEPENDS protobuf_src
        SOURCE_DIR ${PROTOBUF_SRC_DIR}
        DOWNLOAD_COMMAND ""
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
            -G ${CMAKE_GENERATOR}
            ${PROTOBUF_TOOLCHAIN_ARGS}
            -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
            -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
            -DCMAKE_INSTALL_LIBDIR=lib
            -DCMAKE_POLICY_VERSION_MINIMUM=3.5
            -DBUILD_SHARED_LIBS=OFF
            -DCMAKE_CXX_STANDARD=14
            -Dprotobuf_WITH_ZLIB=OFF
            -DLIB_PREFIX=ascend_
            -DCMAKE_SKIP_RPATH=TRUE
            -Dprotobuf_BUILD_TESTS=OFF
            -DCMAKE_CXX_FLAGS=${HOST_PROTOBUF_STATIC_CXXFLAGS}
            -DCMAKE_INSTALL_PREFIX=${PROTOBUF_STATIC_PKG_DIR}
            -Dprotobuf_BUILD_PROTOC_BINARIES=OFF
            -DABSL_COMPILE_OBJ=TRUE
            -DABSL_ROOT_DIR=${ABS_INSTALL_DIR}
            <SOURCE_DIR>
        BUILD_COMMAND $(MAKE)
        INSTALL_COMMAND $(MAKE) install
        EXCLUDE_FROM_ALL TRUE
    )
    set(_ASCEND_PROTOBUF_STATIC_INCLUDE ${PROTOBUF_STATIC_PKG_DIR}/include)
    set_target_properties(ascend_protobuf_static PROPERTIES
        IMPORTED_LOCATION ${PROTOBUF_STATIC_PKG_DIR}/lib/libascend_protobuf.a
        INTERFACE_INCLUDE_DIRECTORIES "${_ASCEND_PROTOBUF_STATIC_INCLUDE}"
    )
    add_dependencies(ascend_protobuf_static protobuf_static_build)
    add_dependencies(ascend_protobuf_static_headers protobuf_static_build)
    set(PROTOBUF_STATIC_FINAL_PATH ${PROTOBUF_STATIC_PKG_DIR}/lib/libascend_protobuf.a)
endif()
target_include_directories(ascend_protobuf_static_headers INTERFACE ${_ASCEND_PROTOBUF_STATIC_INCLUDE})
create_imported_interface_include_directories(ascend_protobuf_static)

# ---------------------------------------------------------
# Target: protobuf_static (Host Static)
# ---------------------------------------------------------
add_library(protobuf_static STATIC IMPORTED GLOBAL)
if(HOST_PROTOBUF_STATIC_INCLUDE AND HOST_PROTOBUF_STATIC_LIB)
    message("[ThirdParty][protobuf] protobuf_host_static use cache.")
    set_target_properties(protobuf_static PROPERTIES 
        IMPORTED_LOCATION ${HOST_PROTOBUF_STATIC_LIB}
        INTERFACE_INCLUDE_DIRECTORIES "${HOST_PROTOBUF_STATIC_INCLUDE}"
    )
    set(PROTOBUF_HOST_STATIC_FINAL_PATH ${HOST_PROTOBUF_STATIC_LIB})
else()
    message("[ThirdParty][protobuf] protobuf_host_static build.")
    ExternalProject_Add(protobuf_host_static_build
        DEPENDS protobuf_src
        SOURCE_DIR ${PROTOBUF_SRC_DIR}
        DOWNLOAD_COMMAND ""
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
            -G ${CMAKE_GENERATOR}
            -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
            -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
            -DCMAKE_INSTALL_LIBDIR=lib
            -DCMAKE_POLICY_VERSION_MINIMUM=3.5
            -DBUILD_SHARED_LIBS=OFF
            -DCMAKE_CXX_STANDARD=14
            -Dprotobuf_WITH_ZLIB=OFF
            -DLIB_PREFIX=host_ascend_
            -DCMAKE_SKIP_RPATH=TRUE
            -Dprotobuf_BUILD_TESTS=OFF
            -DCMAKE_CXX_FLAGS=${HOST_PROTOBUF_STATIC_CXXFLAGS}
            -DCMAKE_INSTALL_PREFIX=${PROTOBUF_HOST_STATIC_PKG_DIR}
            -Dprotobuf_BUILD_PROTOC_BINARIES=OFF
            -DABSL_COMPILE_OBJ=TRUE
            -DABSL_ROOT_DIR=${ABS_INSTALL_DIR}
            <SOURCE_DIR>
        BUILD_COMMAND $(MAKE)
        INSTALL_COMMAND $(MAKE) install
        EXCLUDE_FROM_ALL TRUE
    )

    set_target_properties(protobuf_static PROPERTIES 
        IMPORTED_LOCATION ${PROTOBUF_HOST_STATIC_PKG_DIR}/lib/libhost_ascend_protobuf.a
        INTERFACE_INCLUDE_DIRECTORIES "${PROTOBUF_HOST_STATIC_PKG_DIR}/include"
    )
    add_dependencies(protobuf_static protobuf_host_static_build)
    set(PROTOBUF_HOST_STATIC_FINAL_PATH ${PROTOBUF_HOST_STATIC_PKG_DIR}/lib/libhost_ascend_protobuf.a)
endif()
create_imported_interface_include_directories(protobuf_static)
