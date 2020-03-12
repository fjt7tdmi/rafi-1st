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

module FpComparator #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output word_t intResult,
    output logic unsigned [WIDTH-1:0] fpResult,
    output fflags_t flags,
    input FpComparatorCommand command,
    input logic unsigned [WIDTH-1:0] fpSrc1,
    input logic unsigned [WIDTH-1:0] fpSrc2,
    input logic clk,
    input logic rst
);
    typedef enum logic [1:0]
    {
        FpResultType_Src1           = 2'h0,
        FpResultType_Src2           = 2'h1,
        FpResultType_QuietNan       = 2'h2,
        FpResultType_SignalingNan   = 2'h3
    } FpResultType;

    typedef logic unsigned [EXPONENT_WIDTH-1:0] exponent_t;
    typedef logic unsigned [FRACTION_WIDTH-1:0] fraction_t;

    function automatic logic unsigned [WIDTH-1:0] GetCanonicalQuietNan();
        logic unsigned [WIDTH-1:0] value;
        value[WIDTH-1] = '0;
        value[WIDTH-2:FRACTION_WIDTH-1] = '1;
        value[FRACTION_WIDTH-2:0] = '0;
        return value;
    endfunction

    function automatic logic unsigned [WIDTH-1:0] GetCanonicalSignalingNan();
        logic unsigned [WIDTH-1:0] value;
        value[WIDTH-1] = '0;
        value[WIDTH-2:FRACTION_WIDTH] = '1;
        value[FRACTION_WIDTH-1:1] = '0;
        value[0] = '1;
        return value;
    endfunction

    logic sign1;
    logic sign2;
    exponent_t exponent1;
    exponent_t exponent2;
    fraction_t fraction1;
    fraction_t fraction2;
    always_comb begin
        sign1 = fpSrc1[WIDTH-1];
        sign2 = fpSrc2[WIDTH-1];
        exponent1 = fpSrc1[WIDTH-2:FRACTION_WIDTH];
        exponent2 = fpSrc2[WIDTH-2:FRACTION_WIDTH];
        fraction1 = fpSrc1[FRACTION_WIDTH-1:0];
        fraction2 = fpSrc2[FRACTION_WIDTH-1:0];
    end

    logic is_zero1;
    logic is_zero2;
    logic is_nan1;
    logic is_nan2;
    logic is_signaling_nan1;
    logic is_signaling_nan2;
    always_comb begin
        is_zero1 = exponent1 == '0 && fraction1 != '0;
        is_zero2 = exponent2 == '0 && fraction2 != '0;
        is_nan1 = exponent1 == '1 && fraction1 != '0;
        is_nan2 = exponent2 == '1 && fraction2 != '0;
        is_signaling_nan1 = is_nan1 && fraction1[FRACTION_WIDTH-1] == '0;
        is_signaling_nan2 = is_nan2 && fraction2[FRACTION_WIDTH-1] == '0;
    end

    logic sign_eq;
    logic sign_lt;
    logic sign_le;
    always_comb begin
        sign_eq = sign1 == sign2;
        sign_lt = sign1 == 1 && sign2 == 0;
        sign_le = sign_eq && sign_lt;
    end

    logic exponent_eq;
    logic exponent_lt;
    logic exponent_le;
    always_comb begin
        exponent_eq = exponent1 == exponent2;
        exponent_lt = exponent1 < exponent2;
        exponent_le = exponent1 <= exponent2;
    end

    logic fraction_eq;
    logic fraction_lt;
    logic fraction_le;
    always_comb begin
        fraction_eq = fraction1 == fraction2;
        fraction_lt = fraction1 < fraction2;
        fraction_le = fraction1 <= fraction2;
    end

    logic eq;
    logic lt;
    logic le;
    always_comb begin
        eq = (sign_eq & exponent_eq & fraction_eq) | (is_zero1 & is_zero2);
        lt = sign_lt |
            (sign_eq & !sign1 & exponent_lt) |
            (sign_eq & sign1 & !exponent_le) |
            (sign_eq & exponent_eq & !sign1 & fraction_lt) |
            (sign_eq & exponent_eq & sign1 & !fraction_le);
        le = eq | lt;
    end

    FpResultType fp_result_type;
    always_comb begin
        if (is_zero1 && is_zero2) begin
            fp_result_type = (!sign1 && sign2) ? FpResultType_Src1 : FpResultType_Src2;
        end
        else if (is_nan1 && is_nan2) begin
            fp_result_type = (is_signaling_nan1 || is_signaling_nan2) ? FpResultType_SignalingNan : FpResultType_QuietNan;
        end
        else if (!is_nan1 && is_nan2) begin
            fp_result_type = FpResultType_Src1;
        end
        else if (is_nan1 && !is_nan2) begin
            fp_result_type = FpResultType_Src2;
        end
        else begin
            unique case (command)
            FpComparatorCommand_Max: fp_result_type = lt ? FpResultType_Src2 : FpResultType_Src1;
            FpComparatorCommand_Min: fp_result_type = lt ? FpResultType_Src1 : FpResultType_Src2;
            default:                 fp_result_type = '0;
            endcase
        end
    end

    always_comb begin
        if (is_nan1 || is_nan2) begin
            intResult = 0;
        end
        else begin
            unique case (command)
            FpComparatorCommand_Eq: intResult = eq ? 1 : 0;
            FpComparatorCommand_Lt: intResult = lt ? 1 : 0;
            FpComparatorCommand_Le: intResult = le ? 1 : 0;
            default:                intResult = 0;
            endcase
        end

        unique case (fp_result_type)
        FpResultType_Src1:          fpResult = fpSrc1;
        FpResultType_Src2:          fpResult = fpSrc2;
        FpResultType_QuietNan:      fpResult = GetCanonicalQuietNan();
        FpResultType_SignalingNan:  fpResult = GetCanonicalSignalingNan();
        default:                    fpResult = '0;
        endcase

        if (command inside { FpComparatorCommand_Lt, FpComparatorCommand_Le }) begin
            flags.NV = is_nan1 || is_nan2;
            flags.DZ = 0;
            flags.OF = 0;
            flags.UF = 0;
            flags.NX = 0;
        end
        else begin
            flags.NV = is_signaling_nan1 || is_signaling_nan2;
            flags.DZ = 0;
            flags.OF = 0;
            flags.UF = 0;
            flags.NX = 0;
        end
    end
endmodule
