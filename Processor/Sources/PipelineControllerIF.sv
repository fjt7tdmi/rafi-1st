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

    logic ifStall;
    logic idStall;
    logic rrStall;
    logic exStall;

    logic exStallReq;
    logic maStallReq;

    uint64_t opCommitCount;

    modport FetchStage(
    input
        .stall(ifStall),
        .flush(flush)
    );

    modport DecodeStage(
    input
        .stall(idStall),
        .flush(flush),
        .opCommitCount(opCommitCount)
    );

    modport RegReadStage(
    input
        .stall(rrStall),
        .flush(flush)
    );

    modport ExecuteStage(
    output
        .stallReq(exStallReq),
    input
        .stall(exStall),
        .flush(flush)
    );

    modport MemoryAccessStage(
    output
        .stallReq(maStallReq),
        .flushReq(flushReq),
        .nextPc(nextPc),
        .opCommitCount(opCommitCount)
    );

    modport BypassLogic(
    input
        .stall(rrStall),
        .flush(flush)
    );

    modport FetchUnit(
    input
        .stall(ifStall),
        .flush(flush),
        .nextPc(nextPc)
    );

    modport PipelineController(
    output
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
