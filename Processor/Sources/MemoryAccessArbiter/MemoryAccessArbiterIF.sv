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

// Interface between D$, I$, arbiter and memory

interface MemoryAccessArbiterIF #(
    // Bit width of cache line
    // e.g. if cache line size is 64 byte, LineSize = 64
    parameter LineSize,

    // Address to specify cacheline
    // e.g. if virtual address is 32 bit and cache line size is 64 (2^6) byte, AddrWidth = (32-6) = 26
    parameter AddrWidth
);
    localparam LineWidth = LineSize * ByteWidth;

    logic [AddrWidth-1:0] icAddr;
    logic icReadGrant;
    logic icReadReq;
    logic [LineWidth-1:0] icReadValue;
    logic icWriteGrant;
    logic icWriteReq;
    logic [LineWidth-1:0] icWriteValue;

    logic [AddrWidth-1:0] dcAddr;
    logic dcReadGrant;
    logic dcReadReq;
    logic [LineWidth-1:0] dcReadValue;
    logic dcWriteGrant;
    logic dcWriteReq;
    logic [LineWidth-1:0] dcWriteValue;

    logic [AddrWidth-1:0] memoryAddr;
    logic memoryDone;
    logic memoryEnable;
    logic memoryIsWrite;
    logic [LineWidth-1:0] memoryReadValue;
    logic [LineWidth-1:0] memoryWriteValue;

    modport FetchUnit(
    output
        .addr(icAddr),
        .readReq(icReadReq),
        .writeReq(icWriteReq),
        .writeValue(icWriteValue),
    input
        .readValue(icReadValue),
        .readGrant(icReadGrant),
        .writeGrant(icWriteGrant)
    );

    modport LoadStoreUnit(
    output
        .addr(dcAddr),
        .readReq(dcReadReq),
        .writeReq(dcWriteReq),
        .writeValue(dcWriteValue),
    input
        .readGrant(dcReadGrant),
        .readValue(dcReadValue),
        .writeGrant(dcWriteGrant)
    );

    modport MemoryAccessArbiter(
    output
        dcReadGrant,
        dcReadValue,
        dcWriteGrant,
        icReadGrant,
        icReadValue,
        icWriteGrant,
        memoryAddr,
        memoryEnable,
        memoryIsWrite,
        memoryWriteValue,
    input
        dcAddr,
        dcReadReq,
        dcWriteReq,
        dcWriteValue,
        icAddr,
        icReadReq,
        icWriteReq,
        icWriteValue,
        memoryDone,
        memoryReadValue
    );

    modport Memory(
    output
        .done(memoryDone),
        .readValue(memoryReadValue),
    input
        .addr(memoryAddr),
        .enable(memoryEnable),
        .isWrite(memoryIsWrite),
        .writeValue(memoryWriteValue)
    );
endinterface
