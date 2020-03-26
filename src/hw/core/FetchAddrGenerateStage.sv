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

module FetchAddrGenerateStage(
    FetchAddrGenerateStageIF.ThisStage nextStage,
    FetchPipeControllerIF.FetchAddrGenerateStage ctrl,
    input   logic clk,
    input   logic rst
);
    vaddr_t reg_pc;

    vaddr_t next_pc;

    // next_pc
    always_comb begin
        if (ctrl.flush) begin
            next_pc = ctrl.flushTargetPc;
        end
        else begin
            next_pc = reg_pc + (reg_pc[1] ? 2 : 4);
        end
    end

    // PC
    always_ff @(posedge clk) begin
        if (rst) begin
            reg_pc <= INITIAL_PC;
        end
        else begin
            reg_pc <= next_pc;
        end
    end

    // FetchAddrTranslateStageIF
    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            nextStage.valid <= 0;
            nextStage.pc_vaddr <= '0;
        end
        else begin
            nextStage.valid <= 1;
            nextStage.pc_vaddr <= reg_pc;
        end
    end
endmodule
