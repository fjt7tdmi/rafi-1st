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

interface FetchPipeControllerIF;
    // Common
    logic stall;
    logic flush;

    // FetchAddrGenerateStage
    vaddr_t flushTargetPc;

    // FetchAddrTranslateStage
    logic invalidateITlb;
    logic invalidateITlbDone;

    // ICacheReadStage
    logic invalidateICache;
    logic invalidateICacheDone;
    logic stallFromICacheReadStage;

    // InsnTraverseStage
    logic stallFromInsnTraverseStage;

    // MainPipeController
    logic flushFromMainPipe;
    FlushReason flushReason;

    modport FetchAddrGenerateStage(
    input
        stall,
        flush,
        flushTargetPc
    );

    modport FetchAddrTranslateStage(
    output
        invalidateITlbDone,
    input
        stall,
        flush,
        invalidateITlb
    );

    modport ICacheReadStage(
    output
        invalidateICacheDone,
        stallFromICacheReadStage,
    input
        stall,
        flush,
        invalidateICache
    );

    modport InsnTraverseStage(
    output
        stallFromInsnTraverseStage,
    input
        stall,
        flush
    );

    modport MainPipeController(
    output
        flushFromMainPipe,
        flushReason
    );

    modport FetchPipeController(
    output
        stall,
        flush,
        flushTargetPc,
        invalidateITlb,
        invalidateICache,
    input
        invalidateITlbDone,
        invalidateICacheDone,
        stallFromICacheReadStage,
        stallFromInsnTraverseStage,
        flushFromMainPipe,
        flushReason
    );
endinterface
