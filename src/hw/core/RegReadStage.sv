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
    IntRegFileIF.RegReadStage intRegFile,
    FpRegFileIF.RegReadStage fpRegFile,
    input   logic clk,
    input   logic rst
);

    always_comb begin
        intRegFile.readAddr1 = prevStage.srcRegAddr1;
        intRegFile.readAddr2 = prevStage.srcRegAddr2;
        fpRegFile.readAddr1 = prevStage.srcRegAddr1;
        fpRegFile.readAddr2 = prevStage.srcRegAddr2;
    end

    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            nextStage.valid <= '0;
            nextStage.op <= '0;
            nextStage.pc <= '0;
            nextStage.insn <= '0;
            nextStage.csrAddr <= '0;
            nextStage.srcRegAddr1 <= '0;
            nextStage.srcRegAddr2 <= '0;
            nextStage.srcIntRegValue1 <= '0;
            nextStage.srcIntRegValue2 <= '0;
            nextStage.srcFpRegValue1 <= '0;
            nextStage.srcFpRegValue2 <= '0;
            nextStage.dstRegAddr <= '0;
            nextStage.trapInfo <= '0;
        end
        else if (ctrl.rrStall) begin
            nextStage.valid <= nextStage.valid;
            nextStage.op <= nextStage.op;
            nextStage.pc <= nextStage.pc;
            nextStage.insn <= nextStage.insn;
            nextStage.csrAddr <= nextStage.csrAddr;
            nextStage.srcRegAddr1 <= nextStage.srcRegAddr1;
            nextStage.srcRegAddr2 <= nextStage.srcRegAddr2;
            nextStage.srcIntRegValue1 <= nextStage.srcIntRegValue1;
            nextStage.srcIntRegValue2 <= nextStage.srcIntRegValue2;
            nextStage.srcFpRegValue1 <= nextStage.srcFpRegValue1;
            nextStage.srcFpRegValue2 <= nextStage.srcFpRegValue2;
            nextStage.dstRegAddr <= nextStage.dstRegAddr;
            nextStage.trapInfo <= nextStage.trapInfo;
        end
        else begin
            nextStage.valid <= prevStage.valid;
            nextStage.op <= prevStage.op;
            nextStage.pc <= prevStage.pc;
            nextStage.insn <= prevStage.insn;
            nextStage.csrAddr <= prevStage.csrAddr;
            nextStage.srcRegAddr1 <= prevStage.srcRegAddr1;
            nextStage.srcRegAddr2 <= prevStage.srcRegAddr2;
            nextStage.dstRegAddr <= prevStage.dstRegAddr;
            nextStage.srcIntRegValue1 <= intRegFile.readValue1;
            nextStage.srcIntRegValue2 <= intRegFile.readValue2;
            nextStage.srcFpRegValue1 <= fpRegFile.readValue1;
            nextStage.srcFpRegValue2 <= fpRegFile.readValue2;
            nextStage.trapInfo <= prevStage.trapInfo;
        end
    end

endmodule
