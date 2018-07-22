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

module UartMemoryTestUnit #(
    parameter BaudRate,
    parameter ClockFrequency,
    parameter LineSize,
    parameter MemoryCapacity
)(
    output  int32_t debugValue,
    output  logic uartTx,
    input   logic uartRx,
    input   logic clk,
    input   logic rst
);
    // Params
    localparam LineWidth = LineSize * ByteWidth;

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

    // Modules
    InternalMemory #(
        .Capacity(MemoryCapacity),
        .LineSize(LineSize)
    ) m_Memory (
        .done(memoryDone),
        .readValue(memoryReadValue),
        .addr(memoryAddr),
        .enable(memoryEnable),
        .isWrite(reg_State == State_Rx),
        .writeValue(memoryWriteValue),
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
        debugValue = totalMemoryWriteSize;

        if (reg_State == State_Rx) begin
            memoryAddr = totalMemoryWriteSize[MemoryAddrMsb:MemoryAddrLsb];
            memoryEnable = memoryWriteEnable;

            next_State = (totalMemoryWriteSize == MemoryCapacity) ? State_Tx : State_Rx;
            next_TxCount = reg_TxCount;
        end
        else begin
            memoryAddr = reg_TxCount[MemoryAddrMsb:MemoryAddrLsb];
            memoryEnable = uartTxEmpty;

            next_State = State_Tx;
            next_TxCount = (memoryEnable && memoryDone) ? reg_TxCount + 1 : reg_TxCount;
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
