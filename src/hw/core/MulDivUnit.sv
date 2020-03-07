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
    logic mulDone;
    logic [31:0] mulResult;
    logic mulHigh;
    logic mulSrcSigned1;
    logic mulSrcSigned2;

    MulUnit m_MulUnit(
        .done(mulDone),
        .result(mulResult),
        .high(mulHigh),
        .srcSigned1(mulSrcSigned1),
        .srcSigned2(mulSrcSigned2),
        .src1,
        .src2,
        .enable,
        .stall,
        .flush,
        .clk,
        .rst
    );

    // DivUnit
    logic divDone;
    logic [31:0] quotient;
    logic [31:0] remnant;
    logic divSigned;

    DivUnit #(
        .N(32)
    ) m_DivUnit (
        .done(divDone),
        .quotient,
        .remnant,
        .is_signed(divSigned),
        .dividend(src1),
        .divisor(src2),
        .enable,
        .stall,
        .flush,
        .clk,
        .rst
    );

    always_comb begin
        mulHigh = (command == MulDivCommand_Mulh || command == MulDivCommand_Mulhsu || command == MulDivCommand_Mulhu);
        mulSrcSigned1 = (command == MulDivCommand_Mulh || command == MulDivCommand_Mulhsu);
        mulSrcSigned2 = (command == MulDivCommand_Mulh);
        divSigned = (command == MulDivCommand_Div || command == MulDivCommand_Rem);
    end

    always_comb begin
        if (command == MulDivCommand_Mul || command == MulDivCommand_Mulh || command == MulDivCommand_Mulhsu || command == MulDivCommand_Mulhu) begin
            done = mulDone;
            result = mulResult;
        end
        else if (command == MulDivCommand_Div || command == MulDivCommand_Divu) begin
            done = divDone;
            result = quotient;
        end
        else begin
            done = divDone;
            result = remnant;
        end
    end
endmodule
