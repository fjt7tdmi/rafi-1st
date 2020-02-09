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

module FpConverter_rounder_i33 (
    output logic [32:0] result,
    output logic inexact,
    output logic overflow,
    input logic [2:0] roundingMode,
    input logic [32:0] value,
    input logic g,
    input logic r,
    input logic s
);
    logic sign;
    logic ulp;
    always_comb begin
        sign = value[32];
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
        result = increment ? value + 33'b1 : value;
        inexact = g | r | s;
        overflow = result[32] && ~value[32];
    end
endmodule

module FpConverter_f32_to_i32 (
    output word_t result,
    output fflags_t flags,
    input logic intSigned,
    input logic [2:0] roundingMode,
    input fp32_t src
);
    logic is_zero;
    logic is_nan;
    logic is_inf;
    logic [7:0] fixed_exp32;
    always_comb begin
        is_zero = src.exponent == '0;
        is_nan = src.exponent == '1 && src.fraction != '0;
        is_inf = src.exponent == '1 && src.fraction == '0;
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

    // Rounder input/output is always signed
    FpConverter_rounder_i33 rounder(
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
        underflow = fixed_exp32[7]; // fixed_exp32 < 0
    end

    // Rounder output is i33. Check if that is representable in i32 or u32.
    logic overflow;
    always_comb begin
        if (intSigned) begin
            overflow = ~fixed_exp32[7] && fixed_exp32 >= 31 ||
                !underflow && (rounder_overflow || rounder_result[32] != rounder_result[31]);
        end
        else begin
            overflow = ~fixed_exp32[7] && fixed_exp32 >= 32 ||
                !underflow && (rounder_overflow || rounder_result[32] == 1'b1);
        end
    end

    always_comb begin
        if (src.sign && is_inf) begin
            result = intSigned ? 32'h8000_0000 : 32'h0000_0000;
        end
        else if (!src.sign && is_inf || is_nan) begin
            result = intSigned ? 32'h7fff_ffff : 32'hffff_ffff;
        end
        else if (is_zero || underflow) begin
            result = '0;
        end
        else if (overflow && src.sign) begin
            result = intSigned ? 32'h8000_0000 : 32'h0000_0000;
        end
        else if (overflow && !src.sign) begin
            result = intSigned ? 32'h7fff_ffff : 32'hffff_ffff;
        end
        else begin
            result = rounder_result[31:0];
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

    fp32_t fp32_src;
    always_comb begin
        fp32_src = fpSrc[31:0];
    end

    word_t result_f32_to_i32;
    fflags_t flags_f32_to_i32;    
    FpConverter_f32_to_i32 m_f32_to_i32(
        .result(result_f32_to_i32),
        .flags(flags_f32_to_i32),
        .intSigned(intSigned),
        .roundingMode(roundingMode),
        .src(fp32_src));

    always_comb begin
        if (command inside {FpConverterCommand_W_S, FpConverterCommand_WU_S})  begin
            intResult = result_f32_to_i32;
            fpResult = '0;
            flags = flags_f32_to_i32;
        end
        else begin
            intResult = '0;
            fpResult = '0;
            flags = '0;
        end
    end
endmodule
