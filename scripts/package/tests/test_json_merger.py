# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

import json
from pathlib import Path

import pytest

from .. import json_merger


def test_load_json_file_success(tmp_path: Path):
    file_path = tmp_path / "data.json"
    content = {"a": 1, "b": "x"}
    file_path.write_text(json.dumps(content), encoding="utf-8")

    result = json_merger.load_json_file(str(file_path))

    assert result == content


def test_load_json_file_not_found():
    with pytest.raises(FileNotFoundError):
        json_merger.load_json_file("not_exist_xxx.json")


def test_load_json_file_invalid_json(tmp_path: Path):
    file_path = tmp_path / "bad.json"
    file_path.write_text("{ invalid json", encoding="utf-8")

    with pytest.raises(ValueError) as exc:
        json_merger.load_json_file(str(file_path))

    assert "Invalid JSON format" in str(exc.value)


def test_save_json_file_create_dir_and_content(tmp_path: Path):
    out_dir = tmp_path / "sub"
    out_file = out_dir / "out.json"
    data = {"k": "v"}

    json_merger.save_json_file(str(out_file), data)

    assert out_file.exists()
    loaded = json.loads(out_file.read_text(encoding="utf-8"))
    assert loaded == data


def test_merge_binlist_basic():
    base = {"binList": [1, 2], "other": "x"}
    update = {"binList": [3], "extra": True}

    merged = json_merger.merge_binlist(base, update)

    assert merged["binList"] == [1, 2, 3]
    # 其他字段保持 base 的内容
    assert merged["other"] == "x"
    # update 中额外字段不自动合并
    assert "extra" not in merged


def test_main_full_flow(tmp_path: Path):
    base = {"binList": [1]}
    update = {"binList": [2, 3]}
    base_file = tmp_path / "base.json"
    update_file = tmp_path / "update.json"
    out_file = tmp_path / "out.json"

    base_file.write_text(json.dumps(base), encoding="utf-8")
    update_file.write_text(json.dumps(update), encoding="utf-8")

    ok = json_merger.main(
        [
            "--base-file",
            str(base_file),
            "--update-file",
            str(update_file),
            "--output-file",
            str(out_file),
        ]
    )

    assert ok is True
    assert out_file.exists()
    merged = json.loads(out_file.read_text(encoding="utf-8"))
    assert merged["binList"] == [1, 2, 3]

