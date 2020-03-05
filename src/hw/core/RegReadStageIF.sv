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
import RafiTypes::*;

interface RegReadStageIF;
    logic valid;
    vaddr_t pc;
    insn_t insn;
    logic isCompressedInsn;
    Op op;
    csr_addr_t csrAddr;
    word_t srcIntRegValue1;
    word_t srcIntRegValue2;
    uint64_t srcFpRegValue1;
    uint64_t srcFpRegValue2;
    uint64_t srcFpRegValue3;
    TrapInfo trapInfo;

    modport ThisStage(
    output
        valid,
        pc,
        insn,
        isCompressedInsn,
        op,
        csrAddr,
        srcIntRegValue1,
        srcIntRegValue2,
        srcFpRegValue1,
        srcFpRegValue2,
        srcFpRegValue3,
        trapInfo
    );

    modport NextStage(
    input
        valid,
        pc,
        insn,
        isCompressedInsn,
        op,
        csrAddr,
        srcIntRegValue1,
        srcIntRegValue2,
        srcFpRegValue1,
        srcFpRegValue2,
        srcFpRegValue3,
        trapInfo
    );
endinterface
