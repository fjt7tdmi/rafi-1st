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
import LoadStoreUnitTypes::*;

module MemoryAccessStage(
    ExecuteStageIF.NextStage prevStage,
    MemoryAccessStageIF.ThisStage nextStage,
    input logic clk,
    input logic rst
);
    always_ff @(posedge clk) begin
        if (rst) begin
            nextStage.valid <= '0;
            nextStage.op <= '0;
            nextStage.pc <= '0;
            nextStage.csrAddr <= '0;
            nextStage.dstCsrValue <= '0;
            nextStage.dstRegAddr <= '0;
            nextStage.dstIntRegValue <= '0;
            nextStage.dstFpRegValue <= '0;
            nextStage.branchTaken <= '0;
            nextStage.branchTarget <= '0;
            nextStage.trapInfo <= '0;
            nextStage.trapReturn <= '0;
            nextStage.debugInsn <= '0;
        end
        else begin
            nextStage.valid <= prevStage.valid;
            nextStage.op <= prevStage.op;
            nextStage.pc <= prevStage.pc;
            nextStage.csrAddr <= prevStage.csrAddr;
            nextStage.dstCsrValue <= prevStage.dstCsrValue;
            nextStage.dstRegAddr <= prevStage.dstRegAddr;
            nextStage.dstIntRegValue <= prevStage.dstIntRegValue;
            nextStage.dstFpRegValue <= prevStage.dstFpRegValue;
            nextStage.branchTaken <= prevStage.branchTaken;
            nextStage.branchTarget <= prevStage.branchTarget;
            nextStage.trapInfo <= prevStage.trapInfo;
            nextStage.trapReturn <= prevStage.trapReturn;
            nextStage.debugInsn <= prevStage.debugInsn;
        end
    end
endmodule
