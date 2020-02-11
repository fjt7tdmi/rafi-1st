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

module Fp32Unit(
    output word_t intResult,
    output uint32_t fpResult,
    output logic writeFlags,
    output fflags_t writeFlagsValue,
    input FpUnitType unit,
    input FpUnitCommand command,
    input logic [2:0] roundingMode,
    input word_t intSrc1,
    input word_t intSrc2,
    input uint32_t fpSrc1,
    input uint32_t fpSrc2,
    input uint32_t fpSrc3,
    input logic clk,
    input logic rst
);

    function automatic uint32_t get_class(uint32_t value);
        fp32_t x = value;

        if (x.sign == 1'h1 && x.exponent == 8'hff && x.fraction == 23'h0)               return FP_CLASS_NEG_INF;
        else if (x.sign == 1'h1 && 8'h1 <= x.exponent && x.exponent < 8'hff)            return FP_CLASS_NEG_NORMAL;
        else if (x.sign == 1'h1 && x.exponent == 8'h0 && x.fraction != 23'h0)           return FP_CLASS_NEG_SUBNORMAL;
        else if (x.sign == 1'h1 && x.exponent == 8'h0 && x.fraction == 23'h0)           return FP_CLASS_NEG_ZERO;
        else if (x.sign == 1'h0 && x.exponent == 8'h0 && x.fraction == 23'h0)           return FP_CLASS_POS_ZERO;
        else if (x.sign == 1'h0 && x.exponent == 8'h0 && x.fraction != 23'h0)           return FP_CLASS_POS_SUBNORMAL;
        else if (x.sign == 1'h0 && 8'h1 <= x.exponent && x.exponent < 8'hff)            return FP_CLASS_POS_NORMAL;
        else if (x.sign == 1'h0 && x.exponent == 8'hff && x.fraction == 23'h0)          return FP_CLASS_POS_INF;
        else if (x.exponent == 8'hff && x.fraction != 23'h0 && x.fraction[22] == 1'h0)  return FP_CLASS_SIGNALING_NAN;
        else if (x.exponent == 8'hff && x.fraction != 23'h0 && x.fraction[22] == 1'h1)  return FP_CLASS_QUIET_NAN;
        else                                                                            return '0;
    endfunction

    uint32_t fpResultSign;
    FpSignUnit m_FpSignUnit (
        .fpResult(fpResultSign),
        .command(command.sign),
        .fpSrc1(fpSrc1),
        .fpSrc2(fpSrc2),
        .clk(clk),
        .rst(rst));

    uint32_t intResultCmp;
    uint32_t fpResultCmp;
    fflags_t flagsCmp;
    FpComparator m_FpComparator (
        .intResult(intResultCmp),
        .fpResult(fpResultCmp),
        .flags(flagsCmp),
        .command(command.cmp),
        .fpSrc1(fpSrc1),
        .fpSrc2(fpSrc2),
        .clk(clk),
        .rst(rst));

    uint32_t intResultCvt;
    uint32_t fpResultCvt;
    fflags_t flagsCvt;
    FpConverter m_FpConverter (
        .intResult(intResultCvt),
        .fp32Result(fpResultCvt),
        .flags(flagsCvt),
        .command(command.cvt),
        .roundingMode(roundingMode),
        .intSrc(intSrc1),
        .fp32Src(fpSrc1),
        .clk(clk),
        .rst(rst));

    uint32_t fpResultMulAdd;
    fflags_t flagsMulAdd;
    FpMulAdd m_FpMulAdd (
        .fpResult(fpResultMulAdd),
        .flags(flagsMulAdd),
        .command(command.mulAdd),
        .roundingMode(roundingMode),
        .fpSrc1(fpSrc1),
        .fpSrc2(fpSrc2),
        .fpSrc3(fpSrc3),
        .clk(clk),
        .rst(rst));

    uint32_t fpResultDiv;
    fflags_t flagsDiv;
    FpDivUnit m_FpDivUnit (
        .fpResult(fpResultDiv),
        .flags(flagsDiv),
        .roundingMode(roundingMode),
        .fpSrc1(fpSrc1),
        .fpSrc2(fpSrc2),
        .clk(clk),
        .rst(rst));

    uint32_t fpResultSqrt;
    fflags_t flagsSqrt;
    FpSqrtUnit m_FpSqrtUnit (
        .fpResult(fpResultSqrt),
        .flags(flagsSqrt),
        .roundingMode(roundingMode),
        .fpSrc(fpSrc1),
        .clk(clk),
        .rst(rst));

    always_comb begin
        unique case (unit)
        FpUnitType_Move: begin
            intResult = fpSrc1; // FMV.X.W
            fpResult = intSrc1; // FMV.W.X
            writeFlags = '0;
            writeFlagsValue = '0;
        end
        FpUnitType_Classifier: begin
            intResult = get_class(fpSrc1);
            fpResult = '0;
            writeFlags = '0;
            writeFlagsValue = '0;
        end
        FpUnitType_Sign: begin
            intResult = '0;
            fpResult = fpResultSign;
            writeFlags = '0;
            writeFlagsValue = '0;
        end
        FpUnitType_Comparator: begin
            intResult = intResultCmp;
            fpResult = fpResultCmp;
            writeFlags = '1;
            writeFlagsValue = flagsCmp;
        end
        FpUnitType_Converter: begin
            intResult = intResultCvt;
            fpResult = fpResultCvt;
            writeFlags = '1;
            writeFlagsValue = flagsCvt;
        end
        FpUnitType_MulAdd: begin
            intResult = '0;
            fpResult = fpResultMulAdd;
            writeFlags = '1;
            writeFlagsValue = flagsMulAdd;
        end
        FpUnitType_Div: begin
            intResult = '0;
            fpResult = fpResultDiv;
            writeFlags = '1;
            writeFlagsValue = flagsDiv;
        end
        FpUnitType_Sqrt: begin
            intResult = '0;
            fpResult = fpResultSqrt;
            writeFlags = '1;
            writeFlagsValue = flagsSqrt;
        end
        default: begin
            intResult = '0;
            fpResult = '0;
            writeFlags = '0;
            writeFlagsValue = '0;
        end
        endcase
    end
endmodule
