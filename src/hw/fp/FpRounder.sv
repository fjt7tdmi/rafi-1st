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

module FpRounder #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output logic [EXPONENT_WIDTH-1:0] roundedExponent,
    output logic [FRACTION_WIDTH-1:0] roundedFraction,
    output logic inexact,
    input logic [2:0] roundingMode,
    input logic sign,
    input logic [EXPONENT_WIDTH-1:0] exponent,
    input logic [FRACTION_WIDTH-1:0] fraction,
    input logic g,
    input logic r,
    input logic s
);
    logic [FRACTION_WIDTH:0] extendedFraction;
    logic ulp;
    always_comb begin
        extendedFraction = {1'b1, fraction};
        ulp = fraction[0];
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

    logic [FRACTION_WIDTH:0] incrementdFraction;
    always_comb begin
        incrementdFraction = extendedFraction + 1;
    end

    always_comb begin
        if (increment && !incrementdFraction[FRACTION_WIDTH]) begin
            roundedExponent = exponent + 1;
            roundedFraction = incrementdFraction[FRACTION_WIDTH:1];
        end
        else if (increment && incrementdFraction[FRACTION_WIDTH]) begin
            roundedExponent = exponent;
            roundedFraction = incrementdFraction[FRACTION_WIDTH-1:0];
        end
        else begin
            roundedExponent = exponent;
            roundedFraction = fraction;
        end

        inexact = g | r | s;
    end
endmodule
