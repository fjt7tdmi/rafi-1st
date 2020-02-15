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

module FpSqrtUnit #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output logic [WIDTH-1:0] fpResult,
    output fflags_t flags,
    output logic done,
    input logic enable,
    input logic flush,
    input logic [2:0] roundingMode,
    input logic [WIDTH-1:0] fpSrc,
    input logic clk,
    input logic rst
);
    parameter EXPONENT_MAX = (1 << EXPONENT_WIDTH) - 2;

    typedef enum logic [1:0]
    {
        ResultType_Sqrt = 2'h0,
        ResultType_Zero = 2'h1,
        ResultType_Inf  = 2'h2,
        ResultType_Nan  = 2'h3
    } ResultType;

    logic sign;
    logic [EXPONENT_WIDTH-1:0] exponent;
    logic [FRACTION_WIDTH-1:0] fraction;
    always_comb begin
        sign = fpSrc[WIDTH-1];
        exponent = fpSrc[WIDTH-2:FRACTION_WIDTH];
        fraction = fpSrc[FRACTION_WIDTH-1:0];
    end

    // TODO: Support subnormalized numbers
    logic is_zero;
    logic is_inf;
    logic is_nan;
    always_comb begin
        is_zero = exponent == '0;
        is_nan = exponent == '1 && fraction != '0;
        is_inf = exponent == '1 && fraction == '0;
    end

    // Normalize
    logic [EXPONENT_WIDTH:0] exponent_unbiased;
    logic [EXPONENT_WIDTH:0] exponent_normalized;
    logic [FRACTION_WIDTH*2+5:0] fraction_normalized;
    always_comb begin
        exponent_unbiased = {1'b0, exponent} - EXPONENT_MAX / 2;
        exponent_normalized[EXPONENT_WIDTH:1] = exponent_unbiased[EXPONENT_WIDTH:1];
        exponent_normalized[0] = 1'b0;

        if (exponent_unbiased[0]) begin
            // Multiple by 2
            fraction_normalized[FRACTION_WIDTH*2+5] = 1'b1;
            fraction_normalized[FRACTION_WIDTH*2+4:FRACTION_WIDTH+5] = fraction;
            fraction_normalized[FRACTION_WIDTH  +4:0] = '0;
        end
        else begin
            fraction_normalized[FRACTION_WIDTH*2+5] = 1'b0;
            fraction_normalized[FRACTION_WIDTH*2+4] = 1'b1;
            fraction_normalized[FRACTION_WIDTH*2+3:FRACTION_WIDTH+4] = fraction;
            fraction_normalized[FRACTION_WIDTH  +3:0] = '0;
        end
    end

    // Sqrt
    logic [EXPONENT_WIDTH-1:0] exponent_sqrt;
    logic [FRACTION_WIDTH+2:0] fraction_sqrt;
    logic [FRACTION_WIDTH+2:0] remnant;

    SqrtUnit #(
        .WIDTH(FRACTION_WIDTH+3)
    ) m_SqrtUnit (
        .sqrt(fraction_sqrt),
        .remnant(remnant),
        .done(done),
        .enable(enable),
        .flush(flush),
        .src(fraction_normalized),
        .clk(clk),
        .rst(rst));

    always_comb begin
        exponent_sqrt = exponent_normalized[EXPONENT_WIDTH:1] + EXPONENT_MAX / 2;
    end

    // Rounding
    logic inexact;
    logic [EXPONENT_WIDTH-1:0] exponent_rounded;
    logic [FRACTION_WIDTH-1:0] fraction_rounded;
    FpRounder #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .FRACTION_WIDTH(FRACTION_WIDTH)
    ) rounder (
        .inexact(inexact),
        .roundedExponent(exponent_rounded),
        .roundedFraction(fraction_rounded),
        .roundingMode(roundingMode),
        .sign(sign),
        .exponent(exponent_sqrt),
        .fraction(fraction_sqrt[FRACTION_WIDTH+1:2]),
        .g(fraction_sqrt[1]),
        .r(fraction_sqrt[0]),
        .s(|remnant));

    // Result
    ResultType result_type;
    always_comb begin
        if (is_nan || sign) begin
            result_type = ResultType_Nan;
        end
        else if (is_inf) begin
            result_type = ResultType_Inf;
        end
        else if (is_zero) begin
            result_type = ResultType_Zero;
        end
        else begin
            result_type = ResultType_Sqrt;
        end
    end

    always_comb begin
        unique case (result_type)
        ResultType_Sqrt: begin
            fpResult[WIDTH-1] = 0;
            fpResult[WIDTH-2:FRACTION_WIDTH] = exponent_rounded;
            fpResult[FRACTION_WIDTH-1:0] = fraction_rounded;
        end
        ResultType_Zero: begin
            fpResult = '0;
        end
        ResultType_Inf: begin
            fpResult[WIDTH-1] = 0;
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
        flags.OF = 0;
        flags.UF = 0;
        flags.NX = result_type == ResultType_Sqrt && inexact;
    end
endmodule
