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
import functools
import operator

Extensions = [".cpp", ".h", ".py", ".S", ".sv"]
LinesToRead = 10
KeyWords = ["Copyright", "Akifumi", "Fujita"]

filesToCheck = []
for root, dirs, files in os.walk(os.getcwd()):
    for name in files:
        path = os.path.join(root, name)
        (_, ext) = os.path.splitext(path)
        if ext in Extensions:
            filesToCheck.append(path)

error = False

for path in filesToCheck:
    with open(path, "r", encoding='utf8') as f:
        copyrightFound = False
        for i in range(LinesToRead):
            line = f.readline()
            if line is None:
                break
            if functools.reduce(operator.and_, map(lambda keyword: keyword in line, KeyWords)):
                copyrightFound = True
                break
        if not copyrightFound:
            error = True
            print(f"Copyright is not found in '{path}'.'")
        
if not error:
    print(f"No error.")
