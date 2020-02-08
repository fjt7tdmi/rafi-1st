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

module FpConverter_f32_to_i32 (
    output word_t result,
    output fflags_t flags,
    input logic [2:0] roundingMode,
    input fp32_t src
);
    logic is_nan;
    logic is_zero;
    logic [7:0] fixed_exp32;
    logic overflow;
    logic underflow;
    logic [55:0] shift_result;
    logic [55:0] signed_result;
    always_comb begin
        is_nan = src.exponent == '1 && src.fraction != '0;
        is_zero = src.exponent == '0;
        fixed_exp32 = src.exponent - 127;
        overflow = ~fixed_exp32[7] && |fixed_exp32[6:5]; // fixed_exp32 >= 32;
        underflow = fixed_exp32[7]; // fixed_exp32 < 0

        /* verilator lint_off WIDTH */
        shift_result = {1'b1, src.fraction} << fixed_exp32[4:0];
        signed_result = -shift_result;
    end

    // TODO: implement rounding 

    always_comb begin
        result = (is_nan || is_zero || overflow || underflow) ? '0 : signed_result[54:23];

        flags.NV = is_nan;
        flags.DZ = 0;
        flags.OF = 0;
        flags.UF = 0;
        flags.NX = 0; // Set by rounding result
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
