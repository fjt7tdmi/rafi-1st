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
    logic flush;

    // FetchAddrGenerateStage
    vaddr_t flushTargetPc;

    // FetchAddrTranslateStage
    logic invalidateITlb;
    logic invalidateITlbDone;

    // ICacheReadStage
    logic invalidateICache;
    logic invalidateICacheDone;

    // InsnTraverseStage
    logic flushFromFetchPipe;
    FlushReason flushReasonFromFetchPipe;

    // MainPipeController
    logic flushFromMainPipe;
    FlushReason flushReasonFromMainPipe;

    modport FetchAddrGenerateStage(
    input
        flush,
        flushTargetPc
    );

    modport FetchAddrTranslateStage(
    output
        invalidateITlbDone,
    input
        flush,
        invalidateITlb
    );

    modport ICacheReadStage(
    output
        invalidateICacheDone,
    input
        flush,
        invalidateICache
    );

    modport InsnTraverseStage(
    output
        flushFromFetchPipe,
        flushReasonFromFetchPipe
    );

    modport MainPipeController(
    output
        flushFromMainPipe,
        flushReasonFromMainPipe
    );

    modport FetchPipeController(
    output
        flush,
        flushTargetPc,
        invalidateITlb,
        invalidateICache,
    input
        invalidateITlbDone,
        invalidateICacheDone,
        flushFromFetchPipe,
        flushReasonFromFetchPipe,
        flushFromMainPipe,
        flushReasonFromMainPipe
    );
endinterface
