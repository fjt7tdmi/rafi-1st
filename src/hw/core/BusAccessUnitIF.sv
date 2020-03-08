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

import CacheTypes::*;

// Interface between D$, I$ and BusAccessUnit

interface BusAccessUnitIF;
    icache_mem_addr_t icacheAddr;
    logic icacheReadGrant;
    logic icacheReadReq;
    icache_line_t icacheReadValue;
    logic icacheWriteGrant;
    logic icacheWriteReq;
    icache_line_t icacheWriteValue;

    dcache_mem_addr_t dcacheAddr;
    logic dcacheReadGrant;
    logic dcacheReadReq;
    dcache_line_t dcacheReadValue;
    logic dcacheWriteGrant;
    logic dcacheWriteReq;
    dcache_line_t dcacheWriteValue;

    modport FetchUnit(
    output
        icacheAddr,
        icacheReadReq,
        icacheWriteReq,
        icacheWriteValue,
    input
        icacheReadValue,
        icacheReadGrant,
        icacheWriteGrant
    );

    modport LoadStoreUnit(
    output
        dcacheAddr,
        dcacheReadReq,
        dcacheWriteReq,
        dcacheWriteValue,
    input
        dcacheReadGrant,
        dcacheReadValue,
        dcacheWriteGrant
    );

    modport BusAccessUnit(
    output
        dcacheReadGrant,
        dcacheReadValue,
        dcacheWriteGrant,
        icacheReadGrant,
        icacheReadValue,
        icacheWriteGrant,
    input
        dcacheAddr,
        dcacheReadReq,
        dcacheWriteReq,
        dcacheWriteValue,
        icacheAddr,
        icacheReadReq,
        icacheWriteReq,
        icacheWriteValue
    );
endinterface
