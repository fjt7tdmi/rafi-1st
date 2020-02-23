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
import OpTypes::*;
import Decoder::*;
import DecoderRV32C::*;

module DecodeStage(
    InsnBufferIF.DecodeStage insnBuffer,
    DecodeStageIF.ThisStage nextStage,
    PipelineControllerIF.DecodeStage ctrl,
    input logic clk,
    input logic rst
);
    logic is_compressed;
    logic [15:0] insn_low;
    logic [15:0] insn_high;
    always_comb begin
        is_compressed = insnBuffer.readEntryLow.insn[1:0] inside {2'b00, 2'b01, 2'b10};
        insn_low = insnBuffer.readEntryLow.insn;
        insn_high = insnBuffer.readEntryHigh.insn;
    end

    logic valid;
    addr_t pc;
    insn_t insn;
    always_comb begin
        valid = (insnBuffer.readableEntryCount == 1 && is_compressed) || insnBuffer.readableEntryCount >= 2;
        pc = insnBuffer.readEntryLow.pc;
        insn = is_compressed ? {16'h0, insn_low} : {insn_high, insn_low};
    end

    Op op;
    csr_addr_t csr_addr;
    always_comb begin
        op = is_compressed ? DecodeRV32C(insn_low) : Decode(insn);
        csr_addr = insn[31:20];
    end

    TrapInfo trap_info;
    always_comb begin
        if (valid && insnBuffer.readEntryLow.fault) begin
            trap_info.valid = '1;
            trap_info.cause = ExceptionCode_InsnPageFault;
            trap_info.value = pc;
        end
        else if (valid && op.isUnknown) begin
            trap_info.valid = 1;
            trap_info.cause = ExceptionCode_IllegalInsn;
            trap_info.value = insn;
        end
        else begin
            trap_info = '0;
        end
    end

    always_comb begin
        if (ctrl.idStall) begin
            insnBuffer.readLow = '0;
            insnBuffer.readHigh = '0;
        end
        else begin
            insnBuffer.readLow = valid;
            insnBuffer.readHigh = valid && !is_compressed;
        end
    end

    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            nextStage.valid <= '0;
            nextStage.pc <= '0;
            nextStage.op <= '0;
            nextStage.insn <= '0;
            nextStage.csrAddr <= '0;
            nextStage.trapInfo <= '0;
        end
        else if (ctrl.idStall) begin
            nextStage.valid <= nextStage.valid;
            nextStage.pc <= nextStage.pc;
            nextStage.op <= nextStage.op;
            nextStage.insn <= nextStage.insn;
            nextStage.csrAddr <= nextStage.csrAddr;
            nextStage.trapInfo <= nextStage.trapInfo;
        end
        else if (!valid) begin
            nextStage.valid <= '0;
            nextStage.pc <= '0;
            nextStage.op <= '0;
            nextStage.insn <= '0;
            nextStage.csrAddr <= '0;
            nextStage.trapInfo <= '0;
        end
        else begin
            nextStage.valid <= valid;
            nextStage.pc <= pc;
            nextStage.op <= op;
            nextStage.insn <= insn;
            nextStage.csrAddr <= csr_addr;
            nextStage.trapInfo <= trap_info;
        end
    end
endmodule
