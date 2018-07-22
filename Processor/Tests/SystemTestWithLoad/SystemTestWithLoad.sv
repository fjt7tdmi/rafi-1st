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

import CacheTypes::*;
import MemoryTypes::*;

timeunit 1ns;
timeprecision 100ps;

module SystemTestWithLoad;
    // Command line arguments
    parameter INITIAL_MEMORY_PATH;
    parameter MEMORY_DUMP_DIR;
    parameter TRACE_PATH;
    parameter ENABLE_DUMP_MEMORY;
    parameter ENABLE_FINISH;
    
    // Constant parameter
    parameter BAUD_RATE = 115200;
    parameter CLOCK_FREQUENCY = 20 * 1000 * 1000;
    parameter MEMORY_LINE_SIZE = 2;
    parameter UART_LOAD_SIZE = 64;

    parameter SIMULATION_CYCLE = 200000;
    parameter HALF_CYCLE_TIME = 5;
    parameter ONE_CYCLE_TIME = HALF_CYCLE_TIME * 2;

    localparam LINE_COUNT = UART_LOAD_SIZE / MEMORY_LINE_SIZE;

    parameter SdramAddrWidth = 16;

    localparam SdramBankWidth = 3;
    localparam SdramDataWidth = 16;

    // Types
    typedef logic [MEMORY_LINE_SIZE*ByteWidth-1:0] _line_t;

    // Wires
    int32_t hostIoValue;

    logic   clk;
    logic   rst;

    logic sdramWriteReq;
    logic sdramWriteAck;
    logic sdramWriteDataEnable;
    logic [SdramAddrWidth-1:0] sdramWriteAddr;
    logic [SdramDataWidth-1:0] sdramWriteData;
    logic sdramReadReq;
    logic sdramReadAck;
    logic [SdramAddrWidth-1:0] sdramReadAddr;
    logic sdramReadDataEnable;
    logic [SdramDataWidth-1:0] sdramReadData;

    logic   uart;
    logic   uartTxEmpty;
    logic   uartTxWriteEnable;
    int8_t  uartTxWriteValue;

    // Modules
    InternalSdram #(
        .AddrWidth(SdramAddrWidth),
        .DataWidth(SdramDataWidth)
    ) m_Sdram (
        .writeReq(sdramWriteReq),
        .writeAck(sdramWriteAck),
        .writeDataEnable(sdramWriteDataEnable),
        .writeAddr(sdramWriteAddr),
        .writeData(sdramWriteData),
        .readReq(sdramReadReq),
        .readAck(sdramReadAck),
        .readAddr(sdramReadAddr),
        .readDataEnable(sdramReadDataEnable),
        .readData(sdramReadData),
        .clk,
        .rst
    );

    System #(
        .SdramAddrWidth(SdramAddrWidth),
        .SdramBankWidth(SdramBankWidth),
        .SdramDataWidth(SdramDataWidth),
        .BaudRate(BAUD_RATE),
        .ClockFrequency(CLOCK_FREQUENCY)
    ) m_Top (
        // sdram
        .sdramWriteReq,
        .sdramWriteAck,
        .sdramWriteDataEnable,
        .sdramWriteAddr,
        .sdramWriteData,
        .sdramReadReq,
        .sdramReadAck,
        .sdramReadAddr,
        .sdramReadDataEnable,
        .sdramReadData,

        // debug
        .hostIoValue(hostIoValue),
        .debugIn('0),

        // uart
        .uartLoadSize(UART_LOAD_SIZE),
        .uartRx(uart),

        // clk & rst
        .clk,
        .rst
    );

    UartTx #(
        .BaudRate(BAUD_RATE),
        .ClockFrequency(CLOCK_FREQUENCY)
    ) m_UartTx (
        .uartTx(uart),
        .empty(uartTxEmpty),
        .writeEnable(uartTxWriteEnable),
        .writeValue(uartTxWriteValue),
        .clk,
        .rst
    );

    // init Memory
    _line_t lines[LINE_COUNT];
    int8_t [MEMORY_LINE_SIZE-1:0] line;

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
    endtask

    // Reset & Load binary
    initial begin
        // Reset
        $display("Reset asserted.");
        rst = 1;
        #ONE_CYCLE_TIME;
        #HALF_CYCLE_TIME;
        $display("Reset deasserted.");
        rst = 0;

        // Init Memory
        for (int i = 0; i < m_Sdram.BodyEntryCount; i++) begin
            m_Sdram.body[i] = '0;
        end

        // Load binary
        $readmemh(INITIAL_MEMORY_PATH, lines);

        for (int i = 0; i < LINE_COUNT; i++) begin
            line = lines[i];

            for (int j = 0; j < MEMORY_LINE_SIZE; j++) begin
                UartTxWrite(line[j]);
            end
        end

        $display("UART load completed.");
    end

    // clk
    initial begin
        clk = 0;

        for (int cycle = 0; cycle < SIMULATION_CYCLE; cycle++) begin
            clk = 1;
            #HALF_CYCLE_TIME;
            clk = 0;
            #HALF_CYCLE_TIME;
        end

        if (ENABLE_FINISH) begin
            $finish;        
        end
        else begin
            $break;
        end
    end
endmodule