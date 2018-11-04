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
    CheckIoPath = "build/rafi-emu/Debug/rafi-check-io.exe"
    TestCorePath = "build/Debug/test_Core.exe"
else:
    CheckIoPath = "build/rafi-emu/rafi-check-io"
    TestCorePath = "build/test_Core"

BinaryDirPath = "rafi-emu/work/riscv_tests"
TraceDirPath = "work/riscv_tests/trace"
VcdDirPath = "work/riscv_tests/vcd"

#
# Functions
#
def InitializeDirectory(path):
    os.makedirs(path, exist_ok=True)
    for filename in os.listdir(f"{TraceDirPath}"):
        os.remove(f"{TraceDirPath}/{filename}")
    for filename in os.listdir(f"{VcdDirPath}"):
        os.remove(f"{VcdDirPath}/{filename}")

def MakeCheckIoCommand(trace_paths):
    cmd = [CheckIoPath]
    cmd.extend(trace_paths)
    return cmd

def MakeTestCoreCommand(testname, cycle):
    binary_path = f"{BinaryDirPath}/{testname}.bin"
    trace_path = f"{TraceDirPath}/{testname}.trace.bin"
    vcd_path = f"{VcdDirPath}/{testname}.vcd"
    return [
        TestCorePath,
        "--cycle", str(cycle),
        "--load-path", f"{binary_path}",
        "--dump-path", trace_path,
        "--vcd-path", vcd_path,
    ]

def VerifyTraces(paths):
    cmd = MakeCheckIoCommand(paths)
    print(f"Run {' '.join(cmd)}")
    subprocess.run(cmd)

def RunTestCore(config):
    cmd = MakeTestCoreCommand(config['name'], config['cycle'])
    print(f"Run {' '.join(cmd)}")

    result = subprocess.run(cmd)
    if result.returncode != 0:
        return False # Emulation Failure

def RunTests(configs):
    with multiprocessing.Pool(multiprocessing.cpu_count()) as p:
        p.map(RunTestCore, configs)

    trace_paths = list(map(lambda config: f"{TraceDirPath}/{config['name']}.trace.bin", configs))
    VerifyTraces(trace_paths)

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

    print("-------------------------------------------------------------")
    InitializeDirectory(TraceDirPath)

    print("Run test on verilator:")
    RunTests(configs)
