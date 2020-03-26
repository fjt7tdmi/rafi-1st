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
    vaddr_t flushTargetPc;

    // FetchAddrTranslateStage
    logic tlbInvalidate;
    logic tlbReplace;
    logic tlbDone;

    // ICacheReadStage
    logic cacheInvalidate;
    logic cacheReplace;
    logic cacheDone;

    // InsnTraverseStage
    logic flushFromFetchPipe;
    FlushReason flushReasonFromFetchPipe;
    vaddr_t flushTargetPcFromFetchPipe;

    // MainPipeController
    logic flushFromMainPipe;
    FlushReason flushReasonFromMainPipe;
    vaddr_t flushTargetPcFromMainPipe;

    modport FetchAddrGenerateStage(
    input
        flush,
        flushTargetPc
    );

    modport FetchAddrTranslateStage(
    output
        tlbDone,
    input
        flush,
        flushTargetPc,
        tlbInvalidate,
        tlbReplace
    );

    modport ICacheReadStage(
    output
        cacheDone,
    input
        flush,
        flushTargetPc,
        cacheInvalidate,
        cacheReplace
    );

    modport InsnTraverseStage(
    output
        flushFromFetchPipe,
        flushReasonFromFetchPipe,
        flushTargetPcFromFetchPipe
    );

    modport MainPipeController(
    output
        flushFromMainPipe,
        flushReasonFromMainPipe,
        flushTargetPcFromMainPipe
    );

    modport FetchPipeController(
    output
        flush,
        flushTargetPc,
        tlbInvalidate,
        tlbReplace,
        cacheInvalidate,
        cacheReplace,
    input
        tlbDone,
        cacheDone,
        flushFromFetchPipe,
        flushReasonFromFetchPipe,
        flushTargetPcFromFetchPipe,
        flushFromMainPipe,
        flushReasonFromMainPipe,
        flushTargetPcFromMainPipe
    );
endinterface
