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
  echo "  sh build.sh --pkgs=<PACKAGES> [-h | --help] [-v | --verbose] [-j<N>]"
  echo "              [--binary-pkgs=<PACKAGES>]"
  echo "              [--superbuild-config=<PATH>] [--p=<PATH> | --cann_path=<PATH>]"
  echo "              [--cann_3rd_lib_path=<PATH>]"
  echo "              [--asan] [--build_host_only] [--cov]"
  echo "              [--sign-script <PATH>] [--enable-sign]"
  echo "              [--rule-launch | --rule_launch]"
  echo ""
  echo "Options:"
  echo "    -h, --help     Print usage"
  echo "    --pkgs=<PACKAGES>"
  echo "                   Packages to be built, separate the package names with commas"
  echo "    --binary-pkgs=<PACKAGES>"
  echo "                   Use the binary in the package"
  echo "    --superbuild-config=<PATH>"
  echo "                   Config path for superbuild"
  echo "    --asan         Enable AddressSanitizer"
  echo "    --cov          Enable Coverage"
  echo "    --build_host_only
                           Only build host target"
  echo "    --build-type=<TYPE>"
  echo "                   Specify build type (TYPE options: Release/Debug), Default: Release"
  echo "    -v, --verbose  Display build command"
  echo "    -j<N>          Set the number of threads used for building, default is 8"
  echo "    -p, --cann_path=<PATH>"
  echo "                   Set ascend package install path, default /usr/local/Ascend/cann"
  echo "    --cann_3rd_lib_path=<PATH>"
  echo "                   Set ascend third_party package install path, default ./output/third_party"
  echo "    --sign-script <PATH>"
  echo "                   Set sign-script's path to <PATH>"
  echo "    --enable-sign"
  echo "                   Enable to sign"
  echo "    --rule-launch/--rule_launch"
  echo "                   Set compiler launcher rule"
  echo ""
}

trans_commas() {
  local _outvar="$1"
  read -r "$_outvar" <<EOF
$(echo "$2" | tr "," ";")
EOF
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
  CANN_BINARY_PACKAGES=""
  CANN_SUPERBUILD_CONFIG=""
  CHECK_CANN_PATH="0"
  LAUNCH_RULE=""

  # Process the options
  parsed_args=$(getopt -a -o j:hp:v -l help,pkgs:,superbuild-config:,binary-pkgs:,verbose,cov,build_host_only,cann_path:,build-type:,cann_3rd_lib_path:,asan,sign-script:,enable-sign,rule-launch:,rule_launch: -- "$@") || {
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
        trans_commas "CANN_PACKAGES" "$2"
        shift 2
        ;;
      --superbuild-config)
        CANN_SUPERBUILD_CONFIG="$2"
        shift 2
        ;;
      --binary-pkgs)
        trans_commas "CANN_BINARY_PACKAGES" "$2"
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
      --cann_path | -p)
        CANN_PATH="$(realpath $2)"
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
      --rule-launch | --rule_launch)
        LAUNCH_RULE="$2"
        shift 2
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

  set_env
}

set_env() {
  if [ "${USER_ID}" != "0" ]; then
    DEFAULT_TOOLKIT_INSTALL_DIR="${HOME}/Ascend/cann"
    DEFAULT_INSTALL_DIR="${HOME}/Ascend/cann"
  else
    DEFAULT_TOOLKIT_INSTALL_DIR="/usr/local/Ascend/cann"
    DEFAULT_INSTALL_DIR="/usr/local/Ascend/cann"
  fi

  ASCEND_CANN_PACKAGE_PATH=""
  if [ -n "${CANN_PATH}" ];then
    ASCEND_CANN_PACKAGE_PATH=${CANN_PATH}
  elif [ -n "${ASCEND_HOME_PATH}" ];then
    ASCEND_CANN_PACKAGE_PATH=${ASCEND_HOME_PATH}
  elif [ -n "${ASCEND_OPP_PATH}" ];then
    ASCEND_CANN_PACKAGE_PATH=$(dirname ${ASCEND_OPP_PATH})
  elif [ -d "${DEFAULT_TOOLKIT_INSTALL_DIR}" ];then
    ASCEND_CANN_PACKAGE_PATH=${DEFAULT_TOOLKIT_INSTALL_DIR}
  elif [ -d "${DEFAULT_INSTALL_DIR}" ];then
    ASCEND_CANN_PACKAGE_PATH=${DEFAULT_INSTALL_DIR}
  elif [ "$CHECK_CANN_PATH" = "1" ]; then
    echo "Error: Please set the cann package installation directory through parameter -p|--cann_path."
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
  local -a cmake_cmd
  echo "create build directory and build";
  mk_dir "${BUILD_PATH}"
  mk_dir "${OUTPUT_PATH}"
  mkdir -p "$BUILD_PATH/.cmake/api/v1/query"
  touch "$BUILD_PATH/.cmake/api/v1/query/codemodel-v2"

  CMAKE_ARGS=(
    "-DBUILD_OPEN_PROJECT=TRUE"
    "-DENABLE_OPEN_SRC=TRUE"
    "-DENABLE_UNIFIED_BUILD=TRUE"
    "-DCANN_PACKAGES=${CANN_PACKAGES}"
    "-DCANN_BINARY_PACKAGES=${CANN_BINARY_PACKAGES}"
    "-DCANN_SUPERBUILD_CONFIG=${CANN_SUPERBUILD_CONFIG}"
    "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
    "-DCMAKE_INSTALL_PREFIX=${OUTPUT_PATH}"
    "-DASCEND_CANN_PACKAGE_PATH=${ASCEND_CANN_PACKAGE_PATH}"
    "-DCANN_3RD_LIB_PATH=${CANN_3RD_LIB_PATH}"
    "-DENABLE_GCOV=${ENABLE_GCOV}"
    "-DENABLE_ASAN=${ENABLE_ASAN}"
    "-DENABLE_SIGN=${ENABLE_SIGN}"
    "-DENABLE_BUILD_DEVICE=${ENABLE_BUILD_DEVICE}"
    "-DCUSTOM_SIGN_SCRIPT=${CUSTOM_SIGN_SCRIPT}"
  )

  if [ -n "${LAUNCH_RULE}" ]; then
    CMAKE_ARGS+=("-DLAUNCH_COMPILE_TOOL=${LAUNCH_RULE}")
    CMAKE_ARGS+=("-DLAUNCH_LINK_TOOL=${LAUNCH_RULE}")
  fi

  cmake_cmd=(cmake -S "$BASEPATH/superbuild" -B "$BUILD_PATH" "${CMAKE_ARGS[@]}")
  "${cmake_cmd[@]}"
  if [ $? -ne 0 ]; then
    echo "execute command: ${cmake_cmd[@]} failed."
    return 1
  fi

  cmake_cmd=(cmake --build "$BUILD_PATH" --target package "-j${THREAD_NUM}")
  "${cmake_cmd[@]}"
  if [ $? -ne 0 ]; then
    echo "execute command: ${cmake_cmd[@]} failed."
    return 1
  fi
  echo "build success!"
}

function main() {
  checkopts "$@"

  # build start
  local start_time=$(date +%s)
  echo "---------------- build start $(date '+%Y-%m-%d %H:%M:%S') ----------------"

  build_project
  if [[ "$?" -ne 0 ]]; then
    echo "build failed.";
    exit 1;
  fi

  echo "---------------- build end  $(date '+%Y-%m-%d %H:%M:%S') ----------------"
  local end_time=$(date +%s)

  # 计算耗时（秒）
  local duration=$((end_time - start_time))

  # 格式化输出耗时（时:分:秒）
  local hours=$((duration / 3600))
  local minutes=$(( (duration % 3600) / 60 ))
  local seconds=$((duration % 60))
  echo "---------------- Total duration: ${hours} hour ${minutes} min ${seconds} sec ----------------"
 
}

main "$@"
