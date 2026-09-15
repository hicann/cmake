#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

"""混合两个异架构的run包。"""

from __future__ import annotations

import argparse
import copy
import os
import shlex
import shutil
import subprocess
import sys
from argparse import Namespace
from glob import glob
from typing import NamedTuple, Optional

from filelist import (
    FileItem,
    generate_filelist,
    generate_record_file,
    parse_filelist,
    parse_records,
)
from packer import create_makeself_pkg_params_factory, create_run_package_command
from utils.comm_log import CommLog
from utils.pkg_utils import PackageError

RUN_SUFFIX = ".run"


class Logger(NamedTuple):
    """日志接口。"""

    error: callable
    warning: callable
    info: callable


class SceneInfo(NamedTuple):
    """场景信息。"""

    arch: str
    filepath: str


def remove(path: str):
    """删除文件或目录。"""
    if os.path.isdir(path):
        shutil.rmtree(path)
    elif os.path.islink(path):
        os.remove(path)
    elif os.path.isfile(path):
        os.remove(path)


class Prepare:
    """准备流程。"""

    def __init__(self, filepath: str, logger: Logger):
        self.filepath = filepath
        self.logger = logger
        self.extract_path = filepath[: -len(RUN_SUFFIX)]

    def decompress_run(self):
        """解压run包。"""
        remove(self.extract_path)
        subprocess.run(
            ["bash", self.filepath, "--noexec", f"--extract={self.extract_path}"],
            check=True,
        )

    def get_scene_info(self) -> SceneInfo:
        """获取包场景。"""
        scene_info_paths = glob(
            os.path.join(self.extract_path, "**", "scene.info"), recursive=True
        )
        if len(scene_info_paths) == 0:
            self.logger.error(f"File scene.info not found in {self.filepath}!")
            raise PackageError()
        if len(scene_info_paths) > 1:
            self.logger.error(
                f"Found multiple scene.info in {self.filepath}, {', '.join(scene_info_paths)}!"
            )
            raise PackageError()
        scene_info_path = scene_info_paths[0]

        def parse_arch_from_scene_info() -> Optional[str]:
            arch_prefix = "arch="
            with open(scene_info_path, encoding="utf-8") as file:
                for line in file:
                    if line.startswith(arch_prefix):
                        return line.strip()[len(arch_prefix) :]
            return None

        arch = parse_arch_from_scene_info()
        if arch is None:
            self.logger.error(f"Get package arch failed in {self.filepath}!")
            raise PackageError()

        return SceneInfo(arch, scene_info_path)

    def remove_extract(self):
        """删除解压目录。"""
        remove(self.extract_path)


def filename_to_label(name: str) -> str:
    """文件名转为标签名。"""
    name_prefix = name.split("_")[0]
    name_prefix = name_prefix.replace("-", "_").upper()
    return name_prefix + "_RUN_PACKAGE"


class Mix:
    """混合流程。"""

    def __init__(self, prepare: Prepare, scene_info: SceneInfo, makeself_dir: str):
        self.filepath = prepare.filepath
        self.extract_path = prepare.extract_path
        self.logger = prepare.logger
        self.dirpath = os.path.dirname(prepare.filepath)
        self.scene_info = scene_info
        self.makeself_dir = makeself_dir

        filename = os.path.basename(self.filepath)
        self.filename_new = f"{filename[: -len(RUN_SUFFIX)]}.mixed.run"
        self.filepath_new = os.path.join(self.dirpath, self.filename_new)
        self.label = filename_to_label(filename)

        # 相对extract_path的架构产物路径
        arch_relpath = os.path.join(
            f"{self.scene_info.arch}-linux", "devlib", "linux", self.scene_info.arch
        )

        share_info_pkg_dirpath = os.path.dirname(scene_info.filepath)
        self.share_info_pkg_relpath = os.path.relpath(
            share_info_pkg_dirpath, self.extract_path
        )
        self.record_filepath = os.path.join(share_info_pkg_dirpath, "RECORD")
        self.filelist_filepath = os.path.join(
            share_info_pkg_dirpath, "script", "filelist.csv"
        )

        self.records = list(parse_records(self.record_filepath))
        self.filelist = list(parse_filelist(self.filelist_filepath))

        self.records_set = set(self.records)
        self.filelist_set = set(item.relative_install_path for item in self.filelist)

        self.arch_records = [
            item for item in self.records if item.startswith(arch_relpath)
        ]
        self.arch_filelist = [
            item
            for item in self.filelist
            if item.relative_install_path.startswith(arch_relpath)
        ]

    def trans_to_self_arch_record(self, item: str) -> str:
        """转为本包架构的RECORD条目。"""
        parts = item.split("/")
        parts[0] = f"{self.scene_info.arch}-linux"
        return "/".join(parts)

    def trans_to_self_arch_fileitem(self, item: FileItem) -> FileItem:
        """转为本包架构的filelist条目。"""
        relative_install_path = item.relative_install_path
        parts = relative_install_path.split("/")
        parts[0] = f"{self.scene_info.arch}-linux"
        relative_install_path = "/".join(parts)

        if item.relative_path_in_pkg == "NA":
            return item._replace(relative_install_path=relative_install_path)
        return item._replace(
            relative_path_in_pkg=relative_install_path,
            relative_install_path=relative_install_path,
        )

    def mix_artifacts(self, other: Mix) -> bool:
        """混合编译产物。"""
        other_artifact_path = os.path.join(
            other.extract_path,
            f"{other.scene_info.arch}-linux",
            "devlib",
            "linux",
            other.scene_info.arch,
        )
        self_artifact_path = os.path.join(
            self.extract_path,
            f"{self.scene_info.arch}-linux",
            "devlib",
            "linux",
            other.scene_info.arch,
        )
        if not os.path.isdir(other_artifact_path):
            return False

        remove(self_artifact_path)
        shutil.copytree(other_artifact_path, self_artifact_path, symlinks=True)

        records = copy.copy(self.records)
        for item in other.arch_records:
            self_item = self.trans_to_self_arch_record(item)
            if self_item not in self.records_set:
                records.append(self_item)
        generate_record_file(records, self.record_filepath)

        filelist = copy.copy(self.filelist)
        for item in other.arch_filelist:
            self_item = self.trans_to_self_arch_fileitem(item)
            if self_item.relative_install_path not in self.filelist_set:
                filelist.append(self_item)
        generate_filelist(filelist, self.filelist_filepath)
        return True

    def repack_run(self) -> bool:
        """重打run包。"""
        factory = create_makeself_pkg_params_factory(
            ".", os.path.join("..", self.filename_new), self.label
        )
        package_attr = {
            "install_script": os.path.join(
                self.share_info_pkg_relpath, "script", "install.sh"
            ),
            "help": os.path.join(self.share_info_pkg_relpath, "script", "help.info"),
            "cleanup": os.path.join(
                self.share_info_pkg_relpath, "script", "cleanup.sh"
            ),
        }
        params = factory(self.makeself_dir, package_attr, True)
        pack_cmds, err_msg = create_run_package_command(params)
        if err_msg:
            self.logger.error(err_msg)
            self.logger.error("Create run command failed!")
            return False

        pack_cmds = ["bash"] + pack_cmds
        self.logger.info(f"Repack run command: {shlex.join(pack_cmds)}")
        subprocess.run(pack_cmds, check=True, cwd=self.extract_path)

        os.replace(self.filepath_new, self.filepath)
        return True


def check_makeself_tools(makeself_dir: str) -> bool:
    """检查makeself工具是否存在。"""
    if not os.path.exists(makeself_dir):
        CommLog.cilog_error(f"{makeself_dir} doesn't exist!")
        return False

    makeself_main = os.path.join(makeself_dir, "makeself.sh")
    if not os.path.exists(makeself_main):
        CommLog.cilog_error(f"{makeself_main} doesn't exist!")
        return False

    makeself_header = os.path.join(makeself_dir, "makeself-header.sh")
    if not os.path.exists(makeself_header):
        CommLog.cilog_error(f"{makeself_header} doesn't exist!")
        return False

    return True


def check_args(args: Namespace) -> bool:
    """检查参数。"""
    if not os.path.exists(args.pkga):
        CommLog.cilog_error(f"Package {args.pkga} doesn't exist!")
        return False

    if not os.path.exists(args.pkgb):
        CommLog.cilog_error(f"Package {args.pkgb} doesn't exist!")
        return False

    if not args.pkga.endswith(RUN_SUFFIX):
        CommLog.cilog_error(
            f"Package {args.pkga} needs to be a run package(end with {RUN_SUFFIX})!"
        )
        return False

    if not args.pkgb.endswith(RUN_SUFFIX):
        CommLog.cilog_error(
            f"Package {args.pkgb} needs to be a run package(end with {RUN_SUFFIX})!"
        )
        return False

    if not check_makeself_tools(args.makeself):
        return False
    return True


def main(argv: list[str]) -> int:
    """主流程。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("pkga")
    parser.add_argument("pkgb")
    parser.add_argument("--arch", nargs="+")
    parser.add_argument("--makeself", required=True)
    parser.add_argument("--clean", action="store_true", help="Clean after repack.")
    args = parser.parse_args(argv)

    if not check_args(args):
        return 1

    logger = Logger(CommLog.cilog_error, CommLog.cilog_warning, CommLog.cilog_info)

    prepares = [
        Prepare(args.pkga, logger),
        Prepare(args.pkgb, logger),
    ]
    try:
        for prepare in prepares:
            prepare.decompress_run()

        try:
            scene_infos = [prepare.get_scene_info() for prepare in prepares]
        except PackageError:
            return 1

        if scene_infos[0].arch == scene_infos[1].arch:
            CommLog.cilog_error(f"Packages arch is the same {scene_infos[0].arch}.")
            return 1

        mixes = [
            Mix(prepare, scene_info, args.makeself)
            for prepare, scene_info in zip(prepares, scene_infos)
        ]
        for idx in range(len(mixes)):
            if not args.arch or mixes[idx].scene_info.arch in args.arch:
                mix = mixes[idx]
                other_mix = mixes[1 - idx]  # 1-idx即另一个Mix元素
                if mix.mix_artifacts(other_mix):
                    mix.repack_run()
    finally:
        if args.clean:
            for prepare in prepares:
                prepare.remove_extract()

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
