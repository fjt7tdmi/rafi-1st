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

interface RegReadStageIF;
    logic valid;
    Op op;
    addr_t pc;
    insn_t insn;
    csr_addr_t csrAddr;
    reg_addr_t srcRegAddr1;
    reg_addr_t srcRegAddr2;
    reg_addr_t dstRegAddr;
    word_t srcIntRegValue1;
    word_t srcIntRegValue2;
    uint64_t srcFpRegValue1;
    uint64_t srcFpRegValue2;
    TrapInfo trapInfo;

    modport ThisStage(
    output
        valid,
        op,
        pc,
        insn,
        csrAddr,
        srcRegAddr1,
        srcRegAddr2,
        srcIntRegValue1,
        srcIntRegValue2,
        srcFpRegValue1,
        srcFpRegValue2,
        dstRegAddr,
        trapInfo
    );

    modport NextStage(
    input
        valid,
        op,
        pc,
        insn,
        csrAddr,
        srcRegAddr1,
        srcRegAddr2,
        srcIntRegValue1,
        srcIntRegValue2,
        srcFpRegValue1,
        srcFpRegValue2,
        dstRegAddr,
        trapInfo        
    );
endinterface
