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
import RafiTypes::*;

module InsnTraverseStage(
    ICacheReadStageIF.NextStage prevStage,
    InsnBufferIF.FetchStage insnBuffer,
    FetchPipeControllerIF.InsnTraverseStage ctrl,
    InterruptControllerIF.FetchStage interrupt,
    input   logic clk,
    input   logic rst
);
    localparam INSN_COUNT_IN_LINE = ICACHE_LINE_WIDTH / INSN_WIDTH;
    localparam INDEX_WIDTH = $clog2(INSN_COUNT_IN_LINE);

    logic valid;
    logic fetch_compressed_insn;
    vaddr_t pc_low;
    vaddr_t pc_high;
    always_comb begin
        valid = prevStage.valid;
        fetch_compressed_insn = prevStage.pc_vaddr[1];
        pc_low = prevStage.pc_vaddr;
        pc_high = prevStage.pc_vaddr + 2;
    end

    logic [INDEX_WIDTH-1:0] index;
    insn_t [INSN_COUNT_IN_LINE-1:0] insns;
    insn_t insn;
    logic insnBufferFull;
    always_comb begin
        index = prevStage.pc_vaddr[INDEX_WIDTH+$clog2(INSN_SIZE)-1:$clog2(INSN_SIZE)];
        insns = prevStage.cacheLine;
        insn = insns[index];
        insnBufferFull = insnBuffer.writableEntryCount < 2;
    end

    // FetchPipeController
    always_comb begin
        ctrl.flushFromFetchPipe = valid && (prevStage.tlbMiss || prevStage.cacheMiss || insnBufferFull);

        if (prevStage.tlbMiss) begin
            ctrl.flushReasonFromFetchPipe = FlushReason_ITlbMiss;
        end
        else if (prevStage.cacheMiss) begin
            ctrl.flushReasonFromFetchPipe = FlushReason_ICacheMiss;
        end
        else if (insnBufferFull) begin
            ctrl.flushReasonFromFetchPipe = FlushReason_InsnBufferFull;
        end
        else begin
            ctrl.flushReasonFromFetchPipe = '0;
        end

        ctrl.flushTargetPcFromFetchPipe = pc_low;
    end

    // InsnBuffer
    always_comb begin
        insnBuffer.writeLow = !insnBufferFull && prevStage.valid && ~fetch_compressed_insn;
        insnBuffer.writeHigh = !insnBufferFull && prevStage.valid;
        insnBuffer.writeEntryLow.pc = pc_low;
        insnBuffer.writeEntryLow.insn = insn[15:0];
        insnBuffer.writeEntryLow.fault = prevStage.tlbFault;
        insnBuffer.writeEntryLow.interruptValid = interrupt.valid;
        insnBuffer.writeEntryLow.interruptCode = interrupt.code;
        insnBuffer.writeEntryHigh.pc = fetch_compressed_insn ? pc_low : pc_high;
        insnBuffer.writeEntryHigh.insn = insn[31:16];
        insnBuffer.writeEntryHigh.fault = prevStage.tlbFault;
        insnBuffer.writeEntryHigh.interruptValid = interrupt.valid;
        insnBuffer.writeEntryHigh.interruptCode = interrupt.code;
    end
endmodule