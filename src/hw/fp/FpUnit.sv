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

typedef struct packed {
    logic sign;
    logic [7:0] exponent;
    logic [22:0] fraction;
} fp32_t;

module Fp32Unit(
    output word_t intResult,
    output uint32_t fpResult,
    input FpUnitType unit,
    input FpUnitCommand command,
    input word_t intSrc1,
    input word_t intSrc2,
    input uint32_t fpSrc1,
    input uint32_t fpSrc2,
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
    FpComparator m_FpComparator (
        .intResult(intResultCmp),
        .fpResult(fpResultCmp),
        .command(command.cmp),
        .fpSrc1(fpSrc1),
        .fpSrc2(fpSrc2),
        .clk(clk),
        .rst(rst));

    always_comb begin
        unique case (unit)
        FpUnitType_Move: begin
            intResult = fpSrc1; // FMV.X.W
            fpResult = intSrc1; // FMV.W.X
        end
        FpUnitType_Classifier: begin
            intResult = get_class(fpSrc1);
            fpResult = '0;
        end
        FpUnitType_Sign: begin
            intResult = '0;
            fpResult = fpResultSign;
        end
        FpUnitType_Comparator: begin
            intResult = intResultCmp;
            fpResult = fpResultCmp;
        end
        default: begin
            intResult = '0;
            fpResult = '0;
        end
        endcase
    end
endmodule
