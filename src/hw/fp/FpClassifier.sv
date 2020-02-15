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

module FpClassifier #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output word_t intResult,
    input logic [WIDTH-1:0] fpSrc,
    input logic clk,
    input logic rst
);
    parameter EXPONENT_MAX = (1 << EXPONENT_WIDTH) - 2;

    logic sign;
    logic [EXPONENT_WIDTH-1:0] exponent;
    logic [FRACTION_WIDTH-1:0] fraction;
    always_comb begin
        sign = fpSrc[WIDTH-1];
        exponent = fpSrc[WIDTH-2:FRACTION_WIDTH];
        fraction = fpSrc[FRACTION_WIDTH-1:0];
    end

    always_comb begin
        if (sign == 1 && exponent == '1 && fraction == '0) begin
            intResult =  FP_CLASS_NEG_INF;
        end
        else if (sign == 1 && 1 <= exponent && exponent <= EXPONENT_MAX) begin
            intResult =  FP_CLASS_NEG_NORMAL;
        end
        else if (sign == 1 && exponent == '0 && fraction != '0) begin
            intResult =  FP_CLASS_NEG_SUBNORMAL;
        end
        else if (sign == 1 && exponent == '0 && fraction == '0) begin
            intResult =  FP_CLASS_NEG_ZERO;
        end
        else if (sign == 0 && exponent == '0 && fraction == '0) begin
            intResult =  FP_CLASS_POS_ZERO;
        end
        else if (sign == 0 && exponent == '0 && fraction != '0) begin
            intResult =  FP_CLASS_POS_SUBNORMAL;
        end
        else if (sign == 0 && 1 <= exponent && exponent <= EXPONENT_MAX) begin
            intResult =  FP_CLASS_POS_NORMAL;
        end
        else if (sign == 0 && exponent == '1 && fraction == '0) begin        
            intResult =  FP_CLASS_POS_INF;
        end
        else if (exponent == '1 && fraction != '0 && fraction[FRACTION_WIDTH-1] == 0) begin
            intResult =  FP_CLASS_SIGNALING_NAN;
        end
        else if (exponent == '1 && fraction != '0 && fraction[FRACTION_WIDTH-1] == 1) begin
            intResult =  FP_CLASS_QUIET_NAN;
        end
        else begin
            intResult =  '0;
        end
    end
endmodule
