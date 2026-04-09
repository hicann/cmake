# ------------------------------------------------------------------------------
# Unified GTest Configuration Module
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# ------------------------------------------------------------------------------

include_guard(GLOBAL)
if (NOT ENABLE_TESTS)
    return()
endif()

unset(gtest_FOUND CACHE)
unset(GTEST_INCLUDE CACHE)
unset(GTEST_STATIC_LIBRARY CACHE)
unset(GTEST_MAIN_STATIC_LIBRARY CACHE)
unset(GMOCK_STATIC_LIBRARY CACHE)
unset(GMOCK_MAIN_STATIC_LIBRARY CACHE)

set(GTEST_VERSION "1.14.0")
set(GTEST_INSTALL_PATH ${CANN_3RD_LIB_PATH}/gtest)
set(GTEST_DOWNLOAD_PATH ${CANN_3RD_LIB_PATH}/pkg)
set(GTEST_FILE "googletest-${GTEST_VERSION}.tar.gz")
set(GTEST_URL "https://gitcode.com/cann-src-third-party/googletest/releases/download/v${GTEST_VERSION}/${GTEST_FILE}")

message(STATUS "[GTestUnified] GTEST_VERSION=${GTEST_VERSION}")
message(STATUS "[GTestUnified] GTEST_INSTALL_PATH=${GTEST_INSTALL_PATH}")
message(STATUS "[GTestUnified] GTEST_DOWNLOAD_PATH=${GTEST_DOWNLOAD_PATH}")

find_path(GTEST_INCLUDE
    NAMES gtest/gtest.h
    PATH_SUFFIXES include
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
    PATHS ${GTEST_INSTALL_PATH}
)

find_library(GTEST_STATIC_LIBRARY
    NAMES libgtest.a
    PATH_SUFFIXES lib lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
    PATHS ${GTEST_INSTALL_PATH}
)

find_library(GTEST_MAIN_STATIC_LIBRARY
    NAMES libgtest_main.a
    PATH_SUFFIXES lib lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
    PATHS ${GTEST_INSTALL_PATH}
)

find_library(GMOCK_STATIC_LIBRARY
    NAMES libgmock.a
    PATH_SUFFIXES lib lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
    PATHS ${GTEST_INSTALL_PATH}
)

find_library(GMOCK_MAIN_STATIC_LIBRARY
    NAMES libgmock_main.a
    PATH_SUFFIXES lib lib64
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
    PATHS ${GTEST_INSTALL_PATH}
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(gtest
    FOUND_VAR gtest_FOUND
    REQUIRED_VARS
        GTEST_INCLUDE
        GTEST_STATIC_LIBRARY
        GTEST_MAIN_STATIC_LIBRARY
        GMOCK_STATIC_LIBRARY
        GMOCK_MAIN_STATIC_LIBRARY
)

message(STATUS "[GTestUnified] Found GTest: ${gtest_FOUND}")

if(gtest_FOUND AND NOT FORCE_REBUILD_CANN_3RD)
    message(STATUS "[GTestUnified] GTest found in ${GTEST_INSTALL_PATH}, and not force rebuild")
else()
    set(GTEST_ARCHIVE ${GTEST_DOWNLOAD_PATH}/${GTEST_FILE})
    file(MAKE_DIRECTORY ${GTEST_DOWNLOAD_PATH})

    if(EXISTS ${CANN_3RD_LIB_PATH}/${GTEST_FILE} AND NOT EXISTS ${GTEST_ARCHIVE})
        message(STATUS "[GTestUnified] Found googletest archive in ${CANN_3RD_LIB_PATH}, moving to pkg")
        file(RENAME ${CANN_3RD_LIB_PATH}/${GTEST_FILE} ${GTEST_ARCHIVE})
    endif()

    set(GTEST_LOCAL_TAR_SRC "${CANN_3RD_LIB_PATH}/googletest")
    set(GTEST_LOCAL_SRC "${CANN_3RD_LIB_PATH}/../llt/third_party/gtest/googletest-1.10.x")

    if(EXISTS "${GTEST_ARCHIVE}")
        message(STATUS "[GTestUnified] Found local gtest archive: ${GTEST_ARCHIVE}")
        set(GTEST_PROJECT_URL "file://${GTEST_ARCHIVE}")
        
        file(MAKE_DIRECTORY "${GTEST_LOCAL_TAR_SRC}")
        execute_process(
            COMMAND tar xzf "${GTEST_ARCHIVE}" -C "${GTEST_LOCAL_TAR_SRC}" --strip-components=1
            RESULT_VARIABLE EXTRACT_RESULT
            ERROR_VARIABLE EXTRACT_ERROR
        )

        if(NOT EXTRACT_RESULT EQUAL 0)
            message(FATAL_ERROR "[GTestUnified] Failed to extract local gtest archive: ${EXTRACT_ERROR}")
        endif()
        message(STATUS "[GTestUnified] Local gtest archive extracted successfully to ${GTEST_LOCAL_TAR_SRC}")
    elseif(EXISTS ${GTEST_LOCAL_SRC})
        message(STATUS "[GTestUnified] Found local gtest source: ${GTEST_LOCAL_SRC}")
        set(GTEST_PROJECT_URL ${GTEST_LOCAL_SRC})
    else()
        message(STATUS "[GTestUnified] Downloading GTest from ${GTEST_URL}")
        set(GTEST_PROJECT_URL ${GTEST_URL})
    endif()

    if(NOT DEFINED USE_CXX11_ABI)
        set(USE_CXX11_ABI 0)
    endif()

    set(GTEST_CXXFLAGS "-D_GLIBCXX_USE_CXX11_ABI=${USE_CXX11_ABI} -O2 -D_FORTIFY_SOURCE=2 -fPIC -fstack-protector-all -Wl,-z,relro,-z,now,-z,noexecstack")
    set(GTEST_CFLAGS "-D_GLIBCXX_USE_CXX11_ABI=${USE_CXX11_ABI} -O2 -D_FORTIFY_SOURCE=2 -fPIC -fstack-protector-all -Wl,-z,relro,-z,now,-z,noexecstack")

    set(GTEST_OPTS
        -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
        -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
        -DCMAKE_CXX_FLAGS=${GTEST_CXXFLAGS}
        -DCMAKE_C_FLAGS=${GTEST_CFLAGS}
        -DCMAKE_INSTALL_PREFIX=${GTEST_INSTALL_PATH}
        -DCMAKE_INSTALL_LIBDIR=lib
        -DBUILD_TESTING=OFF
        -DBUILD_SHARED_LIBS=OFF
    )

    include(ExternalProject)
    if(EXISTS ${GTEST_LOCAL_SRC})
        ExternalProject_Add(third_party_gtest
            SOURCE_DIR ${GTEST_LOCAL_SRC}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${GTEST_OPTS} <SOURCE_DIR>
            BUILD_COMMAND $(MAKE)
            INSTALL_COMMAND $(MAKE) install
            EXCLUDE_FROM_ALL TRUE
        )
    elseif(EXISTS "${GTEST_ARCHIVE}")
        ExternalProject_Add(third_party_gtest
            SOURCE_DIR ${GTEST_LOCAL_TAR_SRC}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${GTEST_OPTS} <SOURCE_DIR>
            BUILD_COMMAND $(MAKE)
            INSTALL_COMMAND $(MAKE) install
            EXCLUDE_FROM_ALL TRUE
        )
    else()
        ExternalProject_Add(third_party_gtest
            URL ${GTEST_PROJECT_URL}
            URL_HASH SHA256=8ad598c73ad796e0d8280b082cebd82a630d73e73cd3c70057938a6501bba5d7
            TLS_VERIFY OFF
            DOWNLOAD_DIR ${GTEST_DOWNLOAD_PATH}
            DOWNLOAD_NO_PROGRESS TRUE
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${GTEST_OPTS} <SOURCE_DIR>
            BUILD_COMMAND $(MAKE)
            INSTALL_COMMAND $(MAKE) install
            EXCLUDE_FROM_ALL TRUE
        )
    endif()
endif()

set(GTEST_INCLUDE ${GTEST_INSTALL_PATH}/include)

add_library(GTest::gtest STATIC IMPORTED GLOBAL)
add_library(GTest::gmock STATIC IMPORTED GLOBAL)
add_library(GTest::gtest_main STATIC IMPORTED GLOBAL)

if(NOT gtest_FOUND OR FORCE_REBUILD_CANN_3RD)
    add_dependencies(GTest::gtest third_party_gtest)
    add_dependencies(GTest::gmock third_party_gtest)
    add_dependencies(GTest::gtest_main third_party_gtest)
endif()

if(NOT EXISTS ${GTEST_INSTALL_PATH}/include)
    file(MAKE_DIRECTORY "${GTEST_INSTALL_PATH}/include")
endif()

set_target_properties(GTest::gtest PROPERTIES
    IMPORTED_LOCATION ${GTEST_INSTALL_PATH}/lib/libgtest.a
    INTERFACE_INCLUDE_DIRECTORIES ${GTEST_INSTALL_PATH}/include
)

set_target_properties(GTest::gmock PROPERTIES
    IMPORTED_LOCATION ${GTEST_INSTALL_PATH}/lib/libgmock.a
    INTERFACE_INCLUDE_DIRECTORIES ${GTEST_INSTALL_PATH}/include
)


set_target_properties(GTest::gtest_main PROPERTIES
    IMPORTED_LOCATION ${GTEST_INSTALL_PATH}/lib/libgtest_main.a
    INTERFACE_INCLUDE_DIRECTORIES ${GTEST_INSTALL_PATH}/include
)
message(STATUS "[GTestUnified] GTest configured successfully")