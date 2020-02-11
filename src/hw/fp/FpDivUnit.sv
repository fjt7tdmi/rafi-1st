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

module FpDivUnit #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output logic [WIDTH-1:0] fpResult,
    output fflags_t flags,
    input logic [2:0] roundingMode,
    input logic [WIDTH-1:0] fpSrc1,
    input logic [WIDTH-1:0] fpSrc2,
    input logic clk,
    input logic rst
);
    typedef enum logic [1:0]
    {
        ResultType_Quotient = 2'h0,
        ResultType_Zero     = 2'h1,
        ResultType_Inf      = 2'h2,
        ResultType_Nan      = 2'h3
    } ResultType;

    logic sign1;
    logic sign2;
    logic [EXPONENT_WIDTH-1:0] exponent1;
    logic [EXPONENT_WIDTH-1:0] exponent2;
    logic [FRACTION_WIDTH-1:0] fraction1;
    logic [FRACTION_WIDTH-1:0] fraction2;
    always_comb begin
        sign1 = fpSrc1[WIDTH-1];
        sign2 = fpSrc2[WIDTH-1];
        exponent1 = fpSrc1[WIDTH-2:FRACTION_WIDTH];
        exponent2 = fpSrc2[WIDTH-2:FRACTION_WIDTH];
        fraction1 = fpSrc1[FRACTION_WIDTH-1:0];
        fraction2 = fpSrc2[FRACTION_WIDTH-1:0];
    end

    // TODO: Support subnormalized numbers
    logic is_zero1;
    logic is_zero2;
    logic is_inf1;
    logic is_inf2;
    logic is_nan1;
    logic is_nan2;
    always_comb begin
        is_zero1 = exponent1 == '0;
        is_zero2 = exponent2 == '0;
        is_nan1 = exponent1 == '1 && fraction1 != '0;
        is_nan2 = exponent2 == '1 && fraction2 != '0;
        is_inf1 = exponent1 == '1 && fraction1 == '0;
        is_inf2 = exponent2 == '1 && fraction2 == '0;
    end

    logic signed [EXPONENT_WIDTH+1:0] exponent1_extended;
    logic signed [EXPONENT_WIDTH+1:0] exponent2_extended;
    logic [FRACTION_WIDTH*2+3:0] fraction1_extended;
    logic [FRACTION_WIDTH*2+3:0] fraction2_extended;
    always_comb begin
        exponent1_extended = {2'h0, exponent1};
        exponent2_extended = {2'h0, exponent2};
        fraction1_extended[FRACTION_WIDTH*2+3] = 1'b0;
        fraction1_extended[FRACTION_WIDTH*2+2] = 1'b1;
        fraction1_extended[FRACTION_WIDTH*2+1:FRACTION_WIDTH+2] = fraction1;
        fraction1_extended[FRACTION_WIDTH+1:0] = '0;
        fraction2_extended[FRACTION_WIDTH*2+3:FRACTION_WIDTH+1] = '0;
        fraction2_extended[FRACTION_WIDTH] = 1'b1;
        fraction2_extended[FRACTION_WIDTH-1:0] = fraction2;
    end

    // Calculate subtract of exponents and quotient of fractions.
    logic sign;
    logic signed [EXPONENT_WIDTH+1:0] exponent_sum;
    logic [FRACTION_WIDTH*2+3:0] fraction_quotient;
    logic [FRACTION_WIDTH*2+3:0] fraction_remnant;
    always_comb begin
        sign = sign1 ^ sign2;
        exponent_sum = exponent1_extended - exponent2_extended + 127;

        // TODO: Optmize
        fraction_quotient = fraction1_extended / fraction2_extended;
        fraction_remnant = fraction1_extended % fraction2_extended;
    end

    // Normalize
    logic signed [EXPONENT_WIDTH+1:0] exponent_normalized;
    logic [FRACTION_WIDTH+3:0] fraction_normalized;
    always_comb begin
        if (~fraction_quotient[FRACTION_WIDTH+2]) begin
            exponent_normalized = exponent_sum - 1;
            fraction_normalized = {fraction_quotient[FRACTION_WIDTH+1:0], fraction_remnant == '0 ? 2'b00 : 2'b11};
        end
        else begin
            exponent_normalized = exponent_sum;
            fraction_normalized = {fraction_quotient[FRACTION_WIDTH+2:0], fraction_remnant == '0 ? 1'b0 : 1'b1};
        end
    end

    // Rounding
    logic inexact;
    logic signed [EXPONENT_WIDTH+1:0] exponent_rounded;
    logic [FRACTION_WIDTH-1:0] fraction_rounded;
    FpRounder #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH + 2),
        .FRACTION_WIDTH(FRACTION_WIDTH)
    ) rounder (
        .inexact(inexact),
        .roundedExponent(exponent_rounded),
        .roundedFraction(fraction_rounded),
        .roundingMode(roundingMode),
        .sign(sign),
        .exponent(exponent_normalized),
        .fraction(fraction_normalized[FRACTION_WIDTH+2:3]),
        .g(fraction_normalized[2]),
        .r(fraction_normalized[1]),
        .s(fraction_normalized[0]));

    // Exception handling
    logic overflow;
    logic underflow;
    always_comb begin
        overflow = exponent_rounded >= 255;
        underflow = exponent_rounded <= 0;
    end

    // Result
    ResultType result_type;
    always_comb begin
        if (is_nan1 || is_nan2 || (is_zero1 && is_zero2) || (is_inf1 && is_inf2)) begin
            result_type = ResultType_Nan;
        end
        else if (is_inf1 || is_zero2) begin
            result_type = ResultType_Inf;
        end
        else if (is_zero1 || is_inf2) begin
            result_type = ResultType_Zero;
        end
        else begin
            result_type = ResultType_Quotient;
        end
    end

    always_comb begin
        unique case (result_type)
        ResultType_Quotient: begin
            fpResult[WIDTH-1] = sign;
            fpResult[WIDTH-2:FRACTION_WIDTH] = exponent_rounded[EXPONENT_WIDTH-1:0];
            fpResult[FRACTION_WIDTH-1:0] = fraction_rounded;
        end
        ResultType_Zero: begin
            fpResult[WIDTH-1] = sign;
            fpResult[WIDTH-2:0] = '0;
        end
        ResultType_Inf: begin
            fpResult[WIDTH-1] = sign;
            fpResult[WIDTH-2:FRACTION_WIDTH] = '1;
            fpResult[FRACTION_WIDTH-1:0] = '0;
        end
        ResultType_Nan: begin
            // Canonical Quiet NaN
            fpResult[WIDTH-1] = '0;
            fpResult[WIDTH-2:FRACTION_WIDTH-1] = '1;
            fpResult[FRACTION_WIDTH-2:0] = '0;
        end
        default: begin
            fpResult = '0;
        end
        endcase

        flags.NV = result_type == ResultType_Nan;
        flags.DZ = 0;
        flags.OF = overflow;
        flags.UF = underflow;
        flags.NX = inexact;
    end
endmodule
