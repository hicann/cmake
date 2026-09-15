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

"""filelist模块测试。"""

from package.filelist import (
    FileItem,
    generate_filelist,
    generate_record_file,
    parse_filelist,
    parse_records,
)


class DataSet:
    """数据集。"""

    class FileItem:
        share = FileItem(
            "metadef",
            "mkdir",
            "NA",
            "share",
            "TRUE",
            "750",
            "\\\\$username:\\\\$usergroup",
            "all",
            [],
            set(),
            "N",
            "FALSE",
            "NA",
            "metadef",
            [],
            set(),
            True,
        )

    filelist_1 = [FileItem.share]
    records_1 = ["share"]


def trans_filelist_to_parsed(filelist):
    return [fileitem._replace(is_dir=False) for fileitem in filelist]


def test_parse_filelist_1(tmp_path):
    path = tmp_path / "filelist_1.csv"
    generate_filelist(DataSet.filelist_1, str(path))
    result = list(parse_filelist(str(path)))
    expected = trans_filelist_to_parsed(DataSet.filelist_1)
    assert expected == result


def test_parse_records_1(tmp_path):
    path = tmp_path / "RECORD"
    generate_record_file(DataSet.records_1, str(path))
    result = list(parse_records(str(path)))
    assert DataSet.records_1 == result
