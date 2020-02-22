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

import OpTypes::*;
import ProcessorTypes::*;

interface ExecuteStageIF;
    logic valid;
    addr_t pc;
    insn_t insn;
    Op op;

    word_t dstIntRegValue;
    uint64_t dstFpRegValue;

    logic branchTaken;
    addr_t branchTarget;

    TrapInfo trapInfo;
    logic trapReturn;

    modport ThisStage(
    output
        valid,
        pc,
        insn,
        op,
        dstIntRegValue,
        dstFpRegValue,
        branchTaken,
        branchTarget,
        trapInfo,
        trapReturn
    );

    modport NextStage(
    input
        valid,
        pc,
        insn,
        op,
        dstIntRegValue,
        dstFpRegValue,
        branchTaken,
        branchTarget,
        trapInfo,
        trapReturn
    );
endinterface
