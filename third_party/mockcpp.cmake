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

set(open_source_target_name mockcpp)

if (CMAKE_HOST_SYSTEM_PROCESSOR  STREQUAL "aarch64")
    set(mockcpp_CXXFLAGS "-fPIC")
else()
    set(mockcpp_CXXFLAGS "-fPIC -std=c++11")
endif()
set(mockcpp_FLAGS "-fPIC")
set(mockcpp_LINKER_FLAGS "")

if ((NOT DEFINED ABI_ZERO) OR (ABI_ZERO STREQUAL ""))
    set(ABI_ZERO "true")
endif()


if (ABI_ZERO STREQUAL true)
    set(mockcpp_CXXFLAGS "${mockcpp_CXXFLAGS} -D_GLIBCXX_USE_CXX11_ABI=0")
    set(mockcpp_FLAGS "${mockcpp_FLAGS} -D_GLIBCXX_USE_CXX11_ABI=0")
endif()

set(BUILD_WRAPPER ${ASCENDC_TOOLS_ROOT_DIR}/test/cmake/tools/build_ext.sh) # TODO 这个tool在这里是否合适
set(BUILD_TYPE "DEBUG")

if (CMAKE_GENERATOR MATCHES "Unix Makefiles")
    set(IS_MAKE True)
    set(MAKE_CMD "$(MAKE)")
else()
    set(IS_MAKE False)
endif()

#依赖蓝区二进制仓mockcpp
set(FILE_NAME mockcpp-2.7.tar.gz)
set(BOOST_INCLUDE_DIR ${CANN_3RD_LIB_PATH}/boost-1.87.0)
set(MOCKCPP_DOWNLOAD_PATH ${CANN_3RD_LIB_PATH}/pkg)
set(MOCKCPP_SOURCE_PATH ${CANN_3RD_LIB_PATH}/mockcpp)
set(MOCK_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/mockcpp)

message(STATUS "[ThirdPartyLib][mockcpp] cmake install prefix ${CMAKE_INSTALL_PREFIX}")
if (EXISTS "${CANN_3RD_LIB_PATH}/mockcpp-2.7-h5.patch")
    set(PATCH_FILE "${CANN_3RD_LIB_PATH}/mockcpp-2.7-h5.patch")
    message(STATUS "[ThirdPartyLib][mockcpp] patch use cache: ${PATCH_FILE}")
else()
    set(PATCH_FILE ${CANN_3RD_LIB_PATH}/mockcpp-2.7/mockcpp-2.7-h5.patch)
    message(STATUS "[ThirdPartyLib][mockcpp] patch not use cache.")
    file(DOWNLOAD
        "https://gitcode.com/cann-src-third-party/mockcpp/releases/download/v2.7-h5/mockcpp-2.7-h5.patch"
        ${PATCH_FILE}
        TIMEOUT 60
    )
endif()
include(ExternalProject)
message(STATUS, "[ThirdPartyLib][mockcpp] CMAKE_COMMAND is ${CMAKE_COMMAND}")
if (NOT EXISTS ${CANN_3RD_LIB_PATH}/mockcpp/${FILE_NAME})
    if(EXISTS ${CANN_3RD_LIB_PATH}/${FILE_NAME})
        set(URL_FILE ${CANN_3RD_LIB_PATH}/${FILE_NAME})
        message("[ThirdPartyLib][mockcpp] use local tar.gz: ${URL_FILE}")
    else()
        set(URL_FILE "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/mockcpp/mockcpp-2.7.tar.gz")
        message("[ThirdPartyLib][mockcpp] not use cache, new url file: ${URL_FILE}")
    endif()
endif()

ExternalProject_Add(mockcpp_static_build
    URL ${URL_FILE}
    DOWNLOAD_DIR ${CANN_3RD_LIB_PATH}/pkg
    SOURCE_DIR ${MOCKCPP_SOURCE_PATH}
    PATCH_COMMAND git init && git apply ${PATCH_FILE}

    CONFIGURE_COMMAND ${CMAKE_COMMAND} -G ${CMAKE_GENERATOR}
        -DCMAKE_CXX_FLAGS=${mockcpp_CXXFLAGS}
        -DCMAKE_C_FLAGS=${mockcpp_FLAGS}
        -DBOOST_INCLUDE_DIRS=${BOOST_INCLUDE_DIR}
        -DCMAKE_SHARED_LINKER_FLAGS=${mockcpp_LINKER_FLAGS}
        -DCMAKE_EXE_LINKER_FLAGS=${mockcpp_LINKER_FLAGS}
        -DBUILD_32_BIT_TARGET_BY_64_BIT_COMPILER=OFF
        -DCMAKE_INSTALL_PREFIX=${MOCK_INSTALL_PATH}
        <SOURCE_DIR>
    BUILD_COMMAND ${${BUILD_TYPE}} $<$<BOOL:${IS_MAKE}>:$(MAKE)>
)

# use for fix the bug of not exists the include directory
if(NOT EXISTS ${MOCK_INSTALL_PATH}/include)
    file(MAKE_DIRECTORY ${MOCK_INSTALL_PATH}/include)
endif()
message("111111111111111 test")
# use for asc_devkit service
set(MOCKCPP_INCLUDE_ONE ${MOCK_INSTALL_PATH}/include)
set(MOCKCPP_INCLUDE_TWO ${BOOST_INCLUDE_DIR})
set(MOCKCPP_STATIC_LIBRARY ${MOCK_INSTALL_PATH}/lib/libmockcpp.a)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(mockcpp_static_build
    REQUIRED_VARS MOCKCPP_INCLUDE_ONE MOCKCPP_INCLUDE_TWO MOCKCPP_STATIC_LIBRARY
)

set(MOCKCPP_INCLUDE_DIR ${MOCKCPP_INCLUDE_ONE} ${MOCKCPP_INCLUDE_TWO})
get_filename_component(MOCKCPP_LIBRARY_DIR ${MOCKCPP_STATIC_LIBRARY} DIRECTORY)

add_library(mockcpp STATIC IMPORTED)
set_target_properties(mockcpp PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${MOCKCPP_INCLUDE_DIR}"
    IMPORTED_LOCATION "${MOCKCPP_STATIC_LIBRARY}"
)
add_dependencies(mockcpp mockcpp_static_build)