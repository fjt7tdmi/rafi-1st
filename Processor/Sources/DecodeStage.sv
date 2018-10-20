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
import ProcessorTypes::*;

module DecodeStage(
    FetchStageIF.NextStage prevStage,
    DecodeStageIF.ThisStage nextStage,
    PipelineControllerIF.DecodeStage ctrl,
    input logic clk,
    input logic rst
);
    logic valid;
    Op op;
    csr_addr_t csrAddr;
    reg_addr_t srcRegAddr1;
    reg_addr_t srcRegAddr2;
    reg_addr_t dstRegAddr;
    TrapInfo trapInfo;
    uint64_t nextOpId;

    // Register
    uint64_t opId;

    always_comb begin
        valid = prevStage.valid;
        op = Decode(prevStage.insn);
        csrAddr = prevStage.insn[31:20];
        srcRegAddr1 = prevStage.insn[19:15];
        srcRegAddr2 = prevStage.insn[24:20];
        dstRegAddr = prevStage.insn[11:7];

        if (valid && !prevStage.trapInfo.valid && op.isUnknown) begin
            trapInfo.valid = 1;
            trapInfo.cause = ExceptionCode_IllegalInsn;
            trapInfo.value = prevStage.insn;
        end
        else begin
            trapInfo = prevStage.trapInfo;
        end
        nextOpId = valid ? opId + 1 : opId;
    end

    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            nextStage.valid <= '0;
            nextStage.pc <= '0;
            nextStage.op <= '0;
            nextStage.opId <= '0;
            nextStage.insn <= '0;
            nextStage.csrAddr <= '0;
            nextStage.srcRegAddr1 <= '0;
            nextStage.srcRegAddr2 <= '0;
            nextStage.dstRegAddr <= '0;
            nextStage.trapInfo <= '0;
        end
        else if (ctrl.idStall) begin
            nextStage.valid <= nextStage.valid;
            nextStage.pc <= nextStage.pc;
            nextStage.op <= nextStage.op;
            nextStage.opId <= nextStage.opId;
            nextStage.insn <= nextStage.insn;
            nextStage.csrAddr <= nextStage.csrAddr;
            nextStage.srcRegAddr1 <= nextStage.srcRegAddr1;
            nextStage.srcRegAddr2 <= nextStage.srcRegAddr2;
            nextStage.dstRegAddr <= nextStage.dstRegAddr;
            nextStage.trapInfo <= nextStage.trapInfo;
        end
        else if (!valid) begin
            nextStage.valid <= '0;
            nextStage.pc <= '0;
            nextStage.op <= '0;
            nextStage.opId <= '0;
            nextStage.insn <= '0;
            nextStage.csrAddr <= '0;
            nextStage.srcRegAddr1 <= '0;
            nextStage.srcRegAddr2 <= '0;
            nextStage.dstRegAddr <= '0;
            nextStage.trapInfo <= '0;
        end
        else begin
            nextStage.valid <= prevStage.valid;
            nextStage.pc <= prevStage.pc;
            nextStage.op <= op;
            nextStage.opId <= opId;
            nextStage.insn <= prevStage.insn;
            nextStage.csrAddr <= csrAddr;
            nextStage.srcRegAddr1 <= srcRegAddr1;
            nextStage.srcRegAddr2 <= srcRegAddr2;
            nextStage.dstRegAddr <= dstRegAddr;
            nextStage.trapInfo <= trapInfo;
        end

        if (rst) begin
            opId <= '0;
        end
        else if (ctrl.flush) begin
            opId <= ctrl.opCommitCount;
        end
        else begin
            opId <= nextOpId;
        end
    end
endmodule
