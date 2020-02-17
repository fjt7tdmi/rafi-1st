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
    FetchStageIF.ThisStage nextStage,
    FetchUnitIF.FetchStage fetchUnit,
    PipelineControllerIF.FetchStage ctrl,
    CsrIF.FetchStage csr,
    input   logic clk,
    input   logic rst
);
    localparam InsnCountInLine = ICacheLineWidth / INSN_WIDTH;
    localparam IndexWidth = $clog2(InsnCountInLine);

    // Wires
    logic [IndexWidth-1:0] index;
    insn_t [InsnCountInLine-1:0] insns;
    insn_t insn;

    always_comb begin
        index = fetchUnit.pc[IndexWidth+$clog2(INSN_SIZE)-1:$clog2(INSN_SIZE)];
        insns = fetchUnit.iCacheLine;
        insn = insns[index];
    end

    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            nextStage.valid <= '0;
            nextStage.pc <= '0;
            nextStage.insn <= '0;
            nextStage.trapInfo <= '0;
        end
        else if (ctrl.ifStall) begin
            nextStage.valid <= nextStage.valid;
            nextStage.pc <= nextStage.pc;
            nextStage.insn <= nextStage.insn;
            nextStage.trapInfo <= nextStage.trapInfo;
        end
        else if (fetchUnit.fault) begin
            nextStage.valid <= fetchUnit.valid;
            nextStage.pc <= fetchUnit.pc;
            nextStage.insn <= '0;
            nextStage.trapInfo.valid <= '1;
            nextStage.trapInfo.cause <= ExceptionCode_InsnPageFault;
            nextStage.trapInfo.value <= fetchUnit.pc;
        end
        else begin
            nextStage.valid <= fetchUnit.valid;
            nextStage.pc <= fetchUnit.pc;
            nextStage.insn <= insn;
            nextStage.trapInfo <= '0;
        end
    end
endmodule