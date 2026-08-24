#!/bin/bash
# ----------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# ----------------------------------------------------------------------------

# bash ops_generate_rpm_deb.sh --top_dir=<TOP_DIR> --pkg_path=<PKG_PATH> --pkg_name=<PKG_NAME> --soc=<SOC> --pkg-type=<rpm|deb|all>

TOP_DIR=""
PKG_PATH=""
PKG_NAME=""
SOC=""
PKG_TYPE=""

parse_args() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            --top_dir=*)    TOP_DIR="${arg#*=}" ;;
            --pkg_path=*)   PKG_PATH="${arg#*=}" ;;
            --pkg_name=*)   PKG_NAME="${arg#*=}" ;;
            --soc=*)        SOC="${arg#*=}" ;;
            --pkg-type=*)   PKG_TYPE="${arg#*=}" ;;
            *)              ;;
        esac
    done
}

log() {
    echo "$*"
}

die() {
    log "ERROR: $*"
    exit 1
}

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log "Creating directory: $dir"
        mkdir -p "$dir" || die "Failed to create directory $dir"
    fi
}

# 从 version.cmake 读取 set_cann_package 的包名和版本
read_package_name_version() {
    local version_cmake="${TOP_DIR}/${PKG_PATH}/version.cmake"
    [[ -f "$version_cmake" ]] || die "version.cmake not found: $version_cmake"
    local pkg_line=$(grep 'set_cann_package(' "$version_cmake" | head -1)
    PKG_COMPONENT=$(echo "$pkg_line" | sed 's/.*set_cann_package(\([^ ]*\).*/\1/')
    PKG_COMPONENT_NAME=$(echo "$PKG_COMPONENT" | tr '_' '-')
    PKG_VERSION_FROM_CMAKE=$(echo "$pkg_line" | sed 's/.*VERSION "\([^"]*\)".*/\1/')
    [[ -n "$PKG_COMPONENT" ]] || die "Failed to parse package name from version.cmake"
    log "Package component: $PKG_COMPONENT, version: $PKG_VERSION_FROM_CMAKE"
}

# 从 version.cmake 读取 set_cann_run_dependencies 依赖列表，生成 deb Depends 和 rpm Requires
read_run_dependencies() {
    local version_cmake="${TOP_DIR}/${PKG_PATH}/version.cmake"
    DEB_DEPENDS=""
    RPM_REQUIRES=""
    local first=true
    local dep=""
    local ver=""
    while IFS= read -r line; do
        dep=$(echo "$line" | sed 's/set_cann_run_dependencies(\([^ ]*\) .*/\1/')
        ver=$(echo "$line" | sed 's/.*"\(.*\)".*/\1/' | sed 's/>=/>= /')
        [[ -n "$dep" ]] || continue
        if $first; then
            DEB_DEPENDS="${dep} (${ver})"
            RPM_REQUIRES="${dep} ${ver}"
            first=false
        else
            DEB_DEPENDS="${DEB_DEPENDS}, ${dep} (${ver})"
            RPM_REQUIRES="${RPM_REQUIRES}, ${dep} ${ver}"
        fi
    done < <(grep 'set_cann_run_dependencies(' "$version_cmake")
    [[ -n "$DEB_DEPENDS" ]] || die "No run dependencies found in version.cmake"
}

generate_cpack_config() {
    local output="$1"
    local format="$2"
    local cpack_version="$3"
    local arch="$4"
    local install_prefix="$5"
    local pkg_file_name="$6"
    local cpack_workdir="$7"
    local postinst_path="$8"
    local prerm_path="$9"
    local staging_dir="${10}"
    local pkg_component="${11}"
    local pkg_name="${12}"

    cat > "$output" << CPACK_EOF
set(CPACK_PACKAGE_NAME "${pkg_component}")
set(CPACK_PACKAGE_VERSION "${cpack_version}")
set(CPACK_SYSTEM_NAME "linux")
set(CPACK_ARCHITECTURE "${arch}")
set(CPACK_PACKAGE_FILE_NAME "${pkg_file_name}")
set(CPACK_PACKAGING_INSTALL_PREFIX "${install_prefix}")
set(CPACK_PACKAGE_DIRECTORY "${cpack_workdir}")
set(CPACK_CMAKE_BINARY_DIR "${cpack_workdir}")
set(CPACK_INSTALLED_DIRECTORIES "${staging_dir};/")
set(CPACK_PACKAGE_DESCRIPTION "CANN ${pkg_component} package")
set(CPACK_PACKAGE_CONTACT "huawei")
set(CPACK_CANN_INSTALL_COMPONENT "${pkg_component}")
set(CPACK_PACKAGE_PARAM_NAME "${pkg_name}")
set(CPACK_CMAKE_SOURCE_DIR "${TOP_DIR}/${PKG_PATH}")
set(CPACK_ENABLE_DEVICE "FALSE")
set(CPACK_SOC "${SOC}")
set(CPACK_RPM_PACKAGE_REQUIRES "${RPM_REQUIRES}")
set(CPACK_RPM_PACKAGE_AUTOREQ OFF)
set(CPACK_RPM_PACKAGE_AUTOPROV OFF)
set(CPACK_RPM_SPEC_MORE_DEFINE "
%global __os_install_post %{nil}
%global __spec_install_post %{nil}
%define _enable_debug_packages 0
%define _build_id_links none
%define _binary_payload w1.zstdio
")
set(CPACK_RPM_SPEC_INSTALL_POST "/bin/true")
set(CPACK_RPM_POST_INSTALL_SCRIPT_FILE "${postinst_path}")
set(CPACK_RPM_PRE_UNINSTALL_SCRIPT_FILE "${prerm_path}")
set(CPACK_RPM_FILE_NAME "${pkg_file_name}.rpm")
set(CPACK_RPM_PACKAGE_GROUP "System/Libraries")
set(CPACK_RPM_PACKAGE_LICENSE "CANN-2.0")
set(CPACK_RPM_PACKAGE_DESCRIPTION "CANN ${pkg_component} package")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "${DEB_DEPENDS}")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "huawei")
set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${postinst_path};${prerm_path}")
set(CPACK_DEBIAN_FILE_NAME "${pkg_file_name}.deb")
set(CPACK_DEBIAN_PACKAGE_SECTION "libs")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
set(CPACK_DEBIAN_COMPRESSION_TYPE "zstd")
set(CPACK_DEBIAN_COMPRESSION_LEVEL 1)
set(CPACK_THREADS 0)
CPACK_EOF
    chmod 644 "$output"
}

generate_rpm_deb_packages() {
    local pkg_type="$1"
    if [[ -z "$pkg_type" || "$pkg_type" == "run" ]]; then
        return 0
    fi

    local WORKDIR="${TOP_DIR}/${PKG_PATH}"
    local OS_ARCH=$(uname -m)
    local STAGING_DIR="${WORKDIR}/build/_CPack_Packages/makeself_staging"
    local CPACK_WORK_DIR="${WORKDIR}/build/cpack_staging"
    local VERSION_FILE="${STAGING_DIR}/share/info/${PKG_NAME}/version.info"
    local PACKAGE_SCRIPT="${TOP_DIR}/open_source/cann-cmake/scripts/package/package.py"

    local CANN_VERSION=""
    if [[ -f "$VERSION_FILE" ]]; then
        CANN_VERSION=$(grep "^Version=" "$VERSION_FILE" | cut -d= -f2)
    fi
    if [[ -z "$CANN_VERSION" ]]; then
        CANN_VERSION="$PKG_VERSION_FROM_CMAKE"
    fi
    [[ -n "$CANN_VERSION" ]] || die "Failed to determine CANN version"

    local CANN_VERSION_PKG="${CANN_VERSION//-/.}"

    local ARCH=""
    if [[ "$OS_ARCH" == "x86_64" ]]; then
        ARCH="x86_64"
    else
        ARCH="aarch64"
    fi

    local INSTALL_PREFIX="/usr/local/Ascend/cann-${CANN_VERSION}"
    local SOC_LOWER=$(echo "$SOC" | tr '[:upper:]' '[:lower:]')
    local SOC_SHORT=""
    if [[ "$SOC_LOWER" == "ascend910_93" ]]; then
        SOC_SHORT="A3"
    elif [[ "$SOC_LOWER" == ascend* ]]; then
        SOC_SHORT="${SOC_LOWER#ascend}"
    else
        SOC_SHORT="$SOC_LOWER"
    fi
    local PKG_FILE_NAME="cann-${SOC_SHORT}-${PKG_COMPONENT}_${CANN_VERSION_PKG}_linux-${ARCH}"

    local expanded_type="$pkg_type"
    if [[ "$pkg_type" == "all" ]]; then
        expanded_type="rpm,deb"
    fi

    # --- 遍历 rpm/deb 打包 ---
    for fmt in $(echo "$expanded_type" | tr ',' ' '); do
        if [[ "$fmt" != "rpm" && "$fmt" != "deb" ]]; then
            continue
        fi

        local t0=$(date +%s)
        log "Generating filelist and scripts for $fmt package..."
        cd "${WORKDIR}/build" || die "Failed to cd to build dir"
        python3 "$PACKAGE_SCRIPT" \
            --pkg_name "$PKG_NAME" \
            --makeself_dir "${WORKDIR}/build/makeself" \
            --pkg-output-dir "${WORKDIR}/build" \
            --independent_pkg \
            --chip_name "$SOC" \
            --os_arch "linux-${ARCH}" \
            --delivery_dir "${STAGING_DIR}" \
            --source_dir "${WORKDIR}" \
            --version_dir "$CANN_VERSION" \
            --suffix "$fmt" || die "package.py --suffix $fmt failed"

        local POSTINST="${WORKDIR}/build/postinst"
        local PRERM="${WORKDIR}/build/prerm"
        [[ -f "$POSTINST" ]] || die "postinst not generated"
        [[ -f "$PRERM" ]] || die "prerm not generated"
        chmod 755 "$POSTINST" "$PRERM"

        local CPACK_STAGING="${CPACK_WORK_DIR}/${fmt}_staging"
        rm -rf "$CPACK_STAGING"
        mkdir -p "${CPACK_STAGING}${INSTALL_PREFIX}"
        cp -al "${STAGING_DIR}"/* "${CPACK_STAGING}${INSTALL_PREFIX}/" 2>/dev/null || true
        rm -f "${CPACK_STAGING}${INSTALL_PREFIX}"/*.run

        local CPACK_CONFIG="${CPACK_WORK_DIR}/CPackConfig.cmake"
        generate_cpack_config "$CPACK_CONFIG" "$fmt" "$CANN_VERSION_PKG" "$ARCH" \
            "$INSTALL_PREFIX" "$PKG_FILE_NAME" "$CPACK_WORK_DIR" "$POSTINST" "$PRERM" "$CPACK_STAGING" \
            "$PKG_COMPONENT_NAME" "$PKG_NAME"

        log "Running CPack to generate $fmt package..."
        cd "$CPACK_WORK_DIR" || die "Failed to cd to cpack_work_dir"
        local UPPER_FMT=$(echo "$fmt" | tr '[:lower:]' '[:upper:]')

        local t_cpack=$(date +%s)
        cpack --config CPackConfig.cmake -G "$UPPER_FMT" || die "cpack -G $UPPER_FMT failed"
        log "[$fmt] cpack cost: $(( $(date +%s) - t_cpack ))s"

        if [[ "$fmt" == "rpm" ]]; then
            find "$CPACK_WORK_DIR" -name "*.rpm" -exec cp {} "${WORKDIR}/build/" \; 2>/dev/null || true
        elif [[ "$fmt" == "deb" ]]; then
            find "$CPACK_WORK_DIR" -name "*.deb" -exec cp {} "${WORKDIR}/build/" \; 2>/dev/null || true
        fi
        log "$fmt package generated successfully"
        log "[$fmt] total cost: $(( $(date +%s) - t0 ))s"
    done

    cd "${WORKDIR}" || die "Failed to cd back to workdir"
}

# -----------------------------
# 主流程开始
# -----------------------------
parse_args "$@"

if [[ -z "$TOP_DIR" || -z "$PKG_PATH" || -z "$PKG_NAME" || -z "$SOC" ]]; then
    die "Missing required arguments: --top_dir, --pkg_path, --pkg_name, --soc"
fi

log "Starting RPM/DEB package generation..."
read_package_name_version
read_run_dependencies
generate_rpm_deb_packages "$PKG_TYPE"
log "RPM/DEB package generation completed."
