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

import json
import os
import optparse
import struct
from rafi import metabuild
from rafi import riscv_tests

parser = optparse.OptionParser()
parser.add_option("-o", dest="outfile", default=None, help="Output file path.")
parser.add_option("-i", dest="infiles", action="append", default=[], help="Input file path.")

(options, args) = parser.parse_args()
outfile = options.outfile

if outfile is None:
    print("No output file are specified.")
    exit(1)

#
# Functions
#

def make_linux_rule():
    return """
build work/vmlinux.bin: objcopy $
    Linux/vmlinux
    start = 0x00000000
    end = 0x00400000
"""

def make_test_build_rule():
    src_dir = "./TargetPrograms/Sources"
    out_dir = "./TargetPrograms/Outputs"
    names = list(map(lambda x: x.rstrip(".S"), os.listdir(src_dir)))

    rule = ""
    for name in names:
        rule += f"""
build {out_dir}/{name}.o: as $
    TargetPrograms/Sources/{name}.S $
    | {out_dir}

build {out_dir}/{name}.bin: objcopy $
    {out_dir}/{name}.o
    section = .text
    start = 0x00000000
    end = 0x00000040

build {out_dir}/{name}.txt: BinaryToText $
    {out_dir}/{name}.bin
"""
    return rule

def make_mkdir_rule():
    paths = [
        "./work/Trace/Emulator",
        "./work/Trace/Processor",
        "./work/PcLog",
    ]
    rule = ""
    for path in paths:
        rule += f"""
build {path}: mkdir
"""
    return rule

#
# Entry Point
#

header = """
include Build/Rules.ninja
"""

# linux_rule = make_linux_rule()
test_build_rule = make_test_build_rule()
mkdir_rule = make_mkdir_rule()

with open(outfile, "w") as f:
    f.write(header)
    # f.write(linux_rule)
    f.write(test_build_rule)
    f.write(mkdir_rule)
    for infile in options.infiles:
        f.write(metabuild.metabuild(infile))