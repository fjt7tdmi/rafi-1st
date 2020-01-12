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

module Led7segDecoder (
    input wire [3:0] in,
    output wire [6:0] out
);
    always_comb begin
        unique case (in)
        // ----------- gfedcba
        4'h0: out = 7'b0111111;
        4'h1: out = 7'b0000110;
        4'h2: out = 7'b1011011;
        4'h3: out = 7'b1001111;
        4'h4: out = 7'b1100110;
        4'h5: out = 7'b1101101;
        4'h6: out = 7'b1111101;
        4'h7: out = 7'b0100111;
        4'h8: out = 7'b1111111;
        4'h9: out = 7'b1101111;
        4'ha: out = 7'b1110111;
        4'hb: out = 7'b1111100;
        4'hc: out = 7'b1011000;
        4'hd: out = 7'b1011110;
        4'he: out = 7'b1111001;
        4'hf: out = 7'b1110001;
        default: out = '0;
        endcase
    end
endmodule
