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

module BranchUnit(
    output logic taken,
    output addr_t target,
    input logic enable,
    input BranchType condition,
    input logic indirect,
    input addr_t pc,
    input word_t srcRegValue1,
    input word_t srcRegValue2,
    input word_t imm
);
    word_t result;

    always_comb begin
        if (enable) begin
            unique case (condition)
            BranchType_Equal:                   taken = srcRegValue1 == srcRegValue2;
            BranchType_NotEqual:                taken = srcRegValue1 != srcRegValue2;
            BranchType_LessThan:                taken = $signed(srcRegValue1) < $signed(srcRegValue2);
            BranchType_GreaterEqual:            taken = $signed(srcRegValue1) >= $signed(srcRegValue2);
            BranchType_UnsignedLessThan:        taken = $unsigned(srcRegValue1) < $unsigned(srcRegValue2);
            BranchType_UnsignedGreaterEqual:    taken = $unsigned(srcRegValue1) >= $unsigned(srcRegValue2);
            BranchType_Always:                  taken = 1;
            default:                            taken = 0;
            endcase
        end
        else begin
            taken = 0;
        end

        result = (indirect ? srcRegValue1 : pc) + imm;
        target[31:1] = result[31:1];
        target[0] = 0;
    end
endmodule
