# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

string(REPLACE ";" "::" EP_HOST_PACKAGE "${PACKAGE}")
string(REPLACE ";" "::" EP_FEATURE_LIST "${FEATURE_LIST}")

ExternalProject_Add(host
    SOURCE_DIR ${TOP_DIR}
    CMAKE_ARGS
        -DPRODUCT_SIDE=host
        -DPACKAGE=${EP_HOST_PACKAGE}
        -DENABLE_ASAN=${ENABLE_ASAN}
        -D FEATURE_LIST=${EP_FEATURE_LIST}
        -DCMAKE_TOOLCHAIN_FILE=${HOST_TOOLCHAIN_FILE}
        -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/host
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DENABLE_CCACHE=${ENABLE_CCACHE}
    -DENABLE_OPEN_SRC=True
    -DENABLE_UNIFIED_BUILD=TRUE
        -DOPEN_SOURCE_DIR=${TOP_DIR}/open_source
    -DASCEND_3RD_LIB_PATH=${TOP_DIR}/open_source
        -G ${CMAKE_GENERATOR}
    BUILD_COMMAND ${BUILD_WRAPPER} all_pkgs ${CMAKE_BUILD_TYPE} <<<BOOL:${USING_MAKE}:$(MAKE)>
    INSTALL_COMMAND ${CMAKE_COMMAND} --install . --component ${PACKAGE} --config ${CMAKE_BUILD_TYPE}
    LIST_SEPARATOR ::
    BUILD_ALWAYS TRUE
    EXCLUDE_FROM_ALL TRUE
)

ExternalProject_Add_Step(host cmake_file_api_query
    COMMAND ${CMAKE_COMMAND} -E make_directory <BINARY_DIR>/.cmake/api/v1/query
    COMMAND ${CMAKE_COMMAND} -E touch <BINARY_DIR>/.cmake/api/v1/query/codemodel-v2
    DEPENDEES patch
    DEPENDERS configure
)

add_dependencies(all_compile host)