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

module RegReadStage(
    DecodeStageIF.NextStage prevStage,
    RegReadStageIF.ThisStage nextStage,
    PipelineControllerIF.RegReadStage ctrl,
    ControlStatusRegisterIF.RegReadStage csr,
    IntRegFileIF.RegReadStage intRegFile,
    input   logic clk,
    input   logic rst
);

    always_comb begin
        intRegFile.readAddr1 = prevStage.srcRegAddr1;
        intRegFile.readAddr2 = prevStage.srcRegAddr2;
        csr.readAddr = prevStage.csrAddr;
        csr.readEnable = prevStage.op.csrReadEnable;
        csr.readOpId = prevStage.opId;
    end

    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            nextStage.valid <= '0;
            nextStage.op <= '0;
            nextStage.pc <= '0;
            nextStage.insn <= '0;
            nextStage.csrAddr <= '0;
            nextStage.srcCsrValue <= '0;
            nextStage.srcRegAddr1 <= '0;
            nextStage.srcRegAddr2 <= '0;
            nextStage.srcRegValue1 <= '0;
            nextStage.srcRegValue2 <= '0;
            nextStage.dstRegAddr <= '0;
            nextStage.trapInfo <= '0;
        end
        else if (ctrl.rrStall) begin
            nextStage.valid <= nextStage.valid;
            nextStage.op <= nextStage.op;
            nextStage.pc <= nextStage.pc;
            nextStage.insn <= nextStage.insn;
            nextStage.csrAddr <= nextStage.csrAddr;
            nextStage.srcCsrValue <= nextStage.srcCsrValue;
            nextStage.srcRegAddr1 <= nextStage.srcRegAddr1;
            nextStage.srcRegAddr2 <= nextStage.srcRegAddr2;
            nextStage.srcRegValue1 <= nextStage.srcRegValue1;
            nextStage.srcRegValue2 <= nextStage.srcRegValue2;
            nextStage.dstRegAddr <= nextStage.dstRegAddr;
            nextStage.trapInfo <= nextStage.trapInfo;
        end
        else begin
            nextStage.valid <= prevStage.valid;
            nextStage.op <= prevStage.op;
            nextStage.pc <= prevStage.pc;
            nextStage.insn <= prevStage.insn;
            nextStage.csrAddr <= prevStage.csrAddr;
            nextStage.srcCsrValue <= csr.readValue;
            nextStage.srcRegAddr1 <= prevStage.srcRegAddr1;
            nextStage.srcRegAddr2 <= prevStage.srcRegAddr2;
            nextStage.dstRegAddr <= prevStage.dstRegAddr;
            nextStage.srcRegValue1 <= intRegFile.readValue1;
            nextStage.srcRegValue2 <= intRegFile.readValue2;

            if (!prevStage.trapInfo.valid && csr.readIllegal) begin
                nextStage.trapInfo.valid <= 1;
                nextStage.trapInfo.cause <= ExceptionCode_IllegalInsn;
                nextStage.trapInfo.value <= prevStage.insn;
            end
            else begin
                nextStage.trapInfo <= prevStage.trapInfo;
            end
        end
    end

endmodule
