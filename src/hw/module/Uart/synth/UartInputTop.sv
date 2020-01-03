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

module UartInputTop(
    input wire CLOCK_50,
    //input wire [17:0] SW,
    input wire [3:0] KEY,
    input wire [35:0] GPIO_0,
    //output wire [35:0] GPIO_1,
    output wire [9:0] LEDR
);
    // localparams
    localparam BaudRate = 115200;
    localparam ClockFrequency = 50 * 1000 * 1000;
    localparam LineSize = 4;

    // Wires
    logic clk;
    logic rst;
    logic uartRx;

    int32_t totalMemoryWriteSize;
    logic   memoryWriteDone;
    logic   memoryWriteEnable;
    logic   [LineSize*ByteWidth-1:0] memoryWriteValue;

    UartInput  #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency),
        .LineSize(LineSize)
    ) m_UartInput (
        .totalMemoryWriteSize,
        .memoryWriteEnable,
        .memoryWriteValue,
        .memoryWriteDone,
        .uartRx,
        .clk,
        .rst
    );

    always_comb begin
        clk = CLOCK_50;
        rst = ~KEY[0];
        uartRx = GPIO_0[0];

        LEDR[9:0] = totalMemoryWriteSize[9:0];

        memoryWriteDone = memoryWriteEnable;
    end
endmodule
