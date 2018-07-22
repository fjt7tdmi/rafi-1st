/*
 * Copyright 2018 Akifumi Fujita
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

import ProcessorTypes::*;

interface BypassLogicIF;
    reg_addr_t writeAddr;
    word_t writeValue;
    logic writeEnable;

    reg_addr_t loadWriteAddr;
    word_t loadWriteValue;
    logic loadWriteEnable;

    reg_addr_t readAddr[BypassReadPortCount];
    word_t readValue[BypassReadPortCount];
    logic hit[BypassReadPortCount];

    modport BypassLogic(
    output
        readValue,
        hit,
    input
        writeAddr,
        writeValue,
        writeEnable,
        loadWriteAddr,
        loadWriteValue,
        loadWriteEnable,
        readAddr
    );

    modport ExecuteStage(
    output
        writeAddr,
        writeValue,
        writeEnable,
        .readAddr1(readAddr[0]),
        .readAddr2(readAddr[1]),
    input
        .readValue1(readValue[0]),
        .readValue2(readValue[1]),
        .hit1(hit[0]),
        .hit2(hit[1])
    );

    modport MemoryAccessStage(
    output
        .writeAddr(loadWriteAddr),
        .writeValue(loadWriteValue),
        .writeEnable(loadWriteEnable)
    );

endinterface
