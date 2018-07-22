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

    .text
start:
    li      a0, 1           # Store Value
    li      a1, 0           # Counter
    li      a2, 0x4         # Counter Max
    li      a3, 0x80001000  # Host IO addr
loop:
    addi    a1, a1, 0x1
    bne     a1, a2, loop
    sw      a0, (a3)
    addi    a0, a0, 1
    li      a1, 0
    j       loop
