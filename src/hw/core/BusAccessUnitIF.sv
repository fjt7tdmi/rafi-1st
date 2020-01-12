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
    icache_mem_addr_t icAddr;
    logic icReadGrant;
    logic icReadReq;
    icache_line_t icReadValue;
    logic icWriteGrant;
    logic icWriteReq;
    icache_line_t icWriteValue;

    dcache_mem_addr_t dcAddr;
    logic dcReadGrant;
    logic dcReadReq;
    dcache_line_t dcReadValue;
    logic dcWriteGrant;
    logic dcWriteReq;
    dcache_line_t dcWriteValue;

    modport FetchUnit(
    output
        icAddr,
        icReadReq,
        icWriteReq,
        icWriteValue,
    input
        icReadValue,
        icReadGrant,
        icWriteGrant
    );

    modport LoadStoreUnit(
    output
        dcAddr,
        dcReadReq,
        dcWriteReq,
        dcWriteValue,
    input
        dcReadGrant,
        dcReadValue,
        dcWriteGrant
    );

    modport BusAccessUnit(
    output
        dcReadGrant,
        dcReadValue,
        dcWriteGrant,
        icReadGrant,
        icReadValue,
        icWriteGrant,
    input
        dcAddr,
        dcReadReq,
        dcWriteReq,
        dcWriteValue,
        icAddr,
        icReadReq,
        icWriteReq,
        icWriteValue
    );
endinterface
