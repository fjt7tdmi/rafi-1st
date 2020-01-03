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

module SystemWithInternalMemory_DE0CV(
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
    // parameter
    parameter BaudRate = 115200;
    parameter ClockFrequency = 50 * 1000 * 1000;
    parameter MemoryCapacity = 128 * 1024;
    parameter MemoryLineSize = 16;

    // typedef
    typedef enum logic [1:0]
    {
        UartLoadSizeType_0,
        UartLoadSizeType_64,
        UartLoadSizeType_32K,
        UartLoadSizeType_4M
    } UartLoadSizeType;

    // Registers
    UartLoadSizeType reg_UartLoadSize;

    // Wires
    int32_t uartLoadSize;
    int32_t debugValue;
    logic uartRx;
    logic uartTx;
    logic clk;
    logic rst;
    logic [6:0] ledOut[6];
    logic [3:0] ledValue[6];
    logic unused;

    // Modules
    SystemWithInternalMemory #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency),
        .MemoryCapacity(MemoryCapacity),
        .MemoryLineSize(MemoryLineSize)
    ) m_Top (
        .debugValue,
        .uartLoadSize,
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
        LEDR[9:8] = reg_UartLoadSize;

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

        clk = CLOCK_50;
        rst = ~KEY[0];
        uartRx = GPIO_0[0];
        
        GPIO_1[0] = uartTx;

        unique case (reg_UartLoadSize)
        UartLoadSizeType_64:    uartLoadSize = 64;
        UartLoadSizeType_32K:   uartLoadSize = 32 * 1024;
        UartLoadSizeType_4M:    uartLoadSize = 4 * 1024 * 1024;
        default:                uartLoadSize = 0;
        endcase

        // To suppress warning, do something for unused pins.
        unused = (|SW[7:0]) || (|KEY[3:1]) || (|GPIO_0[35:1]);
        GPIO_1[35:1] = unused ? '1 : '0;
    end

    always @(posedge clk) begin
        if (rst) begin
            reg_UartLoadSize <= UartLoadSizeType'(SW[9:8]);
        end
        else begin
            reg_UartLoadSize <= reg_UartLoadSize;
        end
    end
endmodule
