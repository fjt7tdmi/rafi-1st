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

module FpUnit #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter FP_WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output word_t intResult,
    output logic [FP_WIDTH-1:0] fpResult,
    output logic writeFlags,
    output fflags_t writeFlagsValue,
    output logic done,
    input logic enable,
    input logic flush,
    input FpSubUnitType unit,
    input FpCommandUnion command,
    input logic [2:0] roundingMode,
    input word_t intSrc1,
    input word_t intSrc2,
    input logic [FP_WIDTH-1:0] fpSrc1,
    input logic [FP_WIDTH-1:0] fpSrc2,
    input logic [FP_WIDTH-1:0] fpSrc3,
    input logic clk,
    input logic rst
);
    uint32_t fpResultClass;
    FpClassifier #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .FRACTION_WIDTH(FRACTION_WIDTH)
    ) fpClassifier(
        .intResult(fpResultClass),
        .fpSrc(fpSrc1),
        .clk(clk),
        .rst(rst));

    logic [FP_WIDTH-1:0] fpResultSign;
    FpSignUnit #(
        .WIDTH(FP_WIDTH)
    ) fpSignUnit (
        .fpResult(fpResultSign),
        .command(command.sign),
        .fpSrc1(fpSrc1),
        .fpSrc2(fpSrc2),
        .clk(clk),
        .rst(rst));

    uint32_t intResultCmp;
    logic [FP_WIDTH-1:0] fpResultCmp;
    fflags_t flagsCmp;
    FpComparator #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .FRACTION_WIDTH(FRACTION_WIDTH)
    ) fpComparator (
        .intResult(intResultCmp),
        .fpResult(fpResultCmp),
        .flags(flagsCmp),
        .command(command.cmp),
        .fpSrc1(fpSrc1),
        .fpSrc2(fpSrc2),
        .clk(clk),
        .rst(rst));

    logic [FP_WIDTH-1:0] fpResultMulAdd;
    fflags_t flagsMulAdd;
    FpMulAdd #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .FRACTION_WIDTH(FRACTION_WIDTH)
    ) fpMulAdd (
        .fpResult(fpResultMulAdd),
        .flags(flagsMulAdd),
        .command(command.mulAdd),
        .roundingMode(roundingMode),
        .fpSrc1(fpSrc1),
        .fpSrc2(fpSrc2),
        .fpSrc3(fpSrc3),
        .clk(clk),
        .rst(rst));

    logic [FP_WIDTH-1:0] fpResultDiv;
    fflags_t flagsDiv;
    FpDivUnit #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .FRACTION_WIDTH(FRACTION_WIDTH)
    ) fpDivUnit (
        .fpResult(fpResultDiv),
        .flags(flagsDiv),
        .roundingMode(roundingMode),
        .fpSrc1(fpSrc1),
        .fpSrc2(fpSrc2),
        .clk(clk),
        .rst(rst));

    logic [FP_WIDTH-1:0] fpResultSqrt;
    fflags_t flagsSqrt;
    logic doneSqrt;
    FpSqrtUnit #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .FRACTION_WIDTH(FRACTION_WIDTH)
    ) fpSqrtUnit (
        .fpResult(fpResultSqrt),
        .flags(flagsSqrt),
        .done(doneSqrt),
        .enable(enable && unit == FpSubUnitType_Sqrt),
        .flush(flush),
        .roundingMode(roundingMode),
        .fpSrc(fpSrc1),
        .clk(clk),
        .rst(rst));

    always_comb begin
        unique case (unit)
        FpSubUnitType_Move: begin
            intResult = fpSrc1[31:0]; // FMV.X.W
            fpResult = '0;
            fpResult[31:0] = intSrc1; // FMV.W.X
            done = '1;
            writeFlags = '0;
            writeFlagsValue = '0;
        end
        FpSubUnitType_Classifier: begin
            intResult = fpResultClass;
            fpResult = '0;
            done = '1;
            writeFlags = '0;
            writeFlagsValue = '0;
        end
        FpSubUnitType_Sign: begin
            intResult = '0;
            fpResult = fpResultSign;
            done = '1;
            writeFlags = '0;
            writeFlagsValue = '0;
        end
        FpSubUnitType_Comparator: begin
            intResult = intResultCmp;
            fpResult = fpResultCmp;
            done = '1;
            writeFlags = '1;
            writeFlagsValue = flagsCmp;
        end
        FpSubUnitType_MulAdd: begin
            intResult = '0;
            fpResult = fpResultMulAdd;
            done = '1;
            writeFlags = '1;
            writeFlagsValue = flagsMulAdd;
        end
        FpSubUnitType_Div: begin
            intResult = '0;
            fpResult = fpResultDiv;
            done = '1;
            writeFlags = '1;
            writeFlagsValue = flagsDiv;
        end
        FpSubUnitType_Sqrt: begin
            intResult = '0;
            fpResult = fpResultSqrt;
            done = doneSqrt;
            writeFlags = '1;
            writeFlagsValue = flagsSqrt;
        end
        default: begin
            intResult = '0;
            fpResult = '0;
            done = '0;
            writeFlags = '0;
            writeFlagsValue = '0;
        end
        endcase
    end
endmodule
