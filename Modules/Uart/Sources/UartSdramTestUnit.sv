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

module UartSdramTestUnit #(
    parameter SdramAddrWidth,
    parameter SdramBankWidth,
    parameter SdramDataWidth,
    parameter BaudRate,
    parameter ClockFrequency,
    parameter UartLoadSize
)(
    // Signals for sdram
    output  logic sdramWriteReq,
    input   logic sdramWriteAck,
    input   logic sdramWriteDataEnable,
    output  logic [SdramAddrWidth-1:0] sdramWriteAddr,
    output  logic [SdramDataWidth-1:0] sdramWriteData,
    output  logic sdramReadReq,
    input   logic sdramReadAck,
    output  logic [SdramAddrWidth-1:0] sdramReadAddr,
    input   logic sdramReadDataEnable,
    input   logic [SdramDataWidth-1:0] sdramReadData,

    // debug
    output  int32_t debugValue,

    // uart
    output  logic uartTx,
    input   logic uartRx,

    // clk & rst
    input   logic clk,
    input   logic rst
);
    // Params
    localparam LineSize = 16;
    localparam LineWidth = LineSize * ByteWidth;

    localparam MemoryCapacity = (SdramDataWidth / ByteWidth) << (SdramAddrWidth + SdramBankWidth);
    localparam MemoryAddrMsb = $clog2(MemoryCapacity) - 1;
    localparam MemoryAddrLsb = $clog2(LineSize);
    localparam MemoryAddrWidth = MemoryAddrMsb - MemoryAddrLsb + 1;
    
    // Types
    typedef logic [MemoryAddrWidth-1:0] _memory_addr_t;
    typedef logic [LineWidth-1:0] _line_t;

    typedef enum logic
    {
        State_Rx = 1'b0,
        State_Tx = 1'b1
    } State;

    // Regs
    State   reg_State;
    int32_t reg_TxCount;

    // Wires
    State   next_State;
    int32_t next_TxCount;

    logic   memoryDone;
    _line_t memoryReadValue;

    _memory_addr_t memoryAddr;
    logic   memoryEnable;

    int32_t totalMemoryWriteSize;
    logic   memoryWriteEnable;
    _line_t memoryWriteValue;

    int8_t [LineSize-1:0] memoryReadBytes;
    logic [MemoryAddrLsb-1:0] indexForUartTxWriteValue;

    logic   uartTxEmpty;
    logic   uartTxWriteEnable;
    int8_t  uartTxWriteValue;

    SdramController #(
        .UserAddrWidth(MemoryAddrWidth),
        .UserLineSize(LineSize),
        .MemoryAddrWidth(SdramAddrWidth),
        .MemoryDataWidth(SdramDataWidth)
    ) m_SdramController (
        .memoryWriteReq(sdramWriteReq),
        .memoryWriteAck(sdramWriteAck),
        .memoryWriteDataEnable(sdramWriteDataEnable),
        .memoryWriteAddr(sdramWriteAddr),
        .memoryWriteData(sdramWriteData),
        .memoryReadReq(sdramReadReq),
        .memoryReadAck(sdramReadAck),
        .memoryReadAddr(sdramReadAddr),
        .memoryReadDataEnable(sdramReadDataEnable),
        .memoryReadData(sdramReadData),
        .userDone(memoryDone),
        .userReadValue(memoryReadValue),
        .userAddr(memoryAddr),
        .userEnable(memoryEnable),
        .userIsWrite(reg_State == State_Rx),
        .userWriteValue(memoryWriteValue),
        .clk,
        .rst
    );

    UartInput #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency),
        .LineSize(LineSize)
    ) m_UartInput (
        .totalMemoryWriteSize,
        .memoryWriteEnable,
        .memoryWriteValue,
        .memoryWriteDone(memoryDone),
        .uartRx,
        .clk,
        .rst
    );

    UartTx #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency)
    ) m_UartTx (
        .uartTx,
        .empty(uartTxEmpty),
        .writeEnable(uartTxWriteEnable),
        .writeValue(uartTxWriteValue),
        .clk,
        .rst
    );

    always_comb begin
        //debugValue = totalMemoryWriteSize;
        debugValue[31:3] = '0;
        debugValue[0] = reg_State;
        debugValue[1] = memoryWriteEnable;
        debugValue[2] = memoryDone;

        if (reg_State == State_Rx) begin
            memoryAddr = totalMemoryWriteSize[MemoryAddrMsb:MemoryAddrLsb];
            memoryEnable = memoryWriteEnable;

            next_State = (totalMemoryWriteSize == UartLoadSize) ? State_Tx : State_Rx;
            next_TxCount = reg_TxCount;
        end
        else begin
            memoryAddr = reg_TxCount[MemoryAddrMsb:MemoryAddrLsb];
            memoryEnable = uartTxEmpty;

            next_State = State_Tx;
            if (memoryEnable && memoryDone) begin
                next_TxCount = (reg_TxCount == UartLoadSize - 1) ? '0 : reg_TxCount + 1;
            end
            else begin
                next_TxCount = reg_TxCount;
            end
        end

        memoryReadBytes = memoryReadValue;
        indexForUartTxWriteValue = reg_TxCount[MemoryAddrLsb-1:0];

        uartTxWriteEnable = (reg_State == State_Tx) && memoryDone;
        uartTxWriteValue = memoryReadBytes[indexForUartTxWriteValue];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_State <= State_Rx;
            reg_TxCount <= '0;
        end
        else begin
            reg_State <= next_State;
            reg_TxCount <= next_TxCount;
        end
    end
endmodule
