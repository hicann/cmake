# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

from ..utils.comm_log import CommLog


def test_comm_log_timestamp_and_basic_methods(monkeypatch):
    timestamps = []

    def fake_print_element(x):
        timestamps.append(x)

    monkeypatch.setattr(CommLog, "cilog_print_element", staticmethod(fake_print_element))

    ts = CommLog.cilog_get_timestamp()
    assert isinstance(ts, str) and len(ts) >= 10

    # 仅验证不会抛异常即可，输出被 fake_print_element 捕获
    CommLog.cilog_info("info %s", "msg")
    CommLog.cilog_warning("warn %s", "msg")
    CommLog.cilog_error("err %s", "msg")

    assert timestamps  # 至少被调用过一次

