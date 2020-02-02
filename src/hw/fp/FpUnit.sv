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

module Fp32Unit(
    output word_t intResult,
    output uint32_t fpResult,
    input FpUnitCommand command,
    input word_t intSrc1,
    input word_t intSrc2,
    input uint32_t fpSrc1,
    input uint32_t fpSrc2,
    input logic clk,
    input logic rst
);
    always_comb begin
        unique case (command)
        FpUnitCommand_Move: begin
            intResult = fpSrc1; // FMV.X.W
            fpResult = intSrc1; // FMV.W.X
        end
        FpUnitCommand_Sgnj: begin
            intResult = '0;
            fpResult = {fpSrc2[31], fpSrc1[30:0]};
        end
        FpUnitCommand_Sgnjn: begin
            intResult = '0;
            fpResult = {~fpSrc2[31], fpSrc1[30:0]};
        end
        FpUnitCommand_Sgnjx: begin
            intResult = '0;
            fpResult = {fpSrc1[31] ^ fpSrc2[31], fpSrc1[30:0]};
        end
        default: begin
            intResult = '0;
            fpResult = '0;
        end
        endcase
    end
endmodule
