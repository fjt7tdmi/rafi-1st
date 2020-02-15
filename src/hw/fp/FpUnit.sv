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

parameter FP_CLASS_NEG_INF          = 32'h0001;
parameter FP_CLASS_NEG_NORMAL       = 32'h0002;
parameter FP_CLASS_NEG_SUBNORMAL    = 32'h0004;
parameter FP_CLASS_NEG_ZERO         = 32'h0008;
parameter FP_CLASS_POS_ZERO         = 32'h0010;
parameter FP_CLASS_POS_SUBNORMAL    = 32'h0020;
parameter FP_CLASS_POS_NORMAL       = 32'h0040;
parameter FP_CLASS_POS_INF          = 32'h0080;
parameter FP_CLASS_SIGNALING_NAN    = 32'h0100;
parameter FP_CLASS_QUIET_NAN        = 32'h0200;

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
    input FpUnitType unit,
    input FpUnitCommand command,
    input logic [2:0] roundingMode,
    input word_t intSrc1,
    input word_t intSrc2,
    input logic [FP_WIDTH-1:0] fpSrc1,
    input logic [FP_WIDTH-1:0] fpSrc2,
    input logic [FP_WIDTH-1:0] fpSrc3,
    input logic clk,
    input logic rst
);
    logic [FP_WIDTH-1:0] fpResultClass;
    FpClassifier #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .FRACTION_WIDTH(FRACTION_WIDTH)
    ) m_FpClassifier(
        .intResult(fpResultClass),
        .fpSrc(fpSrc1),
        .clk(clk),
        .rst(rst));

    logic [FP_WIDTH-1:0] fpResultSign;
    FpSignUnit #(
        .WIDTH(FP_WIDTH)
    ) m_FpSignUnit (
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
    ) m_FpComparator (
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
    ) m_FpMulAdd (
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
    ) m_FpDivUnit (
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
    ) m_FpSqrtUnit (
        .fpResult(fpResultSqrt),
        .flags(flagsSqrt),
        .done(doneSqrt),
        .enable(enable && unit == FpUnitType_Sqrt),
        .flush(flush),
        .roundingMode(roundingMode),
        .fpSrc(fpSrc1),
        .clk(clk),
        .rst(rst));

    always_comb begin
        unique case (unit)
        FpUnitType_Move: begin
            intResult = fpSrc1; // FMV.X.W
            fpResult = intSrc1; // FMV.W.X
            done = '1;
            writeFlags = '0;
            writeFlagsValue = '0;
        end
        FpUnitType_Classifier: begin
            intResult = fpResultClass;
            fpResult = '0;
            done = '1;
            writeFlags = '0;
            writeFlagsValue = '0;
        end
        FpUnitType_Sign: begin
            intResult = '0;
            fpResult = fpResultSign;
            done = '1;
            writeFlags = '0;
            writeFlagsValue = '0;
        end
        FpUnitType_Comparator: begin
            intResult = intResultCmp;
            fpResult = fpResultCmp;
            done = '1;
            writeFlags = '1;
            writeFlagsValue = flagsCmp;
        end
        FpUnitType_MulAdd: begin
            intResult = '0;
            fpResult = fpResultMulAdd;
            done = '1;
            writeFlags = '1;
            writeFlagsValue = flagsMulAdd;
        end
        FpUnitType_Div: begin
            intResult = '0;
            fpResult = fpResultDiv;
            done = '1;
            writeFlags = '1;
            writeFlagsValue = flagsDiv;
        end
        FpUnitType_Sqrt: begin
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
