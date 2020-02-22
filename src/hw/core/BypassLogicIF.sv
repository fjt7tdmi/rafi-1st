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

import RafiTypes::*;

interface IntBypassLogicIF;
    reg_addr_t writeAddr;
    word_t writeValue;
    logic writeEnable;

    reg_addr_t readAddr1;
    reg_addr_t readAddr2;
    word_t readValue1;
    word_t readValue2;
    logic hit1;
    logic hit2;

    modport BypassLogic(
    output
        readValue1,
        readValue2,
        hit1,
        hit2,
    input
        writeAddr,
        writeValue,
        writeEnable,
        readAddr1,
        readAddr2
    );

    modport ExecuteStage(
    output
        writeAddr,
        writeValue,
        writeEnable,
        readAddr1,
        readAddr2,
    input
        readValue1,
        readValue2,
        hit1,
        hit2
    );
endinterface

interface FpBypassLogicIF;
    reg_addr_t writeAddr;
    uint64_t writeValue;
    logic writeEnable;

    reg_addr_t readAddr1;
    reg_addr_t readAddr2;
    reg_addr_t readAddr3;
    uint64_t readValue1;
    uint64_t readValue2;
    uint64_t readValue3;
    logic hit1;
    logic hit2;
    logic hit3;

    modport BypassLogic(
    output
        readValue1,
        readValue2,
        readValue3,
        hit1,
        hit2,
        hit3,
    input
        writeAddr,
        writeValue,
        writeEnable,
        readAddr1,
        readAddr2,
        readAddr3
    );

    modport ExecuteStage(
    output
        writeAddr,
        writeValue,
        writeEnable,
        readAddr1,
        readAddr2,
        readAddr3,
    input
        readValue1,
        readValue2,
        readValue3,
        hit1,
        hit2,
        hit3
    );
endinterface
