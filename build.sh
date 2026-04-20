#!/bin/bash
# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

set -e
BASEPATH=$(cd "$(dirname $0)"; pwd)
TOP_DIR="$(dirname "$BASEPATH")"
OUTPUT_PATH="${BASEPATH}/build_out"
BUILD_PATH="${BASEPATH}/build"

# print usage message
usage() {
  echo "Usage:"
  echo "  sh build.sh --pkg [-h | --help] [-v | --verbose] [-j<N>]"
  echo "              [--cann_3rd_lib_path=<PATH>]"
  echo "              [--asan] [--build_host_only] [--cov]"
  echo "              [--sign-script <PATH>] [--enable-sign]"
  echo ""
  echo "Options:"
  echo "    -h, --help     Print usage"
  echo "    --pkgs         Packages to be built, separate the package names with commas"
  echo "    --asan         Enable AddressSanitizer"
  echo "    --cov          Enable Coverage"
  echo "    --build_host_only
                           Only build host target"
  echo "    -build-type=<TYPE>"
  echo "                   Specify build type (TYPE options: Release/Debug), Default: Release"
  echo "    -v, --verbose  Display build command"
  echo "    -j<N>          Set the number of threads used for building, default is 8"
  echo "    --ascend_install_path=<PATH>"
  echo "                   Set ascend package install path, default /usr/local/Ascend/cann"
  echo "    --cann_3rd_lib_path=<PATH>"
  echo "                   Set ascend third_party package install path, default ./output/third_party"
  echo "    --sign-script <PATH>"
  echo "                   Set sign-script's path to <PATH>"
  echo "    --enable-sign"
  echo "                   Enable to sign"
  echo ""
}

# parse and set options
checkopts() {
  VERBOSE=""
  THREAD_NUM=$(grep -c ^processor /proc/cpuinfo)
  ENABLE_GCOV="off"
  CANN_3RD_LIB_PATH="$BASEPATH/output/third_party"
  BUILD_TYPE="Release"
  CUSTOM_SIGN_SCRIPT="${TOP_DIR}/runtime/scripts/sign/community_sign_build.py"
  ENABLE_SIGN="OFF"
  ENABLE_BUILD_DEVICE="ON"
  CANN_PACKAGES=""

  if [ -z "$ASCEND_INSTALL_PATH" ]; then
      ASCEND_INSTALL_PATH="/usr/local/Ascend/cann"
  fi

  if [[ -n "${ASCEND_HOME_PATH}" ]] && [[ -d "${ASCEND_HOME_PATH}/toolkit/toolchain/hcc" ]]; then
    echo "env exists ASCEND_HOME_PATH : ${ASCEND_HOME_PATH}"
    export TOOLCHAIN_DIR=${ASCEND_HOME_PATH}/toolkit/toolchain/hcc
  else
    echo "env ASCEND_HOME_PATH not exists: ${ASCEND_HOME_PATH}"
  fi

  # Process the options
  parsed_args=$(getopt -a -o j:hv -l help,pkgs:,verbose,cov,build_host_only,ascend_install_path:,build-type:,cann_3rd_lib_path:,asan,sign-script:,enable-sign -- "$@") || {
    usage
    exit 1
  }
  eval set -- "$parsed_args"

  while true; do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      -j)
        THREAD_NUM="$2"
        shift 2
        ;;
      -v | --verbose)
        VERBOSE="VERBOSE=1"
        shift
        ;;
      --pkgs)
        CANN_PACKAGES="$2"
        shift 2
        ;;
      --asan)
        ENABLE_ASAN="on"
        shift
        ;;
      --cov)
        ENABLE_GCOV="on"
        shift
        ;;
      --build_host_only)
        ENABLE_BUILD_DEVICE="OFF"
        shift
        ;;
      --build-type)
        BUILD_TYPE=$2
        shift 2
        ;;
      --ascend_install_path)
        ASCEND_INSTALL_PATH="$(realpath $2)"
        shift 2
        ;;
      --cann_3rd_lib_path)
        CANN_3RD_LIB_PATH="$(realpath $2)"
        shift 2
        ;;
      --sign-script)
        CUSTOM_SIGN_SCRIPT=$2
        shift 2
        ;;
      --enable-sign)
        ENABLE_SIGN="ON"
        shift
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "Undefined option: $1"
        usage
        exit 1
        ;;
    esac
  done

  if [[ -z "$CANN_PACKAGES" ]]; then
    echo "error: --pkgs option is required."
    exit 1
  fi
}

mk_dir() {
  local create_dir="$1"  # the target to make
  mkdir -pv "${create_dir}"
  echo "created ${create_dir}"
}

# create build path
build_project() {
  echo "create build directory and build";
  mk_dir "${BUILD_PATH}"
  mk_dir "${OUTPUT_PATH}"
  cd "${BUILD_PATH}"
  CMAKE_ARGS="-DENABLE_OPEN_SRC=True \
              -DENABLE_UNIFIED_BUILD=True \
              -DCANN_PACKAGES=${CANN_PACKAGES} \
              -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
              -DCMAKE_INSTALL_PREFIX=${OUTPUT_PATH} \
              -DASCEND_INSTALL_PATH=${ASCEND_INSTALL_PATH} \
              -DCANN_3RD_LIB_PATH=${CANN_3RD_LIB_PATH} \
              -DENABLE_GCOV=${ENABLE_GCOV} \
              -DENABLE_ASAN=${ENABLE_ASAN} \
              -DENABLE_SIGN=${ENABLE_SIGN} \
              -DENABLE_BUILD_DEVICE=${ENABLE_BUILD_DEVICE} \
              -DCUSTOM_SIGN_SCRIPT=${CUSTOM_SIGN_SCRIPT}"

  echo "CMAKE_ARGS=${CMAKE_ARGS}"
  cmake -S ../superbuild -B . ${CMAKE_ARGS}
  if [ $? -ne 0 ]; then
    echo "execute command: cmake ${CMAKE_ARGS} .. failed."
    return 1
  fi

  cmake --build . -j${THREAD_NUM}
  if [ $? -ne 0 ]; then
    echo "execute command: cmake --build build -j${THREAD_NUM} failed."
    return 1
  fi

  make package -j${THREAD_NUM}
  if [ $? -ne 0 ]; then
    echo "execute command: make package failed."
    return 1
  fi
  echo "build success!"
}

main() {
  checkopts "$@"

  # build start
  echo "---------------- build start ----------------"
  g++ -v

  build_project
  if [[ "$?" -ne 0 ]]; then
    echo "build failed.";
    exit 1;
  fi
  echo "---------------- build finished ----------------"
}

main "$@"
