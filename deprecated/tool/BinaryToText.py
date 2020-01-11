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
import optparse
import struct

LineSize = 2

parser = optparse.OptionParser()
parser.add_option("-o", dest="outfile", default=None, help="Output file path.")

(options, args) = parser.parse_args()
infiles = args
outfile = options.outfile

if infiles is None or len(infiles) == 0:
    print("No input files are specified.")
    exit(1)
if outfile is None:
    print("No output file are specified.")
    exit(1)

text = ""

for infile in infiles:
    binary = open(infile, "rb").read()

    for row in range(len(binary) // LineSize + 1):
        start = min(row * LineSize, len(binary))
        end = min((row + 1) * LineSize, len(binary))

        bytes_ = list(binary[start:end])
        bytes_.extend([0] * (LineSize - len(binary)))
        for byte in reversed(bytes_):
            text += f"{byte:02x}"
        text += "\n"

f = open(outfile, "w")
f.write(text)
f.close()