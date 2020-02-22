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
import Decoder::*;
import RafiTypes::*;

module DecodeStage(
    InsnBufferIF.DecodeStage insnBuffer,
    DecodeStageIF.ThisStage nextStage,
    PipelineControllerIF.DecodeStage ctrl,
    input logic clk,
    input logic rst
);
    logic valid;
    addr_t pc;
    logic [31:0] insn;
    always_comb begin
        valid = insnBuffer.readableEntryCount >= 2;
        pc = insnBuffer.readEntryLow.pc;
        insn = {insnBuffer.readEntryHigh.insn, insnBuffer.readEntryLow.insn};
    end

    Op op;
    csr_addr_t csrAddr;
    always_comb begin
        op = Decode(insn);
        csrAddr = insn[31:20];
    end

    TrapInfo trapInfo;
    always_comb begin
        if (valid && insnBuffer.readEntryLow.fault) begin
            trapInfo.valid = '1;
            trapInfo.cause = ExceptionCode_InsnPageFault;
            trapInfo.value = pc;
        end
        else if (valid && op.isUnknown) begin
            trapInfo.valid = 1;
            trapInfo.cause = ExceptionCode_IllegalInsn;
            trapInfo.value = insn;
        end
        else begin
            trapInfo = '0;
        end
    end

    always_comb begin
        if (ctrl.idStall) begin
            insnBuffer.readLow = '0;
            insnBuffer.readHigh = '0;
        end
        else begin
            insnBuffer.readLow = valid;
            insnBuffer.readHigh = valid;
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
            nextStage.csrAddr <= csrAddr;
            nextStage.trapInfo <= trapInfo;
        end
    end
endmodule
