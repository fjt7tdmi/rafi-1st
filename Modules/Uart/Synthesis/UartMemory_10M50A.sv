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

module UartMemory_10M50A(
    //Reset and Clocks
    input          fpga_resetn,
    input          clk_ddr3_100_p,
    input          clk_50_max10,
    input          clk_25_max10,
    input          clk_lvds_125_p,
    input          clk_10_adc,
    
    //LED PB DIPSW
    output  [4:0]  user_led,
    input   [3:0]  user_pb,
    input   [4:0]  user_dipsw,
    
    //UART
    input          uart_rx,
    output         uart_tx
);
    // localparams
    localparam BaudRate = 115200;
    localparam ClockFrequency = 50 * 1000 * 1000;

    // Wires
    logic clk;
    logic rst;
    int32_t debugValue;

    // Modules
    UartMemoryTestUnit #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency),
        .LineSize(4),
        .MemoryCapacity(32)
    ) m_UartTxTestUnit (
        .debugValue,
        .uartTx(uart_tx),
        .uartRx(uart_rx),
        .clk,
        .rst
    );

    always_comb begin
        clk = clk_50_max10;
        rst = ~fpga_resetn;

        if (debugValue >= 32) begin
            user_led = '0;
        end
        else begin
            user_led = ~debugValue[4:0];
        end
    end
endmodule
