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

module UartSdramTest;
    // Constant parameter
    parameter MAX_CYCLE = 20000;
    parameter HALF_CYCLE_TIME = 5;
    parameter ONE_CYCLE_TIME = HALF_CYCLE_TIME * 2;
    parameter RESET_TIME = ONE_CYCLE_TIME * 2;

    localparam BaudRate = 1000 * 1000;
    localparam ClockFrequency = 20 * 1000 * 1000;
    localparam TestDataSize = 32;

    localparam SdramAddrWidth = 10;
    localparam SdramBankWidth = 3;
    localparam SdramDataWidth = 16;

    int32_t debugValue;

    logic clk;
    logic rst;

    logic   uartSdramTestUnitOut;
    logic   uartSdramTestUnitIn;

    logic   uartTxEmpty;
    logic   uartTxWriteEnable;
    int8_t  uartTxWriteValue;

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

    UartSdramTestUnit #(
        .SdramAddrWidth(SdramAddrWidth),
        .SdramBankWidth(SdramBankWidth),
        .SdramDataWidth(SdramDataWidth),
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency),
        .UartLoadSize(TestDataSize)
    ) m_UartSdramTestUnit (
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
        .debugValue,

        // uart
        .uartTx(uartSdramTestUnitOut),
        .uartRx(uartSdramTestUnitIn),

        // clk & rst
        .clk,
        .rst
    );

    UartTx #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency)
    ) m_UartTx (
        .uartTx(uartSdramTestUnitIn),
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
        for (int8_t i = 8'h00; i < TestDataSize; i++) begin
            UartTxWrite(i);
        end

        assert(m_Sdram.body[0] == 16'h0100);
        assert(m_Sdram.body[1] == 16'h0302);
        assert(m_Sdram.body[2] == 16'h0504);
        assert(m_Sdram.body[3] == 16'h0706);
        assert(m_Sdram.body[4] == 16'h0908);
        assert(m_Sdram.body[5] == 16'h0b0a);
        assert(m_Sdram.body[6] == 16'h0d0c);
        assert(m_Sdram.body[7] == 16'h0f0e);
        assert(m_Sdram.body[8] == 16'h1110);
        assert(m_Sdram.body[9] == 16'h1312);
        assert(m_Sdram.body[10] == 16'h1514);
        assert(m_Sdram.body[11] == 16'h1716);
        assert(m_Sdram.body[12] == 16'h1918);
        assert(m_Sdram.body[13] == 16'h1b1a);
        assert(m_Sdram.body[14] == 16'h1d1c);
        assert(m_Sdram.body[15] == 16'h1f1e);
    end
endmodule