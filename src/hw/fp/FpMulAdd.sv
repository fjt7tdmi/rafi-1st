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

module FpMul #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output logic [WIDTH-1:0] result,
    output fflags_t flags,
    input logic [2:0] roundingMode,
    input logic [WIDTH-1:0] src1,
    input logic [WIDTH-1:0] src2
);
    typedef enum logic [1:0]
    {
        ResultType_Production = 2'h0,
        ResultType_Zero       = 2'h1,
        ResultType_Inf        = 2'h2,
        ResultType_Nan        = 2'h3
    } ResultType;

    logic sign1;
    logic sign2;
    logic [EXPONENT_WIDTH-1:0] exponent1;
    logic [EXPONENT_WIDTH-1:0] exponent2;
    logic [FRACTION_WIDTH-1:0] fraction1;
    logic [FRACTION_WIDTH-1:0] fraction2;
    always_comb begin
        sign1 = src1[WIDTH-1];
        sign2 = src2[WIDTH-1];
        exponent1 = src1[WIDTH-2:FRACTION_WIDTH];
        exponent2 = src2[WIDTH-2:FRACTION_WIDTH];
        fraction1 = src1[FRACTION_WIDTH-1:0];
        fraction2 = src2[FRACTION_WIDTH-1:0];
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
    logic [FRACTION_WIDTH:0] fraction1_extended;
    logic [FRACTION_WIDTH:0] fraction2_extended;
    always_comb begin
        exponent1_extended = {2'h0, exponent1};
        exponent2_extended = {2'h0, exponent2};
        fraction1_extended = {1'h1, fraction1};
        fraction2_extended = {1'h1, fraction2};
    end

    // Calculate sum of exponents and production of fractions.
    logic sign;
    logic signed [EXPONENT_WIDTH+1:0] exponent_sum;
    logic [FRACTION_WIDTH*2+1:0] fraction_prod;
    always_comb begin
        sign = sign1 ^ sign2;
        exponent_sum = exponent1_extended + exponent2_extended - 127;
        fraction_prod = fraction1_extended * fraction2_extended;
    end

    // Normalize
    logic signed [EXPONENT_WIDTH+1:0] exponent_normalized;
    logic [FRACTION_WIDTH*2:0] fraction_normalized;
    always_comb begin
        if (fraction_prod[FRACTION_WIDTH*2+1]) begin
            exponent_normalized = exponent_sum + 1;
            fraction_normalized = fraction_prod[FRACTION_WIDTH*2+1:1];
        end
        else begin
            exponent_normalized = exponent_sum;
            fraction_normalized = fraction_prod[FRACTION_WIDTH*2:0];
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
        .fraction(fraction_normalized[FRACTION_WIDTH*2-1:FRACTION_WIDTH]),
        .g(fraction_normalized[FRACTION_WIDTH-1]),
        .r(fraction_normalized[FRACTION_WIDTH-2]),
        .s(|fraction_normalized[FRACTION_WIDTH-3:0]));

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
        if (is_nan1 || is_nan2 || (is_zero1 && is_inf2) || (is_zero2 && is_inf1)) begin
            result_type = ResultType_Nan;
        end
        else if (is_inf1 || is_inf2) begin
            result_type = ResultType_Inf;
        end
        else if (is_zero1 || is_zero2) begin
            result_type = ResultType_Zero;
        end
        else begin
            result_type = ResultType_Production;
        end
    end

    always_comb begin
        unique case (result_type)
        ResultType_Production: begin
            result[WIDTH-1] = sign;
            result[WIDTH-2:FRACTION_WIDTH] = exponent_rounded[EXPONENT_WIDTH-1:0];
            result[FRACTION_WIDTH-1:0] = fraction_rounded;
        end
        ResultType_Zero: begin
            result[WIDTH-1] = sign;
            result[WIDTH-2:0] = '0;
        end
        ResultType_Inf: begin
            result[WIDTH-1] = sign;
            result[WIDTH-2:FRACTION_WIDTH] = '1;
            result[FRACTION_WIDTH-1:0] = '0;
        end
        ResultType_Nan: begin
            // Canonical Signaling NaN
            result[WIDTH-1] = '0;
            result[WIDTH-2:FRACTION_WIDTH] = '1;
            result[FRACTION_WIDTH-1:1] = '0;
            result[0] = '1;
        end
        default: begin
            result = '0;
        end
        endcase

        flags.NV = result_type == ResultType_Nan;
        flags.DZ = 0;
        flags.OF = overflow;
        flags.UF = underflow;
        flags.NX = inexact;
    end
endmodule

module FpAdd #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output logic [WIDTH-1:0] result,
    output fflags_t flags,
    input logic [2:0] roundingMode,
    input logic minus1,
    input logic minus2,
    input logic [WIDTH-1:0] src1,
    input logic [WIDTH-1:0] src2
);
    parameter EXPONENT_MAX = (1 << EXPONENT_WIDTH) - 2;

    typedef enum logic [1:0]
    {
        ResultType_Sum  = 2'h0,
        ResultType_Zero = 2'h1,
        ResultType_Inf  = 2'h2,
        ResultType_Nan  = 2'h3
    } ResultType;

    logic sign1;
    logic sign2;
    logic [EXPONENT_WIDTH-1:0] exponent1;
    logic [EXPONENT_WIDTH-1:0] exponent2;
    logic [FRACTION_WIDTH-1:0] fraction1;
    logic [FRACTION_WIDTH-1:0] fraction2;
    always_comb begin
        sign1 = src1[WIDTH-1] ^ minus1;
        sign2 = src2[WIDTH-1] ^ minus2;
        exponent1 = src1[WIDTH-2:FRACTION_WIDTH];
        exponent2 = src2[WIDTH-2:FRACTION_WIDTH];
        fraction1 = src1[FRACTION_WIDTH-1:0];
        fraction2 = src2[FRACTION_WIDTH-1:0];
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

    // Compare abs(src1) and abs(src2)
    logic ge; // abs(src1) >= abs(src2)
    logic sign_large;
    logic sign_small;
    logic [EXPONENT_WIDTH-1:0] exponent_large;
    logic [EXPONENT_WIDTH-1:0] exponent_small;
    logic [FRACTION_WIDTH-1:0] fraction_large;
    logic [FRACTION_WIDTH-1:0] fraction_small;
    always_comb begin
        ge = (exponent1 > exponent2) ||
            (exponent1 == exponent2 && fraction1 >= fraction2);
        sign_large = ge ? sign1 : sign2;
        sign_small = ge ? sign2 : sign1;
        exponent_large = ge ? exponent1 : exponent2;
        exponent_small = ge ? exponent2 : exponent1;
        fraction_large = ge ? fraction1 : fraction2;
        fraction_small = ge ? fraction2 : fraction1;
    end

    // Extend for shift and rounding
    logic [FRACTION_WIDTH*2+3:0] fraction_large_extended;
    logic [FRACTION_WIDTH*2+3:0] fraction_small_extended;
    always_comb begin
        fraction_large_extended[FRACTION_WIDTH*2+3] = 1'b0;
        fraction_large_extended[FRACTION_WIDTH*2+2] = 1'b1;
        fraction_large_extended[FRACTION_WIDTH*2+1:FRACTION_WIDTH+2] = fraction_large;
        fraction_large_extended[FRACTION_WIDTH+1:0] = '0;
        fraction_small_extended[FRACTION_WIDTH*2+3] = 1'b0;
        fraction_small_extended[FRACTION_WIDTH*2+2] = 1'b1;
        fraction_small_extended[FRACTION_WIDTH*2+1:FRACTION_WIDTH+2] = fraction_small;
        fraction_small_extended[FRACTION_WIDTH+1:0] = '0;
    end

    // Shift smaller value
    logic [EXPONENT_WIDTH-1:0] shamt;
    logic [FRACTION_WIDTH*2+3:0] fraction_small_shifted;
    always_comb begin
        shamt = exponent_large - exponent_small;
        fraction_small_shifted = fraction_small_extended >> shamt;
    end

    // Adder
    logic minus;
    logic [FRACTION_WIDTH*2+3:0] fraction_added;
    always_comb begin
        minus = sign_large != sign_small;
        fraction_added = fraction_large_extended +
            (minus ? -fraction_small_shifted : fraction_small_shifted);
    end

    // Normalize
    function automatic logic [EXPONENT_WIDTH+1:0] GetNumberOfLeadingZero(logic [FRACTION_WIDTH*2+3:0] value);
        // TODO: Optimize
        for (int i = FRACTION_WIDTH*2+3; i >= 0; i--) begin
            if (value[i] == 1'b1) begin
                /* verilator lint_off WIDTH */
                return FRACTION_WIDTH*2+3 - i;
            end
        end
        return 0;
    endfunction

    logic [EXPONENT_WIDTH+1:0] shamt_normalize;
    logic signed [EXPONENT_WIDTH+1:0] exponent_normalized;
    logic [FRACTION_WIDTH*2+3:0] fraction_normalized;
    always_comb begin
        shamt_normalize = GetNumberOfLeadingZero(fraction_added);
        exponent_normalized = {2'h0, exponent_large} + 1 - shamt_normalize;
        fraction_normalized = fraction_added << shamt_normalize;
    end

    // Rounding
    logic inexact;
    logic [EXPONENT_WIDTH+1:0] exponent_rounded;
    logic [FRACTION_WIDTH-1:0] fraction_rounded;

    FpRounder #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .FRACTION_WIDTH(FRACTION_WIDTH)
    ) rounder (
        .inexact(inexact),
        .roundedExponent(exponent_rounded),
        .roundedFraction(fraction_rounded),
        .roundingMode(roundingMode),
        .sign(sign_large),
        .exponent(exponent_normalized[EXPONENT_WIDTH-1:0]),
        .fraction(fraction_normalized[FRACTION_WIDTH*2+2:FRACTION_WIDTH+3]),
        .g(fraction_normalized[FRACTION_WIDTH+2]),
        .r(fraction_normalized[FRACTION_WIDTH+1]),
        .s(|fraction_normalized[FRACTION_WIDTH:0]));

    // Detect overflow and underflow
    logic overflow;
    logic underflow;

    always_comb begin
        overflow = exponent_rounded > EXPONENT_MAX;
        underflow = exponent_rounded <= 0;
    end

    // Result
    ResultType result_type;
    always_comb begin
        if (is_nan1 || is_nan2) begin
            result_type = ResultType_Nan;
        end
        else if (is_inf1 && is_inf2 && sign1 != sign2) begin
            result_type = ResultType_Nan;
        end
        else if (is_inf1 || is_inf2) begin
            result_type = ResultType_Inf;
        end
        else if (is_zero1 && is_zero2) begin
            result_type = ResultType_Zero;
        end
        else begin
            result_type = ResultType_Sum;
        end
    end

    always_comb begin
        unique case (result_type)
        ResultType_Sum: begin
            result[WIDTH-1] = sign_large;
            result[WIDTH-2:FRACTION_WIDTH] = exponent_rounded[EXPONENT_WIDTH-1:0];
            result[FRACTION_WIDTH-1:0] = fraction_rounded;
        end
        ResultType_Zero: begin
            result = '0;
        end
        ResultType_Inf: begin
            result[WIDTH-1] = sign_large;
            result[WIDTH-2:FRACTION_WIDTH] = '1;
            result[FRACTION_WIDTH-1:0] = '0;
        end
        ResultType_Nan: begin
            // Canonical Quiet NaN
            result[WIDTH-1] = '0;
            result[WIDTH-2:FRACTION_WIDTH-1] = '1;
            result[FRACTION_WIDTH-2:0] = '0;
        end
        default: begin
            result = '0;
        end
        endcase

        flags.NV = result_type == ResultType_Nan;
        flags.DZ = 0;
        flags.OF = (result_type != ResultType_Nan) && overflow;
        flags.UF = (result_type != ResultType_Nan) && underflow;
        flags.NX = (result_type != ResultType_Nan) && inexact;
    end
endmodule

module FpMulAdd #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output logic [WIDTH-1:0] fpResult,
    output fflags_t flags,
    input logic [2:0] roundingMode,
    input FpMulAddCommand command,
    input logic [WIDTH-1:0] fpSrc1,
    input logic [WIDTH-1:0] fpSrc2,
    input logic [WIDTH-1:0] fpSrc3,
    input logic clk,
    input logic rst
);
    logic [WIDTH-1:0] resultMul;
    fflags_t flagsMul;
    FpMul m_FpMul (
        .result(resultMul),
        .flags(flagsMul),
        .roundingMode(roundingMode),
        .src1(fpSrc1),
        .src2(fpSrc2));

    logic [WIDTH-1:0] resultAdd;
    fflags_t flagsAdd;
    logic useSrc3;
    logic minus1;
    logic minus2;
    FpAdd m_FpAdd (
        .result(resultAdd),
        .flags(flagsAdd),
        .roundingMode(roundingMode),
        .minus1(minus1),
        .minus2(minus2),
        .src1(useSrc3 ? resultMul : fpSrc1),
        .src2(useSrc3 ? fpSrc3 : fpSrc2));

    always_comb begin
        fpResult = command inside {FpMulAddCommand_FMUL} ? resultMul : resultAdd;
        flags    = command inside {FpMulAddCommand_FMUL} ? flagsMul : flagsAdd;
        useSrc3  = command inside {FpMulAddCommand_FMADD, FpMulAddCommand_FMSUB, FpMulAddCommand_FNMADD, FpMulAddCommand_FNMSUB};
        minus1   = command inside {FpMulAddCommand_FNMADD, FpMulAddCommand_FNMSUB};
        minus2   = command inside {FpMulAddCommand_FSUB, FpMulAddCommand_FMSUB, FpMulAddCommand_FNMADD};
    end
endmodule
