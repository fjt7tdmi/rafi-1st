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
    addr_t nextPc;

    logic flush;
    logic flushReq;

    logic bypassStall;
    logic ifStall;
    logic idStall;
    logic rrStall;
    logic exStall;

    logic exStallReq;
    logic maStallReq;

    modport FetchStage(
    input
        ifStall,
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
    input
        exStall,
        flush
    );

    modport MemoryAccessStage(
    output
        maStallReq,
        flushReq,
        nextPc
    );

    modport BypassLogic(
    input
        bypassStall,
        flush
    );

    modport FetchUnit(
    input
        ifStall,
        flush,
        nextPc
    );

    modport PipelineController(
    output
        bypassStall,
        ifStall,
        idStall,
        rrStall,
        exStall,
        flush,
    input
        exStallReq,
        maStallReq,
        flushReq
    );
endinterface
