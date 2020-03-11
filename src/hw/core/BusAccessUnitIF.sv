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

    paddr_t itlbAddr;
    logic itlbReadGrant;
    logic itlbReadReq;
    uint32_t itlbReadValue;
    logic itlbWriteGrant;
    logic itlbWriteReq;
    uint32_t itlbWriteValue;

    paddr_t dcacheAddr;
    logic dcacheReadGrant;
    logic dcacheReadReq;
    dcache_line_t dcacheReadValue;
    logic dcacheWriteGrant;
    logic dcacheWriteReq;
    dcache_line_t dcacheWriteValue;

    paddr_t dtlbAddr;
    logic dtlbReadGrant;
    logic dtlbReadReq;
    uint32_t dtlbReadValue;
    logic dtlbWriteGrant;
    logic dtlbWriteReq;
    uint32_t dtlbWriteValue;

    modport FetchUnit(
    output
        icacheAddr,
        icacheReadReq,
        icacheWriteReq,
        icacheWriteValue,
        itlbAddr,
        itlbReadReq,
        itlbWriteReq,
        itlbWriteValue,
    input
        icacheReadValue,
        icacheReadGrant,
        icacheWriteGrant,
        itlbReadValue,
        itlbReadGrant,
        itlbWriteGrant
    );

    modport LoadStoreUnit(
    output
        dcacheAddr,
        dcacheReadReq,
        dcacheWriteReq,
        dcacheWriteValue,
        dtlbAddr,
        dtlbReadReq,
        dtlbWriteReq,
        dtlbWriteValue,
    input
        dcacheReadGrant,
        dcacheReadValue,
        dcacheWriteGrant,
        dtlbReadGrant,
        dtlbReadValue,
        dtlbWriteGrant
    );

    modport BusAccessUnit(
    output
        dcacheReadGrant,
        dcacheReadValue,
        dcacheWriteGrant,
        dtlbReadGrant,
        dtlbReadValue,
        dtlbWriteGrant,
        icacheReadGrant,
        icacheReadValue,
        icacheWriteGrant,
        itlbReadGrant,
        itlbReadValue,
        itlbWriteGrant,
    input
        dcacheAddr,
        dcacheReadReq,
        dcacheWriteReq,
        dcacheWriteValue,
        dtlbAddr,
        dtlbReadReq,
        dtlbWriteReq,
        dtlbWriteValue,
        icacheAddr,
        icacheReadReq,
        icacheWriteReq,
        icacheWriteValue,
        itlbAddr,
        itlbReadReq,
        itlbWriteReq,
        itlbWriteValue
    );
endinterface
