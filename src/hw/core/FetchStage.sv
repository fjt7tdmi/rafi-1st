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
import ProcessorTypes::*;

module FetchStage(
    InsnBufferIF.FetchStage insnBuffer,
    FetchUnitIF.FetchStage fetchUnit,
    PipelineControllerIF.FetchStage ctrl,
    CsrIF.FetchStage csr,
    input   logic clk,
    input   logic rst
);
    localparam INSN_COUNT_IN_LINE = ICACHE_LINE_WIDTH / INSN_WIDTH;
    localparam INDEX_WIDTH = $clog2(INSN_COUNT_IN_LINE);

    // Wires
    logic [INDEX_WIDTH-1:0] index;
    insn_t [INSN_COUNT_IN_LINE-1:0] insns;
    insn_t insn;
    logic stall;

    always_comb begin
        index = fetchUnit.pc[INDEX_WIDTH+$clog2(INSN_SIZE)-1:$clog2(INSN_SIZE)];
        insns = fetchUnit.iCacheLine;
        insn = insns[index];
        stall = ctrl.ifStall || insnBuffer.writableEntryCount < 2;
    end

    always_comb begin
        insnBuffer.writeLow = !stall && fetchUnit.valid;
        insnBuffer.writeHigh = !stall && fetchUnit.valid;

        insnBuffer.writeEntryLow.pc = fetchUnit.pc;
        insnBuffer.writeEntryLow.fault = fetchUnit.fault;
        insnBuffer.writeEntryLow.insn = insn[15:0];

        insnBuffer.writeEntryHigh.pc = fetchUnit.pc + 2;
        insnBuffer.writeEntryHigh.fault = fetchUnit.fault;
        insnBuffer.writeEntryHigh.insn = insn[31:16];
    end
endmodule