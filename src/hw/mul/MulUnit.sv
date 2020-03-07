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
    input logic src1_signed,
    input logic src2_signed,
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
    logic [63:0] reg_result;
    State reg_state;

    // Wires
    logic [63:0] next_result;
    State next_state;

    logic sign1;
    logic sign2;

    logic [32:0] extended_src1;
    logic [32:0] extended_src2;

    always_comb begin
        done = (reg_state == State_Done);
        result = high ? reg_result[63:32] : reg_result[31:0];

        sign1 = src1_signed && src1[31];
        sign2 = src2_signed && src2[31];

        extended_src1 = {sign1, src1};
        extended_src2 = {sign2, src2};

        next_result = $signed(extended_src1) * $signed(extended_src2);
        next_state = (reg_state == State_Init && enable)
            ? State_Done
            : State_Init;
    end

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            reg_result <= '0;
            reg_state <= State_Init;
        end
        else if (stall) begin
            reg_result <= reg_result;
            reg_state <= reg_state;
        end
        else begin
            reg_result <= next_result;
            reg_state <= next_state;
        end
    end
endmodule
