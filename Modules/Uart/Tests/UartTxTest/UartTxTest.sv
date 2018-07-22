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

module UartTxTest;
    // Constant parameter
    parameter MAX_CYCLE = 10000;
    parameter HALF_CYCLE_TIME = 5;
    parameter ONE_CYCLE_TIME = HALF_CYCLE_TIME * 2;
    parameter RESET_TIME = ONE_CYCLE_TIME * 2;

    localparam BaudRate = 115200;
    localparam ClockFrequency = 1 * 1000 * 1000;

    // Wires
    logic uartTx;
    logic clk;
    logic rst;

    UartTxTestUnit #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency)
    ) m_UartTxTestUnit (
        .uartTx,
        .clk,
        .rst
    );

    // rst
    initial begin
        $display("Reset asserted.");
        rst = 1;
        #RESET_TIME;
        #HALF_CYCLE_TIME;
        $display("Reset deasserted.");
        rst = 0;
    end

    // clk
    initial begin
        clk = 0;

        for (int i = 0; i < MAX_CYCLE; i++) begin
            clk = 1;
            #HALF_CYCLE_TIME;
            clk = 0;
            #HALF_CYCLE_TIME;
        end

        // Test not finished.
        $display("Test not finished. You should increase test cycle count.");
        assert(0);
    end
endmodule
