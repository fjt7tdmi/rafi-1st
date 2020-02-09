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

module FpConverter_round_f32_to_i32 (
    output word_t result,
    output logic inexact,
    output logic overflow,
    input logic [2:0] roundingMode,
    input word_t value,
    input logic g,
    input logic r,
    input logic s
);
    logic value_sign;
    logic ulp;
    always_comb begin
        value_sign = value[31];
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
        FRM_RTZ: increment = (value_sign == '1 && {g, r, s} != 3'b000) ? 1 : 0;
        FRM_RDN: increment = 0;
        FRM_RUP: increment = {g, r, s} != 3'b000 ? 1 : 0;
        FRM_RMM: increment = {g, r, s} inside {3'b100, 3'b101, 3'b110, 3'b111} ? 1 : 0;
        default: increment = '0;
        endcase
    end

    always_comb begin
        result = increment ? value + 1 : value;
        inexact = g | r | s;
        overflow = result[31] && ~value[31];
    end
endmodule

module FpConverter_f32_to_i32 (
    output word_t result,
    output fflags_t flags,
    input logic [2:0] roundingMode,
    input fp32_t src
);
    logic is_zero;
    logic is_nan;
    logic [7:0] fixed_exp32;
    always_comb begin
        is_nan = src.exponent == '1 && src.fraction != '0;
        is_zero = src.exponent == '0;
        fixed_exp32 = src.exponent - 127;
    end

    logic [55:0] shift_result;
    logic [55:0] signed_result;
    always_comb begin
        /* verilator lint_off WIDTH */
        shift_result = {1'b1, src.fraction} << fixed_exp32[4:0];
        signed_result = src.sign ? -shift_result : shift_result;
    end

    logic inexact;
    logic rounder_overflow;
    logic [32:0] rounder_result;

    FpConverter_round_f32_to_i32 rounder(
        .inexact(inexact),
        .overflow(rounder_overflow),
        .result(rounder_result),
        .roundingMode(roundingMode),
        .value(signed_result[55:23]),
        .g(signed_result[22]),
        .r(signed_result[21]),
        .s(|signed_result[20:0]));

    logic overflow;
    logic underflow;
    always_comb begin
        overflow = (~fixed_exp32[7] && fixed_exp32 >= 31) || rounder_overflow;
        underflow = fixed_exp32[7]; // fixed_exp32 < 0
    end

    always_comb begin
        if (is_zero || is_nan || underflow) begin
            result = '0;
        end
        else if (overflow) begin
            result = src.sign ? 32'h8000_0000 : 32'h7fff_ffff;
        end
        else begin
            result = rounder_result;
        end

        flags.NV = is_nan || overflow;
        flags.DZ = 0;
        flags.OF = 0;
        flags.UF = 0;
        flags.NX = !(is_nan || overflow) && (underflow || inexact); // Set by rounding result
    end
endmodule

module FpConverter (
    output word_t intResult,
    output uint64_t fpResult,
    output fflags_t flags,
    input FpConverterCommand command,
    input logic [2:0] roundingMode,
    input word_t intSrc,
    input uint64_t fpSrc,
    input logic clk,
    input logic rst
);
    fp32_t fp32_src;
    always_comb begin
        fp32_src = fpSrc[31:0];
    end

    word_t result_f32_to_i32;
    fflags_t flags_f32_to_i32;    
    FpConverter_f32_to_i32 m_f32_to_i32(
        .result(result_f32_to_i32),
        .flags(flags_f32_to_i32),
        .roundingMode(roundingMode),
        .src(fp32_src));

    always_comb begin
        unique case (command)
        FpConverterCommand_W_S: begin
            intResult = result_f32_to_i32;
            fpResult = '0;
            flags = flags_f32_to_i32;
        end
        default: begin
            intResult = '0;
            fpResult = '0;
            flags = '0;
        end
        endcase
    end
endmodule
