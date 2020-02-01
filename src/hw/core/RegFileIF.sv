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

interface IntRegFileIF; 
    word_t readValue1;
    word_t readValue2;
    word_t writeValue;
    reg_addr_t readAddr1;
    reg_addr_t readAddr2;
    reg_addr_t writeAddr;
    logic writeEnable;

    modport RegFile(
        output readValue1,
        output readValue2,
        input writeValue,
        input readAddr1,
        input readAddr2,
        input writeAddr,
        input writeEnable
    );

    modport RegReadStage(
        input readValue1,
        input readValue2,
        output readAddr1,
        output readAddr2
    );

    modport RegWriteStage(
        output writeValue,
        output writeAddr,
        output writeEnable        
    );
endinterface

interface FpRegFileIF; 
    uint64_t readValue1;
    uint64_t readValue2;
    uint64_t writeValue;
    reg_addr_t readAddr1;
    reg_addr_t readAddr2;
    reg_addr_t writeAddr;
    logic writeEnable;

    modport RegFile(
        output readValue1,
        output readValue2,
        input writeValue,
        input readAddr1,
        input readAddr2,
        input writeAddr,
        input writeEnable
    );

    modport RegReadStage(
        input readValue1,
        input readValue2,
        output readAddr1,
        output readAddr2
    );

    modport RegWriteStage(
        output writeValue,
        output writeAddr,
        output writeEnable        
    );
endinterface
