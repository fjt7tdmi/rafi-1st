# Copyright 2018 Akifumi Fujita
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os

def _is_supported(path):
    # TODO: remove this
    # exclude
    if path.startswith("rv32ui-v-sb"):
        return False
    if path.startswith("rv32ui-v-lb"):
        return False

    if path.startswith("rv32ui-"):
        return True
    elif path.startswith("rv32ua-"):
        return True
    elif path.startswith("rv32um-"):
        return True
    elif path.startswith("rv32si-"):
        return True
    elif path.startswith("rv32mi-"):
        return True
    else:
        return False

def list_test_names(riscv_tests_dir):
    files = os.listdir(f"{riscv_tests_dir}")
    elf_files = filter(lambda path: not path.endswith(".dump"), files)
    supported_files = filter(_is_supported, elf_files)
    return list(supported_files)
