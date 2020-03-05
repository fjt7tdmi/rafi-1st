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

interface FetchUnitIF;
    vaddr_t nextPc;
    logic flush;
    logic stall;

    logic valid;
    logic fault;
    vaddr_t pc;
    icache_line_t iCacheLine;

    logic invalidateICache;
    logic invalidateTlb;

    modport FetchStage(
    output
        stall,
        flush,
        nextPc,
    input
        valid,
        fault,
        pc,
        iCacheLine
    );

    modport ExecuteStage(
    output
        invalidateICache,
        invalidateTlb
    );

    modport FetchUnit(
    output
        valid,
        fault,
        pc,
        iCacheLine,
    input
        stall,
        flush,
        nextPc,
        invalidateICache,
        invalidateTlb
    );
endinterface
