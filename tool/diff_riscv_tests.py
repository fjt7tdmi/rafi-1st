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

import fnmatch
import json
import multiprocessing
import optparse
import os
import subprocess

from functools import reduce
from operator import or_

if os.name == "nt":
    DiffPath = "rafi-emu/build/Debug/rafi-diff.exe"
else:
    DiffPath = "rafi-emu/build/rafi-diff"

EmuTraceDirPath = "rafi-emu/work/riscv_tests/trace"
SimTraceDirPath = "work/riscv_tests/trace"

#
# Functions
#
def MakeDiffCommand(testname, cycle):
    emu_trace_path = f"{EmuTraceDirPath}/{testname}.trace.bin"
    sim_trace_path = f"{SimTraceDirPath}/{testname}.trace.bin"
    return [
        DiffPath,
        "--expect", emu_trace_path,
        "--actual", sim_trace_path,
    ]

def RunDiff(config):
    cmd = MakeDiffCommand(config['name'], config['cycle'])
    print(f"Run {' '.join(cmd)}")

    result = subprocess.run(cmd)
    if result.returncode != 0:
        return False # Emulation Failure

def RunTests(configs):
    with multiprocessing.Pool(multiprocessing.cpu_count()) as p:
        p.map(RunDiff, configs)

#
# Entry point
#
if __name__ == '__main__':
    parser = optparse.OptionParser()
    parser.add_option("-f", dest="filter", default=None, help="Filter test by name.")
    parser.add_option("-i", dest="input_path", default=None, help="Input test list json path.")
    parser.add_option("-l", dest="list_tests", action="store_true", default=False, help="List test names.")

    (options, args) = parser.parse_args()

    if options.input_path is None:
        print("Input test list json is not specified.")
        exit(1)

    configs = []

    with open(options.input_path, "r") as f:
        configs = json.load(f)

    if options.list_tests:
        for config in configs:
            print(config['name'])
        exit(0)

    if options.filter is not None:
        configs = list(filter(lambda config: fnmatch.fnmatch(config['name'], options.filter), configs))

    RunTests(configs)
