#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

"""Extended tests for filelist operations."""

import pytest
from package import filelist


class TestCreateFileItemExtended:
    """Extended tests for create_file_item."""

    @staticmethod
    def test_create_file_item_valid():
        """Test create_file_item with valid parameters."""
        item = filelist.create_file_item(
            'module', 'copy', 'pkg/path', 'install/path',
            'TRUE', '755', 'user:group', 'run', [],
            {'all'}, 'N', 'FALSE', 'hash_value', 'block',
            [], {'ascend910'}, False
        )
        assert item.module == 'module'
        assert item.operation == 'copy'


class TestIsSpecificInstallTypeExtended:
    """Extended tests for is_specific_install_type."""

    @staticmethod
    def test_is_specific_install_type_with_all():
        """Test when install_type contains 'all'."""
        item = filelist.create_file_item(
            'm', 'op', 'pkg', 'install', 'TRUE', '755', 'u:g',
            'all;run', [], {'f'}, 'N', 'FALSE', 'h', 'b', [], {'c'}, False
        )
        result = filelist.is_specific_install_type(item, {'docker'})
        assert result is True

    @staticmethod
    def test_is_specific_install_type_intersection():
        """Test when install_type has intersection."""
        item = filelist.create_file_item(
            'm', 'op', 'pkg', 'install', 'TRUE', '755', 'u:g',
            'docker;run', [], {'f'}, 'N', 'FALSE', 'h', 'b', [], {'c'}, False
        )
        result = filelist.is_specific_install_type(item, {'docker'})
        assert result is True

    @staticmethod
    def test_is_specific_install_type_no_match():
        """Test when no match."""
        item = filelist.create_file_item(
            'm', 'op', 'pkg', 'install', 'TRUE', '755', 'u:g',
            'run', [], {'f'}, 'N', 'FALSE', 'h', 'b', [], {'c'}, False
        )
        result = filelist.is_specific_install_type(item, {'docker'})
        assert result is False


class TestIsSpecificOperationsExtended:
    """Extended tests for is_specific_operations."""

    @staticmethod
    def test_is_specific_operations_match():
        """Test when operation matches."""
        item = filelist.create_file_item(
            'm', 'copy', 'pkg', 'install', 'TRUE', '755', 'u:g',
            'run', [], {'f'}, 'N', 'FALSE', 'h', 'b', [], {'c'}, False
        )
        result = filelist.is_specific_operations(item, ['copy', 'move'])
        assert result is True

    @staticmethod
    def test_is_specific_operations_no_match():
        """Test when operation doesn't match."""
        item = filelist.create_file_item(
            'm', 'del', 'pkg', 'install', 'TRUE', '755', 'u:g',
            'run', [], {'f'}, 'N', 'FALSE', 'h', 'b', [], {'c'}, False
        )
        result = filelist.is_specific_operations(item, ['copy', 'move'])
        assert result is False


class TestGetMissingDirSet:
    """Test get_missing_dir_set function."""

    @staticmethod
    def test_get_missing_dir_set_empty():
        """Test get_missing_dir_set with empty list."""
        result = filelist.get_missing_dir_set([])
        assert result == set()

    @staticmethod
    def test_get_missing_dir_set_with_copy():
        """Test get_missing_dir_set with copy items."""
        item = filelist.create_file_item(
            'm', 'copy', 'pkg/path', '/install/path/file.txt',
            'TRUE', '755', 'u:g', 'run', [],
            {'f'}, 'N', 'FALSE', 'h', 'b', [], {'c'}, False
        )
        result = filelist.get_missing_dir_set([item])
        # Should return parent directories of the install path
        assert isinstance(result, set)
