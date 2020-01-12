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

module Led7segTop(
    input wire CLOCK_50,
    input wire [3:0] KEY,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5
);
    // Registers
    int32_t reg_Count;

    // Wires
    logic clk;
    logic rst;
    logic [6:0] led[6];
    logic [3:0] value[6];

    int32_t next_Count;

    Led7segDecoder m_Decoder0 (
        .in(value[0]),
        .out(led[0])
    );

    Led7segDecoder m_Decoder1 (
        .in(value[1]),
        .out(led[1])
    );

    Led7segDecoder m_Decoder2 (
        .in(value[2]),
        .out(led[2])
    );

    Led7segDecoder m_Decoder3 (
        .in(value[3]),
        .out(led[3])
    );

    Led7segDecoder m_Decoder4 (
        .in(value[4]),
        .out(led[4])
    );

    Led7segDecoder m_Decoder5 (
        .in(value[5]),
        .out(led[5])
    );

    always_comb begin
        clk = CLOCK_50;
        rst = ~KEY[0];

        if (KEY[1]) begin
            value[0] = 4'h0;
            value[1] = 4'h1;
            value[2] = 4'h2;
            value[3] = 4'h3;
            value[4] = 4'h4;
            value[5] = 4'h5;
        end
        else begin
            for (int i = 0; i < 6; i++) begin
                value[i] = reg_Count[28:25];
            end
        end

        HEX0 = ~led[0];
        HEX1 = ~led[1];
        HEX2 = ~led[2];
        HEX3 = ~led[3];
        HEX4 = ~led[4];
        HEX5 = ~led[5];

        next_Count = reg_Count + 1;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_Count <= '0;
        end
        else begin
            reg_Count <= next_Count;
        end
    end
endmodule
