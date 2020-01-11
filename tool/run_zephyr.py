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

import optparse
import os
import subprocess

if os.name == "nt":
    DumpPath = "./build/Debug/rafi-dump.exe"
    DumpPcPath = "./build/Debug/rafi-dump-pc.exe"
    TestCorePath = "./build/Debug/test_Core.exe"
else:
    DumpPath = "./build/rafi-dump"
    DumpPcPath = "./build/rafi-dump-pc"
    TestCorePath = "./build/test_Core"

BinaryDirPath = "rafi-emu/work/zephyr"
TraceDirPath = "work/zephyr/trace"
VcdDirPath = "work/zephyr/vcd"
ZephyrDirPath = os.environ["ZEPHYR_BASE"]

DefaultCycle = 5000
DefaultTestName = "philosophers"

#
# Functions
#
def InitializeDirectory(path):
    os.makedirs(path, exist_ok=True)
    for filename in os.listdir(f"{path}"):
        os.remove(f"{path}/{filename}")

def PrintCommand(cmd):
    print(f"[cmd] {' '.join(cmd)}")

def MakeTestCoreCommand(testname, cycle):
    ram_bin_path = f"{BinaryDirPath}/{config['name']}.ram.bin"
    rom_bin_path = f"{BinaryDirPath}/{config['name']}.rom.bin"
    trace_path = f"{TraceDirPath}/{testname}.trace.bin"
    vcd_path = f"{VcdDirPath}/{testname}.vcd"

    cmd = [
        TestCorePath,
        "--cycle", str(cycle),
        "--ram-path", f"{ram_bin_path}",
        "--rom-path", f"{rom_bin_path}",
        "--dump-path", trace_path,
        "--vcd-path", vcd_path,
    ]
    if config['enable_dump_memory']:
        cmd.append("--enable-dump-memory")
    return cmd

def MakeDumpCommand(testname):
    trace_bin_path = f"{TraceDirPath}/{testname}.trace.bin"
    return [
        DumpPath,
        trace_bin_path
    ]

def MakeDumpPcCommand(testname):
    trace_bin_path = f"{TraceDirPath}/{testname}.trace.bin"
    return [
        DumpPcPath,
        trace_bin_path
    ]

def MakeAddrToLineCommand(testname):
    elf_path = os.path.join(ZephyrDirPath, f"samples/{config['name']}/outdir/qemu_riscv32/zephyr.elf")
    return [
        "riscv64-unknown-elf-addr2line",
        "-e", elf_path,
    ]

def RunTestCore(config):
    cmd = MakeTestCoreCommand(config['name'], config['cycle'])
    PrintCommand(cmd)

    return subprocess.run(cmd).returncode

def RunDump(config):
    trace_txt_path = f"{TraceDirPath}/{config['name']}.trace.txt"

    cmd = MakeDumpCommand(config['name'])
    PrintCommand(cmd)

    with open(trace_txt_path, 'w') as f:
        return subprocess.run(cmd, stdout=f).returncode

    return subprocess.run(cmd).returncode

def RunDumpPc(config):
    pc_txt_path = f"{TraceDirPath}/{config['name']}.pc.txt"
    line_txt_path = f"{TraceDirPath}/{config['name']}.line.txt"

    cmd_dump_pc = MakeDumpPcCommand(config['name'])
    PrintCommand(cmd_dump_pc)

    with open(pc_txt_path, 'w') as f:
        subprocess.run(cmd_dump_pc, stdout=f).returncode

    cmd_addr2line = MakeAddrToLineCommand(config['name'])
    PrintCommand(cmd_addr2line)

    with open(pc_txt_path, 'r') as in_file:
        with open(line_txt_path, 'w') as out_file:
            subprocess.run(cmd_addr2line, stdin=in_file, stdout=out_file).returncode

#
# Entry point
#
if __name__ == '__main__':
    parser = optparse.OptionParser()
    parser.add_option("-c", dest="cycle", default=DefaultCycle, help="Number of emulation cycles.")
    parser.add_option("-n", dest="name", default=DefaultTestName, help="Test name.")
    parser.add_option("--dump", dest="dump", action="store_true", default=False, help="Run rafi-dump after emulation.")
    parser.add_option("--dump-pc", dest="dump_pc", action="store_true", default=False, help="Run rafi-dump-pc and addr2line after emulation.")
    parser.add_option("--enable-dump-memory", dest="enable_dump_memory", action="store_true", default=False, help="Enable memory dump.")

    (options, args) = parser.parse_args()

    config = {
        'name': options.name,
        'cycle': options.cycle,
        'enable_dump_memory': options.enable_dump_memory,
    }

    InitializeDirectory(TraceDirPath)

    result = RunTestCore(config)
    if result != 0:
        exit(result)

    if options.dump:
        RunDump(config)

    if options.dump_pc:
        RunDumpPc(config)