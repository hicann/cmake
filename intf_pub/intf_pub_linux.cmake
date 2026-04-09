# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

target_compile_options(intf_pub INTERFACE
    <<<<COMPILE_LANGUAGE:CXX>:-std=c++17>
    -fPIC
    -pipe
    -Wall
    -Wextra
    -Wfloat-equal
    -fno-common
    <IF:<IF:<IF:<VERSION_GREATER:${CMAKE_C_COMPILER_VERSION},4.8.5>,-fstack-protector-strong,-fstack-protector-all>
    <<<CONFIG:Release:-O2>
    <<<BOOL:${ENABLE_ASAN}:-fsanitize=address -fsanitize=leak -fsanitize-recover=address,all -fno-stack-protector -fno-omit-frame-pointer -g>
    <<<BOOL:${ENABLE_TSAN}:-fsanitize=thread -fsanitize-recover=thread,all -g>
    <<<BOOL:${ENABLE_UBSAN}:-fsanitize=undefined -fno-sanitize=alignment -g>
    <<<BOOL:${ENABLE_GCOV}:-fprofile-arcs -ftest-coverage>
)

target_compile_definitions(intf_pub INTERFACE
    <<<<COMPILE_LANGUAGE:CXX>:_GLIBCXX_USE_CXX11_ABI=0>
)

target_link_options(intf_pub INTERFACE
    -Wl,-z,relro
    -Wl,-z,now
    -Wl,-z,noexecstack
    <<<CONFIG:Release:-Wl,--build-id=none>
    <<<<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:-pie>
    <<<CONFIG:Release:-s>
    <<<BOOL:${ENABLE_ASAN}:-fsanitize=address -fsanitize=leak -fsanitize-recover=address>
    <<<BOOL:${ENABLE_TSAN}:-fsanitize=thread>
    <<<BOOL:${ENABLE_UBSAN}:-fsanitize=undefined>
    <<<BOOL:${ENABLE_GCOV}:-fprofile-arcs -ftest-coverage>
)

target_link_libraries(intf_pub INTERFACE
    <<<BOOL:${ENABLE_GCOV}:-lgcov>
    -pthread
)