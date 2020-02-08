
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

module FpSignUnit #(
    parameter WIDTH = 32
)(
    output logic unsigned [WIDTH-1:0] fpResult,
    input FpSignUnitCommand command,
    input logic unsigned [WIDTH-1:0] fpSrc1,
    input logic unsigned [WIDTH-1:0] fpSrc2,
    input logic clk,
    input logic rst
);
    always_comb begin
        unique case (command)
        FpSignUnitCommand_Sgnj:     fpResult = {fpSrc2[31], fpSrc1[30:0]};
        FpSignUnitCommand_Sgnjn:    fpResult = {~fpSrc2[31], fpSrc1[30:0]};
        FpSignUnitCommand_Sgnjx:    fpResult = {fpSrc1[31] ^ fpSrc2[31], fpSrc1[30:0]};
        default:                    fpResult = '0;
        endcase
    end
endmodule
