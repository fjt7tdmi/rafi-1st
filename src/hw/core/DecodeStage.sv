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
    MainPipeControllerIF.DecodeStage ctrl,
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
    vaddr_t pc;
    vaddr_t pc_paddr_debug;
    insn_t insn;
    always_comb begin
        valid = (insnBuffer.readableEntryCount == 1 && is_compressed) || insnBuffer.readableEntryCount >= 2;
        pc = insnBuffer.readEntryLow.pc;
        pc_paddr_debug = insnBuffer.readEntryLow.pc_paddr_debug;
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
        if (valid) begin
            if (insnBuffer.readEntryLow.interruptValid) begin
                trap_info.valid = 1;
                trap_info.cause.isInterrupt = 1;
                trap_info.cause.code = insnBuffer.readEntryLow.interruptCode;
                trap_info.value = pc;
            end
            else if (~is_compressed && insnBuffer.readEntryHigh.interruptValid) begin
                trap_info.valid = 1;
                trap_info.cause.isInterrupt = 1;
                trap_info.cause.code = insnBuffer.readEntryHigh.interruptCode;
                trap_info.value = pc;
            end
            else if (insnBuffer.readEntryLow.fault || (~is_compressed && insnBuffer.readEntryHigh.fault)) begin
                trap_info.valid = 1;
                trap_info.cause.isInterrupt = 0;
                trap_info.cause.code = EXCEPTION_CODE_INSN_PAGE_FAULT;
                trap_info.value = pc;
            end
            else if (op.isUnknown) begin
                trap_info.valid = 1;
                trap_info.cause.isInterrupt = 0;
                trap_info.cause.code = EXCEPTION_CODE_ILLEGAL_INSN;
                trap_info.value = insn;
            end
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
            nextStage.pc_paddr_debug <= '0;
            nextStage.op <= '0;
            nextStage.insn <= '0;
            nextStage.isCompressedInsn <= '0;
            nextStage.csrAddr <= '0;
            nextStage.trapInfo <= '0;
        end
        else if (ctrl.idStall) begin
            nextStage.valid <= nextStage.valid;
            nextStage.pc <= nextStage.pc;
            nextStage.pc_paddr_debug <= nextStage.pc_paddr_debug;
            nextStage.op <= nextStage.op;
            nextStage.insn <= nextStage.insn;
            nextStage.isCompressedInsn <= nextStage.isCompressedInsn;
            nextStage.csrAddr <= nextStage.csrAddr;
            nextStage.trapInfo <= nextStage.trapInfo;
        end
        else if (!valid) begin
            nextStage.valid <= '0;
            nextStage.pc <= '0;
            nextStage.pc_paddr_debug <= '0;
            nextStage.op <= '0;
            nextStage.insn <= '0;
            nextStage.isCompressedInsn <= '0;
            nextStage.csrAddr <= '0;
            nextStage.trapInfo <= '0;
        end
        else begin
            nextStage.valid <= valid;
            nextStage.pc <= pc;
            nextStage.pc_paddr_debug <= pc_paddr_debug;
            nextStage.op <= op;
            nextStage.insn <= insn;
            nextStage.isCompressedInsn <= is_compressed;
            nextStage.csrAddr <= csr_addr;
            nextStage.trapInfo <= trap_info;
        end
    end
endmodule
