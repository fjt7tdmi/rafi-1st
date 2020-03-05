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

interface PipelineControllerIF;
    vaddr_t nextPc;

    logic flush;
    logic flushReq;
    vaddr_t flushTarget;

    logic trapValid;
    TrapCause trapCause;
    logic trapReturnValid;
    Privilege trapReturnPriv;

    logic ifStall;
    logic idStall;
    logic rrStall;
    logic bypassStall;
    logic exStallReq;

    modport FetchStage(
    input
        nextPc,
        ifStall,
        flush
    );

    modport InsnBuffer(
    input
        flush
    );

    modport DecodeStage(
    input
        idStall,
        flush
    );

    modport RegReadStage(
    input
        rrStall,
        flush
    );

    modport ExecuteStage(
    output
        exStallReq,
        flushReq,
        flushTarget
    );

    modport BypassLogic(
    input
        bypassStall,
        flush
    );

    modport RegWriteStage(
    output
        trapValid,
        trapCause,
        trapReturnValid,
        trapReturnPriv
    );

    modport PipelineController(
    output
        nextPc,
        flush,
        ifStall,
        idStall,
        rrStall,
        bypassStall,
    input
        flushReq,
        flushTarget,
        trapValid,
        trapCause,
        trapReturnValid,
        trapReturnPriv,
        exStallReq
    );
endinterface
