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
import RafiTypes::*;

module MulDivUnit(
    output logic done,
    output logic [31:0] result,
    input MulDivCommand command,
    input logic [31:0] src1,
    input logic [31:0] src2,
    input logic enable,
    input logic stall,
    input logic flush,
    input logic clk,
    input logic rst
);
    // MulUnit
    logic mul_done;
    logic [31:0] mul_result;
    logic mul_high;
    logic mul_src1_signed;
    logic mul_src2_signed;

    MulUnit mulUnit(
        .done(mul_done),
        .result(mul_result),
        .high(mul_high),
        .src1_signed(mul_src1_signed),
        .src2_signed(mul_src2_signed),
        .src1,
        .src2,
        .enable,
        .stall,
        .flush,
        .clk,
        .rst
    );

    // DivUnit
    logic div_done;
    logic [31:0] quotient;
    logic [31:0] remnant;
    logic div_signed;

    DivUnit #(
        .N(32)
    ) divUnit (
        .done(div_done),
        .quotient,
        .remnant,
        .is_signed(div_signed),
        .dividend(src1),
        .divisor(src2),
        .enable,
        .stall,
        .flush,
        .clk,
        .rst
    );

    always_comb begin
        mul_high = (command == MulDivCommand_Mulh || command == MulDivCommand_Mulhsu || command == MulDivCommand_Mulhu);
        mul_src1_signed = (command == MulDivCommand_Mulh || command == MulDivCommand_Mulhsu);
        mul_src2_signed = (command == MulDivCommand_Mulh);
        div_signed = (command == MulDivCommand_Div || command == MulDivCommand_Rem);
    end

    always_comb begin
        if (command == MulDivCommand_Mul || command == MulDivCommand_Mulh || command == MulDivCommand_Mulhsu || command == MulDivCommand_Mulhu) begin
            done = mul_done;
            result = mul_result;
        end
        else if (command == MulDivCommand_Div || command == MulDivCommand_Divu) begin
            done = div_done;
            result = quotient;
        end
        else begin
            done = div_done;
            result = remnant;
        end
    end
endmodule
