# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

# aarch64 clang/LLVM 工具链
# TOOLCHAIN_DIR 指向 LLVM 安装根目录（如 /usr/lib/llvm-15），其 bin/ 下应包含
# clang、clang++、lld、llvm-ar、llvm-ranlib 等工具。

if(NOT TOOLCHAIN_DIR)
    message(FATAL_ERROR "TOOLCHAIN_DIR is not set. This toolchain file requires TOOLCHAIN_DIR "
        "(e.g. -DTOOLCHAIN_DIR=/usr/lib/llvm-15) to locate clang/lld/llvm-ar.")
endif()

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CPU_TYPE aarch64)

# 编译器
set(CMAKE_C_COMPILER "${TOOLCHAIN_DIR}/bin/clang" CACHE PATH "C Compiler")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_DIR}/bin/clang++" CACHE PATH "C++ Compiler")

# 链接器：clang 驱动 + lld（Makefile generator 用编译器驱动链接，
# 需通过 -fuse-ld=lld 指定，仅设 CMAKE_LINKER 不生效）
set(CMAKE_EXE_LINKER_FLAGS_INIT "-fuse-ld=lld")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-fuse-ld=lld")

# LLVM 工具链
set(CMAKE_LINKER "${TOOLCHAIN_DIR}/bin/lld" CACHE PATH "LINKER")
set(CMAKE_AR "${TOOLCHAIN_DIR}/bin/llvm-ar" CACHE PATH "AR")
set(CMAKE_RANLIB "${TOOLCHAIN_DIR}/bin/llvm-ranlib" CACHE PATH "RANLIB")
set(CMAKE_STRIP "${TOOLCHAIN_DIR}/bin/llvm-strip" CACHE PATH "STRIP")
set(CMAKE_LD "${TOOLCHAIN_DIR}/bin/lld" CACHE PATH "LD")
set(CMAKE_NM "${TOOLCHAIN_DIR}/bin/llvm-nm" CACHE PATH "NM")
set(CMAKE_OBJCOPY "${TOOLCHAIN_DIR}/bin/llvm-objcopy" CACHE PATH "OBJCOPY")

# __FILE__ 宏改写：只输出文件名而非完整路径
if(CMAKE_GENERATOR MATCHES "Makefiles")
    set(_CANN_REDEFINING_FILE "-D__FILE__='\"$(notdir $(abspath <SOURCE>))\"'")
else()
    set(_CANN_REDEFINING_FILE)
endif()
set(CMAKE_C_COMPILE_OBJECT "<CMAKE_C_COMPILER> <DEFINES> ${_CANN_REDEFINING_FILE} -Wno-builtin-macro-redefined <INCLUDES> <FLAGS> -o <OBJECT> -c <SOURCE>")
set(CMAKE_CXX_COMPILE_OBJECT "<CMAKE_CXX_COMPILER> <DEFINES> ${_CANN_REDEFINING_FILE} -Wno-builtin-macro-redefined <INCLUDES> <FLAGS> -o <OBJECT> -c <SOURCE>")

# 清除 CMake 默认 flags，避免注入与 clang 不兼容的选项
set(CMAKE_C_FLAGS_DEBUG "" CACHE STRING "c debug flag" FORCE)
set(CMAKE_C_FLAGS_RELEASE "" CACHE STRING "c release flag" FORCE)

set(CMAKE_CXX_FLAGS_DEBUG "" CACHE STRING "cxx debug flag" FORCE)
set(CMAKE_CXX_FLAGS_RELEASE "" CACHE STRING "cxx release flag" FORCE)

set(CMAKE_ASM_FLAGS_DEBUG "" CACHE STRING "asm debug flag" FORCE)
set(CMAKE_ASM_FLAGS_RELEASE "" CACHE STRING "asm release flag" FORCE)

# 确定性归档
set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> qcD <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_C_ARCHIVE_APPEND "<CMAKE_AR> qD <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_C_ARCHIVE_FINISH "<CMAKE_RANLIB> -D <TARGET>")

set(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> qcD <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_CXX_ARCHIVE_APPEND "<CMAKE_AR> qD <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_CXX_ARCHIVE_FINISH "<CMAKE_RANLIB> -D <TARGET>")

set(CMAKE_SKIP_RPATH TRUE)

unset(_CANN_REDEFINING_FILE)
