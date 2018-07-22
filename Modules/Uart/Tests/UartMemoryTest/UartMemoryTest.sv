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

timeunit 1ns;
timeprecision 100ps;

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

module UartMemoryTest;
    // Constant parameter
    parameter MAX_CYCLE = 10000;
    parameter HALF_CYCLE_TIME = 5;
    parameter ONE_CYCLE_TIME = HALF_CYCLE_TIME * 2;
    parameter RESET_TIME = ONE_CYCLE_TIME * 2;

    localparam BaudRate = 115200;
    localparam ClockFrequency = 1 * 1000 * 1000;
    localparam LineSize = 4;
    localparam MemoryCapacity = 32;

    localparam LineWidth = LineSize * ByteWidth;

    typedef logic [LineWidth-1:0] _line_t;

    int32_t debugValue;

    logic clk;
    logic rst;

    logic   uartMemoryTestUnitOut;
    logic   uartMemoryTestUnitIn;

    logic   uartTxEmpty;
    logic   uartTxWriteEnable;
    int8_t  uartTxWriteValue;

    UartMemoryTestUnit #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency),
        .LineSize(LineSize),
        .MemoryCapacity(MemoryCapacity)
    ) m_UartMemoryTestUnit (
        .debugValue,
        .uartTx(uartMemoryTestUnitOut),
        .uartRx(uartMemoryTestUnitIn),
        .clk,
        .rst
    );

    UartTx #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency)
    ) m_UartTx (
        .uartTx(uartMemoryTestUnitIn),
        .empty(uartTxEmpty),
        .writeEnable(uartTxWriteEnable),
        .writeValue(uartTxWriteValue),
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

    // Write to UART
    task UartTxWrite(int8_t value);
        #1;
        assert(uartTxEmpty);

        uartTxWriteEnable = 1;
        uartTxWriteValue = value;
        @(posedge clk); #1;

        while (!uartTxEmpty) begin
            @(posedge clk); #1;
        end

        uartTxWriteEnable = 0;
    endtask

    // test
    initial begin
        uartTxWriteEnable = 0;
        uartTxWriteValue = '0;

        while (rst) @(posedge clk);

        // Sequential access
        for (int8_t i = 8'h00; i < MemoryCapacity; i++) begin
            UartTxWrite(i);
        end

        assert(m_UartMemoryTestUnit.m_Memory.body[0] == 32'h03020100);
        assert(m_UartMemoryTestUnit.m_Memory.body[1] == 32'h07060504);
        assert(m_UartMemoryTestUnit.m_Memory.body[2] == 32'h0b0a0908);
        assert(m_UartMemoryTestUnit.m_Memory.body[3] == 32'h0f0e0d0c);
        assert(m_UartMemoryTestUnit.m_Memory.body[4] == 32'h13121110);
        assert(m_UartMemoryTestUnit.m_Memory.body[5] == 32'h17161514);
        assert(m_UartMemoryTestUnit.m_Memory.body[6] == 32'h1b1a1918);
        assert(m_UartMemoryTestUnit.m_Memory.body[7] == 32'h1f1e1d1c);
    end
endmodule