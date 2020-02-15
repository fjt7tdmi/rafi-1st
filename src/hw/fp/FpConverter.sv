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

module FpConverter_IntRounder #(
    parameter WIDTH = 33
)(
    output logic [WIDTH-1:0] result,
    output logic inexact,
    output logic overflow,
    input logic [2:0] roundingMode,
    input logic [WIDTH-1:0] value,
    input logic g,
    input logic r,
    input logic s
);
    logic sign;
    logic ulp;
    always_comb begin
        sign = value[WIDTH-1];
        ulp = value[0];
    end

    logic increment;
    always_comb begin
        unique case (roundingMode)
        FRM_RNE: begin
            if ({g, r, s} == 3'b100) begin
                increment = ulp ? 1 : 0;
            end
            else if ({g, r, s} inside {3'b101, 3'b110, 3'b111}) begin
                increment = 1;
            end
            else begin
                increment = 0;
            end
        end
        FRM_RTZ: increment = (sign == '1 && {g, r, s} != 3'b000) ? 1 : 0;
        FRM_RDN: increment = 0;
        FRM_RUP: increment = {g, r, s} != 3'b000 ? 1 : 0;
        FRM_RMM: increment = {g, r, s} inside {3'b100, 3'b101, 3'b110, 3'b111} ? 1 : 0;
        default: increment = '0;
        endcase
    end

    always_comb begin
        result = increment ? value + 1 : value;
        inexact = g | r | s;
        overflow = result[WIDTH-1] && ~value[WIDTH-1];
    end
endmodule

module FpConverter_FpToInt32 #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter FP_WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output word_t result,
    output fflags_t flags,
    input logic intSigned,
    input logic [2:0] roundingMode,
    input logic [FP_WIDTH-1:0] src
);
    logic sign;
    logic [EXPONENT_WIDTH-1:0] exponent;
    logic [FRACTION_WIDTH-1:0] fraction;
    always_comb begin
        sign = src[FP_WIDTH-1];
        exponent = src[FP_WIDTH-2:FRACTION_WIDTH];
        fraction = src[FRACTION_WIDTH-1:0];
    end

    logic is_zero;
    logic is_nan;
    logic is_inf;
    logic [EXPONENT_WIDTH-1:0] fixed_exp32;
    always_comb begin
        is_zero = exponent == '0;
        is_nan = exponent == '1 && fraction != '0;
        is_inf = exponent == '1 && fraction == '0;
        fixed_exp32 = exponent - 127;
    end

    logic [FRACTION_WIDTH+32:0] shift_result;
    logic [FRACTION_WIDTH+32:0] signed_result;
    always_comb begin
        /* verilator lint_off WIDTH */
        shift_result = {1'b1, fraction} << fixed_exp32[4:0];
        signed_result = sign ? -shift_result : shift_result;
    end

    logic inexact;
    logic rounder_overflow;
    logic [32:0] rounder_result;

    // Rounder input/output is always signed
    FpConverter_IntRounder #(
        .WIDTH(33)
    ) rounder (
        .inexact(inexact),
        .overflow(rounder_overflow),
        .result(rounder_result),
        .roundingMode(roundingMode),
        .value(signed_result[55:23]),
        .g(signed_result[22]),
        .r(signed_result[21]),
        .s(|signed_result[20:0]));

    logic underflow;
    always_comb begin
        underflow = fixed_exp32[EXPONENT_WIDTH-1]; // fixed_exp32 < 0
    end

    // Rounder output is i33. Check if that is representable in i32 or u32.
    logic overflow;
    always_comb begin
        if (intSigned) begin
            overflow = ~fixed_exp32[EXPONENT_WIDTH-1] && fixed_exp32 >= 31 ||
                !underflow && (rounder_overflow || rounder_result[32] != rounder_result[31]);
        end
        else begin
            overflow = ~fixed_exp32[EXPONENT_WIDTH-1] && fixed_exp32 >= 32 ||
                !underflow && (rounder_overflow || rounder_result[32] == 1'b1);
        end
    end

    always_comb begin
        if (sign && is_inf) begin
            result = intSigned ? 32'h8000_0000 : 32'h0000_0000;
        end
        else if (!sign && is_inf || is_nan) begin
            result = intSigned ? 32'h7fff_ffff : 32'hffff_ffff;
        end
        else if (is_zero || underflow) begin
            result = '0;
        end
        else if (overflow && sign) begin
            result = intSigned ? 32'h8000_0000 : 32'h0000_0000;
        end
        else if (overflow && !sign) begin
            result = intSigned ? 32'h7fff_ffff : 32'hffff_ffff;
        end
        else begin
            result = rounder_result[31:0];
        end

        flags.NV = is_nan || overflow;
        flags.DZ = 0;
        flags.OF = 0;
        flags.UF = 0;
        flags.NX = !(is_nan || overflow) && (underflow || inexact);
    end
endmodule

module FpConverter_Int32ToFp #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter FP_WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output logic [FP_WIDTH-1:0] result,
    output fflags_t flags,
    input logic intSigned,
    input logic [2:0] roundingMode,
    input word_t src
);
    // TODO: Optimize
    function automatic logic [5:0] GetNumberOfLeadingZero(logic [33:0] value);
        for (int i = 0; i < 33; i++) begin
            if (value[32 - i] == 1'b1) begin
                return i;
            end
        end
        return 0;
    endfunction

    logic sign;
    logic [32:0] extendedSrc;
    logic [32:0] abs;
    always_comb begin
        sign = intSigned ? src[31] : 1'b0;
        extendedSrc = {sign, src};
        abs = sign ? -extendedSrc : extendedSrc;
    end

    logic [EXPONENT_WIDTH-1:0] shamt;
    always_comb begin
        shamt[5:0] = GetNumberOfLeadingZero(abs);
        shamt[EXPONENT_WIDTH-1:6] = '0;
    end

    localparam EXPONENT_MAX = (1 << EXPONENT_WIDTH) - 2;
    localparam SHIFTED_WIDTH = FRACTION_WIDTH + 32; // Actually, I wanted to use $max(FRACTION_WIDTH + m, 32 + n);

    logic [SHIFTED_WIDTH-1:0] shifted;
    always_comb begin
        shifted[SHIFTED_WIDTH-1:SHIFTED_WIDTH-33] = abs << shamt;
        shifted[SHIFTED_WIDTH-34:0] = '0;
    end

    logic [EXPONENT_WIDTH-1:0] exponent;
    logic [FRACTION_WIDTH-1:0] fraction;
    always_comb begin
        exponent = 32 - shamt + EXPONENT_MAX / 2;
        fraction = shifted[SHIFTED_WIDTH-2:SHIFTED_WIDTH-FRACTION_WIDTH-1];
    end

    logic inexact;
    logic [EXPONENT_WIDTH-1:0] rounded_exponent;
    logic [FRACTION_WIDTH-1:0] rounded_fraction;

    FpRounder #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .FRACTION_WIDTH(FRACTION_WIDTH)
    ) rounder (
        .inexact(inexact),
        .roundedExponent(rounded_exponent),
        .roundedFraction(rounded_fraction),
        .roundingMode(roundingMode),
        .sign(sign),
        .exponent(exponent),
        .fraction(fraction),
        .g(shifted[SHIFTED_WIDTH-FRACTION_WIDTH-2]),
        .r(shifted[SHIFTED_WIDTH-FRACTION_WIDTH-3]),
        .s(|shifted[SHIFTED_WIDTH-FRACTION_WIDTH-4:0]));

    always_comb begin
        if (src == '0) begin
            result = '0;
        end
        else begin
            result[FP_WIDTH-1] = sign;
            result[FP_WIDTH-2:FRACTION_WIDTH] = rounded_exponent;
            result[FRACTION_WIDTH-1:0] = rounded_fraction;
        end

        flags.NV = 0;
        flags.DZ = 0;
        flags.OF = 0;
        flags.UF = 0;
        flags.NX = inexact; // Set by rounding result
    end
endmodule

module FpConverter (
    output word_t intResult,
    output uint64_t fpResult,
    output logic writeFlags,
    output fflags_t writeFlagsValue,
    input FpConverterCommand command,
    input logic [2:0] roundingMode,
    input word_t intSrc,
    input uint64_t fpSrc,
    input logic clk,
    input logic rst
);
    logic intSigned;
    always_comb begin
        intSigned = command inside {
            FpConverterCommand_W_S,
            FpConverterCommand_L_S,
            FpConverterCommand_W_D,
            FpConverterCommand_L_D,
            FpConverterCommand_S_W,
            FpConverterCommand_S_L,
            FpConverterCommand_D_W,
            FpConverterCommand_D_L
        };
    end

    word_t result_f32_to_i32;
    fflags_t flags_f32_to_i32;    
    FpConverter_FpToInt32 #(
        .EXPONENT_WIDTH(8),
        .FRACTION_WIDTH(23)
    ) m_Fp32ToInt32 (
        .result(result_f32_to_i32),
        .flags(flags_f32_to_i32),
        .intSigned(intSigned),
        .roundingMode(roundingMode),
        .src(fpSrc[31:0]));

    word_t result_f64_to_i32;
    fflags_t flags_f64_to_i32;    
    FpConverter_FpToInt32 #(
        .EXPONENT_WIDTH(11),
        .FRACTION_WIDTH(52)
    ) m_Fp64ToInt32 (
        .result(result_f64_to_i32),
        .flags(flags_f64_to_i32),
        .intSigned(intSigned),
        .roundingMode(roundingMode),
        .src(fpSrc));

    logic [31:0] result_i32_to_f32;
    fflags_t flags_i32_to_f32;    
    FpConverter_Int32ToFp #(
        .EXPONENT_WIDTH(8),
        .FRACTION_WIDTH(23)
    ) m_i32_to_f32(
        .result(result_i32_to_f32),
        .flags(flags_i32_to_f32),
        .intSigned(intSigned),
        .roundingMode(roundingMode),
        .src(intSrc));

    logic [63:0] result_i32_to_f64;
    fflags_t flags_i32_to_f64;    
    FpConverter_Int32ToFp #(
        .EXPONENT_WIDTH(11),
        .FRACTION_WIDTH(52)
    ) m_i32_to_f64(
        .result(result_i32_to_f64),
        .flags(flags_i32_to_f64),
        .intSigned(intSigned),
        .roundingMode(roundingMode),
        .src(intSrc));

    always_comb begin
        if (command inside {FpConverterCommand_W_S, FpConverterCommand_WU_S})  begin
            intResult = result_f32_to_i32;
            fpResult = '0;
            writeFlags = 1;
            writeFlagsValue = flags_f32_to_i32;
        end
        else if (command inside {FpConverterCommand_W_D, FpConverterCommand_WU_D})  begin
            intResult = result_f64_to_i32;
            fpResult = '0;
            writeFlags = 1;
            writeFlagsValue = flags_f64_to_i32;
        end
        else if (command inside {FpConverterCommand_S_W, FpConverterCommand_S_WU})  begin
            intResult = '0;
            fpResult = {32'h0, result_i32_to_f32};
            writeFlags = 1;
            writeFlagsValue = flags_i32_to_f32;
        end
        else if (command inside {FpConverterCommand_D_W, FpConverterCommand_D_WU})  begin
            intResult = '0;
            fpResult = result_i32_to_f64;
            writeFlags = 1;
            writeFlagsValue = flags_i32_to_f64;
        end
        else begin
            intResult = '0;
            fpResult = '0;
            writeFlags = '0;
            writeFlagsValue = '0;
        end
    end
endmodule
