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
if(TARGET intf_pub)
    return()
endif()

add_library(intf_pub_base INTERFACE)

target_compile_options(intf_pub_base INTERFACE
    -fPIC
    -pipe
    -Wall
    -Wextra
    -Wfloat-equal
    -fno-common
    -fstack-protector-strong
    $<$<BOOL:${ENABLE_ASAN}>:-fsanitize=address -fsanitize-recover=address -fno-stack-protector -fno-omit-frame-pointer -g>
    $<$<BOOL:${ENABLE_TSAN}>:-fsanitize=thread -fno-omit-frame-pointer -g>
    $<$<BOOL:${ENABLE_UBSAN}>:-fsanitize=undefined -fno-sanitize=alignment -g>
    $<$<BOOL:${ENABLE_GCOV}>:--coverage>
)

# 增强告警选项，仅当 ENABLE_STRICT_WARNINGS 开启时生效。
# 单仓编译：组件 set(ENABLE_STRICT_WARNINGS ON) 后调用 add_cann_target_options（首次 include intf_pub）即生效。
# 多仓联编：通过命令行 -DENABLE_STRICT_WARNINGS=ON 整体控制（首次 include 时展开固化）。
if(ENABLE_STRICT_WARNINGS)
    target_compile_options(intf_pub_base INTERFACE
        -Wformat=2
        -Wformat-overflow=2
        -Wformat-truncation=2
        -Wduplicated-cond
        -Wlogical-op
        -Winit-self
        -Wtrampolines
        -Wshift-overflow=2
        -Wpointer-arith
        -Wcast-qual
        -Wcast-align
        -Wvla
        -Wdouble-promotion
        -Wshadow=local
        -Wdate-time
        $<$<COMPILE_LANGUAGE:CXX>:-Wnon-virtual-dtor>
    )
endif()

unset(CXX11_ABI_VALUE)
if(DEFINED USE_CXX11_ABI)
    if(USE_CXX11_ABI)
        set(CXX11_ABI_VALUE 1)
    else()
        set(CXX11_ABI_VALUE 0)
    endif()
elseif(NOT PRODUCT_SIDE STREQUAL "device")
    set(CXX11_ABI_VALUE 0)
endif()

if(DEFINED CXX11_ABI_VALUE)
    target_compile_definitions(intf_pub_base INTERFACE
        $<$<COMPILE_LANGUAGE:CXX>:_GLIBCXX_USE_CXX11_ABI=${CXX11_ABI_VALUE}>
    )
endif()

target_compile_definitions(intf_pub_base INTERFACE
    $<$<CONFIG:Release>:CFG_BUILD_NDEBUG>
    $<$<CONFIG:Debug>:CFG_BUILD_DEBUG>
    $<$<CONFIG:Release>:NDEBUG>
    LINUX=0
)

target_link_options(intf_pub_base INTERFACE
    -Wl,-z,relro
    -Wl,-z,now
    -Wl,-z,noexecstack
    $<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:-pie>
    $<$<CONFIG:Release>:-Wl,--build-id=none>
    $<$<CONFIG:Release>:-s>
    $<$<BOOL:${ENABLE_ASAN}>:-fsanitize=address>
    $<$<BOOL:${ENABLE_TSAN}>:-fsanitize=thread>
    $<$<BOOL:${ENABLE_UBSAN}>:-fsanitize=undefined>
    $<$<BOOL:${ENABLE_GCOV}>:--coverage>
)

target_link_libraries(intf_pub_base INTERFACE
    -pthread
)

add_library(intf_pub INTERFACE)
target_link_libraries(intf_pub INTERFACE 
    intf_pub_base
)

target_compile_options(intf_pub INTERFACE
    $<$<COMPILE_LANGUAGE:CXX>:-std=c++17>
)

add_library(intf_pub_cxx14 INTERFACE)
target_link_libraries(intf_pub_cxx14 INTERFACE 
    intf_pub_base
)

target_compile_options(intf_pub_cxx14 INTERFACE
    $<$<COMPILE_LANGUAGE:CXX>:-std=c++14>
)
