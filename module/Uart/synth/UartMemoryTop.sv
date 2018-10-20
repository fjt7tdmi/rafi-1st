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

module UartMemoryTop(
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,
    output wire [35:0] GPIO_1,
    input wire [17:0] SW,
    input wire [3:0] KEY,
    input wire [35:0] GPIO_0,
    input wire CLOCK_50
);
    // localparams
    localparam BaudRate = 115200;
    localparam ClockFrequency = 50 * 1000 * 1000;

    // Wires
    logic clk;
    logic rst;
    logic uartTx;
    logic uartRx;
    logic [6:0] ledOut[6];
    logic [3:0] ledValue[6];

    int32_t debugValue;

    // Modules
    UartMemoryTestUnit #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency),
        .LineSize(4),
        .MemoryCapacity(32)
    ) m_UartTxTestUnit (
        .debugValue,
        .uartTx,
        .uartRx,
        .clk,
        .rst
    );

    Led7segDecoder m_Decoder0 (
        .in(ledValue[0]),
        .out(ledOut[0])
    );

    Led7segDecoder m_Decoder1 (
        .in(ledValue[1]),
        .out(ledOut[1])
    );

    Led7segDecoder m_Decoder2 (
        .in(ledValue[2]),
        .out(ledOut[2])
    );

    Led7segDecoder m_Decoder3 (
        .in(ledValue[3]),
        .out(ledOut[3])
    );

    Led7segDecoder m_Decoder4 (
        .in(ledValue[4]),
        .out(ledOut[4])
    );

    Led7segDecoder m_Decoder5 (
        .in(ledValue[5]),
        .out(ledOut[5])
    );

    always_comb begin
        LEDR[9] = 1;
        LEDR[8] = 0;

        for (int i = 0; i < 8; i++) begin
            LEDR[i] = debugValue[i + 24];
        end
        ledValue[5] = debugValue[23:20];
        ledValue[4] = debugValue[19:16];
        ledValue[3] = debugValue[15:12];
        ledValue[2] = debugValue[11:8];
        ledValue[1] = debugValue[7:4];
        ledValue[0] = debugValue[3:0];

        HEX0 = ~ledOut[0];
        HEX1 = ~ledOut[1];
        HEX2 = ~ledOut[2];
        HEX3 = ~ledOut[3];
        HEX4 = ~ledOut[4];
        HEX5 = ~ledOut[5];

        GPIO_1[0] = uartTx;

        clk = CLOCK_50;
        rst = ~KEY[0];
        uartRx = GPIO_0[0];
    end
endmodule
