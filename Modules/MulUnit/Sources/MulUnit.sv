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

module MulUnit(
    output logic done,
    output logic [31:0] result,
    input logic high,
    input logic srcSigned1,
    input logic srcSigned2,
    input logic [31:0] src1,
    input logic [31:0] src2,
    input logic enable,
    input logic stall,
    input logic flush,
    input logic clk,
    input logic rst
);
    typedef enum logic
    {
        State_Init = 1'h0,
        State_Done = 1'h1
    } State;

    // Regs
    logic [63:0] reg_Result;
    State reg_State;

    // Wires
    logic [63:0] next_Result;
    State next_State;

    logic sign1;
    logic sign2;

    logic [32:0] extendedSrc1;
    logic [32:0] extendedSrc2;

    always_comb begin
        done = (reg_State == State_Done);
        result = high ? reg_Result[63:32] : reg_Result[31:0];

        sign1 = srcSigned1 && src1[31];
        sign2 = srcSigned2 && src2[31];

        extendedSrc1 = {sign1, src1};
        extendedSrc2 = {sign2, src2};

        next_Result = $signed(extendedSrc1) * $signed(extendedSrc2);
        next_State = (reg_State == State_Init && enable)
            ? State_Done
            : State_Init;
    end

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            reg_Result <= '0;
            reg_State <= State_Init;
        end
        else if (stall) begin
            reg_Result <= reg_Result;
            reg_State <= reg_State;
        end
        else begin
            reg_Result <= next_Result;
            reg_State <= next_State;
        end
    end
endmodule
