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

import MemoryTypes::*;

module SystemWithInternalMemory #(
    parameter BaudRate,
    parameter ClockFrequency,
    parameter MemoryCapacity,
    parameter MemoryLineSize
)(
    output  logic   uartTx,
    output  int32_t debugValue,
    output  int32_t hostIoValue,
    input   int32_t uartLoadSize,
    input   logic uartRx,
    input   logic clk,
    input   logic rst
);
    // parameters
    localparam CoreAddrWidth = PhysicalAddrWidth - $clog2(MemoryLineSize);
    localparam InternalMemoryAddrWidth = $clog2(MemoryCapacity) - $clog2(MemoryLineSize);
    localparam MemoryLineWidth = MemoryLineSize * ByteWidth;

    // Types
    typedef logic [CoreAddrWidth-1:0] _core_addr_t;
    typedef logic [InternalMemoryAddrWidth-1:0] _internal_memory_addr_t;

    typedef enum logic
    {
        State_Load = 1'b0,
        State_Main = 1'b1
    } State;

    // Functions
    function automatic _core_addr_t getCoreAddr(paddr_t physicalAddr);
        return physicalAddr[$clog2(MemoryLineSize) + CoreAddrWidth - 1 : $clog2(MemoryLineSize)];
    endfunction


    // Registers
    State r_State;
    logic r_CoreReset;

    // Wires
    logic [InternalMemoryAddrWidth-1:0] memoryAddr;
    logic memoryDone;
    logic memoryEnable;
    logic memoryIsWrite;
    logic [MemoryLineWidth-1:0] memoryReadValue;
    logic [MemoryLineWidth-1:0] memoryWriteValue;

    logic [CoreAddrWidth-1:0] coreAddr;
    logic coreDone;
    logic coreEnable;
    logic coreIsWrite;
    logic [MemoryLineWidth-1:0] coreReadValue;
    logic [MemoryLineWidth-1:0] coreWriteValue;

    logic uartInputWriteEnable;
    logic [MemoryLineWidth-1:0] uartInputWriteValue;

    int32_t uartTotalMemoryWriteSize;

    logic uartTxEmpty;
    logic uartTxWriteEnable;
    int8_t uartTxWriteValue;

    State next_State;
    logic next_CoreReset;

    Core #(
        .MemoryAddrWidth(CoreAddrWidth),
        .MemoryLineWidth(MemoryLineWidth)
    ) m_Core (
        .hostIoValue(hostIoValue),
        .memoryAddr(coreAddr),
        .memoryDone(coreDone),
        .memoryEnable(coreEnable),
        .memoryIsWrite(coreIsWrite),
        .memoryReadValue(coreReadValue),
        .memoryWriteValue(coreWriteValue),
        .clk,
        .rstIn(r_CoreReset)
    );

    InternalMemory #(
        .Capacity(MemoryCapacity),
        .LineSize(MemoryLineSize)
    ) m_Memory (
        .addr(memoryAddr),
        .done(memoryDone),
        .enable(memoryEnable),
        .isWrite(memoryIsWrite),
        .readValue(memoryReadValue),
        .writeValue(memoryWriteValue),
        .clk,
        .rst
    );

    UartInput  #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency),
        .LineSize(MemoryLineSize)
    ) m_UartInput (
        .totalMemoryWriteSize(uartTotalMemoryWriteSize),
        .memoryWriteEnable(uartInputWriteEnable),
        .memoryWriteValue(uartInputWriteValue),
        .memoryWriteDone(memoryDone),
        .uartRx,
        .clk,
        .rst
    );

    UartTx #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency)
    ) m_UartTx (
        .empty(uartTxEmpty),
        .uartTx(uartTx),
        .writeEnable(uartTxWriteEnable),
        .writeValue(uartTxWriteValue),
        .clk,
        .rst
    );

    always_comb begin
        next_State = (uartTotalMemoryWriteSize >= uartLoadSize) ? State_Main : r_State;

        if (r_CoreReset) begin
            next_CoreReset = (r_State == State_Main) ? 1'b0 : 1'b1;
        end
        else begin
            next_CoreReset = 0;
        end

        debugValue[31:26] = '0;
        debugValue[25] = r_State;
        debugValue[24] = r_CoreReset;
        //debugValue[23:0] = uartTotalMemoryWriteSize[23:0];
        debugValue[23:0] = hostIoValue[23:0];

        if (r_State == State_Load) begin
            memoryAddr = uartTotalMemoryWriteSize[$clog2(MemoryCapacity) - 1 : $clog2(MemoryLineSize)];
            memoryEnable = uartInputWriteEnable;
            memoryIsWrite = 1;
            memoryWriteValue = uartInputWriteValue;

            coreDone = 0;
            coreReadValue = '0;

            uartTxWriteEnable = 0;
        end
        else begin
            memoryAddr = coreAddr[InternalMemoryAddrWidth - 1 : 0];
            memoryIsWrite = coreIsWrite;
            memoryWriteValue = coreWriteValue;

            // TODO: avoid using comparator
            if (coreAddr == getCoreAddr(UartAddr)) begin
                coreDone = 1;
                coreReadValue = '0;

                memoryEnable = 0;
                uartTxWriteEnable = coreEnable && coreIsWrite;
            end
            else if (getCoreAddr(MemoryAddrBegin) <= coreAddr && coreAddr < getCoreAddr(MemoryAddrEnd)) begin
                coreDone = memoryDone;
                coreReadValue = memoryReadValue;

                memoryEnable = coreEnable;
                uartTxWriteEnable = 0;
            end
            else begin
                coreDone = 1; // TORIAEZU
                coreReadValue = '0;

                memoryEnable = 0;
                uartTxWriteEnable = 0;
            end
        end

        uartTxWriteValue = coreWriteValue[ByteWidth-1:0];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_State <= State_Load;
            r_CoreReset <= 1;
        end
        else begin
            r_State <= next_State;
            r_CoreReset <= next_CoreReset;
        end
    end
endmodule