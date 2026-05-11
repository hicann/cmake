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

unset(gtest_FOUND CACHE)
unset(GTEST_INCLUDE CACHE)
unset(GTEST_STATIC_LIBRARY CACHE)
unset(GTEST_MAIN_STATIC_LIBRARY CACHE)
unset(GMOCK_STATIC_LIBRARY CACHE)
unset(GMOCK_MAIN_STATIC_LIBRARY CACHE)

if(NOT CANN_3RD_LIB_PATH)
    set(CANN_3RD_LIB_PATH ${CMAKE_SOURCE_DIR}/third_party)
endif()

set(GTEST_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/gtest-1.14.0)
set(GTEST_DOWNLOAD_PATH ${CANN_3RD_LIB_PATH}/pkg)
message(STATUS "[ThirdPartyLib][gtest] GTEST_INSTALL_PATH=${GTEST_INSTALL_PATH}")
message(STATUS "[ThirdPartyLib][gtest] GTEST_DOWNLOAD_PATH=${GTEST_DOWNLOAD_PATH}")

find_path(GTEST_INCLUDE
    NAMES gtest/gtest.h
    PATHS ${GTEST_INSTALL_PATH}/include
    NO_DEFAULT_PATH
)

find_library(GTEST_STATIC_LIBRARY
    NAMES libgtest.a
    PATH_SUFFIXES lib lib64
    PATHS ${GTEST_INSTALL_PATH}
    NO_DEFAULT_PATH
)

find_library(GTEST_MAIN_STATIC_LIBRARY
    NAMES libgtest_main.a
    PATH_SUFFIXES lib lib64
    PATHS ${GTEST_INSTALL_PATH}
    NO_DEFAULT_PATH
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

message(STATUS "[ThirdPartyLib][gtest] Found GTest: ${gtest_FOUND}")

if(gtest_FOUND AND NOT FORCE_REBUILD_CANN_3RD)
    message(STATUS "[ThirdPartyLib][gtest] GTest found in ${GTEST_INSTALL_PATH}, and not force rebuild")
else()
    set(GTEST_ARCHIVE ${CANN_3RD_LIB_PATH}/gtest/googletest-1.14.0.tar.gz)
    if(EXISTS ${CANN_3RD_LIB_PATH}/googletest-1.14.0.tar.gz AND NOT EXISTS ${GTEST_ARCHIVE})
        message(STATUS "[ThirdPartyLib][gtest] Found googletest archive in ${CANN_3RD_LIB_PATH}, moving to ${CANN_3RD_LIB_PATH}/gtest")
        file(MAKE_DIRECTORY ${CANN_3RD_LIB_PATH}/gtest)
        # adapt the user's offline scene.
        file(RENAME ${CANN_3RD_LIB_PATH}/googletest-1.14.0.tar.gz ${GTEST_ARCHIVE})
    endif()

    # specific service logic in Yellow Zone
    set(GTEST_LOCAL_TAR_SRC "${CANN_3RD_LIB_PATH}/googletest")    
    set(GTEST_LOCAL_SRC "${CANN_3RD_LIB_PATH}/../llt/third_party/gtest/googletest-1.10.x")

    if(EXISTS "${GTEST_ARCHIVE}")
        message(STATUS "[ThirdPartyLib][gtest] Found local gtest archive: ${GTEST_ARCHIVE}")
        set(GTEST_PROJECT_URL ${GTEST_ARCHIVE})
    elseif(EXISTS ${GTEST_LOCAL_SRC})
        message(STATUS "[ThirdPartyLib][gtest] Found local gtest source: ${GTEST_LOCAL_SRC}")
        set(GTEST_PROJECT_URL ${GTEST_LOCAL_SRC})
    else()
        message(STATUS "[ThirdPartyLib][gtest] Downloading GTest.")
        set(GTEST_PROJECT_URL "https://gitcode.com/cann-src-third-party/googletest/releases/download/v1.14.0/googletest-1.14.0.tar.gz")
    endif()

    if(NOT DEFINED USE_CXX11_ABI)
        set(USE_CXX11_ABI 0)
    endif()

    set(GTEST_CXXFLAGS "-D_GLIBCXX_USE_CXX11_ABI=${USE_CXX11_ABI} -O2 -D_FORTIFY_SOURCE=2 -fPIC -fstack-protector-all -Wl,-z,relro,-z,now,-z,noexecstack")
    set(GTEST_CFLAGS "-D_GLIBCXX_USE_CXX11_ABI=${USE_CXX11_ABI} -O2 -D_FORTIFY_SOURCE=2 -fPIC -fstack-protector-all -Wl,-z,relro,-z,now,-z,noexecstack")

    include(ExternalProject)
    # adaptive the gtest upgrade scenario, reset the installation path.
    ExternalProject_Add(third_party_gtest
        URL ${GTEST_PROJECT_URL}
        TLS_VERIFY OFF
        DOWNLOAD_DIR ${GTEST_DOWNLOAD_PATH}
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
            -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
            -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
            -DCMAKE_CXX_FLAGS=${GTEST_CXXFLAGS}
            -DCMAKE_C_FLAGS=${GTEST_CFLAGS}
            -DCMAKE_INSTALL_PREFIX=${GTEST_INSTALL_PATH}
            -DCMAKE_INSTALL_LIBDIR=lib
            -DBUILD_TESTING=OFF
            -DBUILD_SHARED_LIBS=OFF
            <SOURCE_DIR>
        BUILD_COMMAND $(MAKE)
        INSTALL_COMMAND $(MAKE) install
        EXCLUDE_FROM_ALL TRUE
    )
endif()

set(GTEST_INCLUDE ${GTEST_INSTALL_PATH}/include)
if(NOT EXISTS ${GTEST_INCLUDE})
    file(MAKE_DIRECTORY "${GTEST_INCLUDE}")
endif()

add_library(GTest::gtest STATIC IMPORTED)
add_dependencies(GTest::gtest third_party_gtest)
set_target_properties(GTest::gtest PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${GTEST_INCLUDE}
    IMPORTED_LOCATION ${GTEST_INSTALL_PATH}/lib/libgtest.a
)

add_library(GTest::gtest_main STATIC IMPORTED GLOBAL)
add_dependencies(GTest::gtest_main third_party_gtest)
set_target_properties(GTest::gtest_main PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${GTEST_INCLUDE}
    IMPORTED_LOCATION ${GTEST_INSTALL_PATH}/lib/libgtest_main.a
)

add_library(GTest::gmock STATIC IMPORTED GLOBAL)
add_dependencies(GTest::gmock third_party_gtest)
set_target_properties(GTest::gmock PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${GTEST_INCLUDE}
    IMPORTED_LOCATION ${GTEST_INSTALL_PATH}/lib/libgmock.a
)

message(STATUS "[ThirdPartyLib][gtest] configured successfully.")