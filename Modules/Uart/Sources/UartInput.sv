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

module UartInput #(
    parameter BaudRate,
    parameter ClockFrequency,
    parameter LineSize,
    parameter LineWidth = LineSize * ByteWidth
)(
    output  logic   [3:0] state,
    output  int32_t totalMemoryWriteSize,
    output  logic   memoryWriteEnable,
    output  logic   [LineWidth-1:0] memoryWriteValue,
    input   logic   memoryWriteDone,
    input   logic   uartRx,
    input   logic   clk,
    input   logic   rst
);
    // localparam
    localparam UartCycleLength = ClockFrequency / BaudRate;
    localparam HoldLength = UartCycleLength / 2; // cycle count to watch start bi
    localparam CycleCountWidth = $clog2(UartCycleLength + 1);

    typedef enum logic [2:0]
    {
        State_None              = 3'h0,
        State_ReceiveStartBit   = 3'h1,
        State_ReceiveData       = 3'h2,
        State_ReceiveStopBit    = 3'h3,
        State_WriteMemory       = 3'h4,
        State_ClearBuffer       = 3'h5
    } State;

    typedef logic [LineWidth-1:0] _line_t;

    // Functions
    function automatic _line_t makeNextLineBuffer(_line_t line, logic writeValue, logic [$clog2(LineWidth)-1:0] index);
        _line_t ret = line;
        ret[index] = writeValue;
        return ret;
    endfunction

    // Registers
    State r_State;
    logic [CycleCountWidth-1:0] r_CycleCount;
    logic [$clog2(ByteWidth)-1:0] r_BitCount;
    logic [$clog2(LineSize)-1:0] r_ByteCount;
    _line_t r_LineBuffer;
    int32_t r_TotalMemoryWriteSize;

    // Wires
    State nextState;
    logic [CycleCountWidth-1:0] nextCycleCount;
    logic [$clog2(ByteWidth):0] nextBitCount;
    logic [$clog2(LineSize):0] nextByteCount;
    _line_t nextLineBuffer;
    int32_t nextTotalMemoryWriteSize;

    always_comb begin
        state = {1'b0, r_State};
        
        // module port
        totalMemoryWriteSize = r_TotalMemoryWriteSize;
        memoryWriteEnable = (r_State == State_WriteMemory);
        memoryWriteValue = r_LineBuffer;

        // State
        unique case (r_State)
        State_ReceiveStartBit: begin
            if (uartRx == 1) begin
                nextState = State_None;
            end
            else if (r_CycleCount == HoldLength) begin
                nextState = State_ReceiveData;
            end
            else begin
                nextState = r_State;
            end
        end
        State_ReceiveData: begin
            nextState = (r_BitCount == ByteWidth - 1 && r_CycleCount == UartCycleLength)
                ? State_ReceiveStopBit
                : r_State;
        end
        State_ReceiveStopBit: begin
            if (r_CycleCount == UartCycleLength) begin
                nextState = (r_ByteCount == LineSize - 1) ? State_WriteMemory : State_None;
            end
            else begin
                nextState = r_State;
            end
        end
        State_WriteMemory: begin
            nextState = memoryWriteDone ? State_ClearBuffer : r_State;
        end
        State_ClearBuffer: begin
            nextState = State_None;
        end
        default: begin
            // State_None
            nextState = (uartRx == 0)
                ? State_ReceiveStartBit
                : r_State;
        end
        endcase

        // CycleCount
        if ((r_State == State_ReceiveStartBit && r_CycleCount != HoldLength) ||
            (r_State == State_ReceiveData && r_CycleCount != UartCycleLength) ||
            (r_State == State_ReceiveStopBit && r_CycleCount != UartCycleLength)) begin
            nextCycleCount = r_CycleCount + 1;
        end
        else begin
            nextCycleCount = '0;
        end

        // BitCount
        if (r_State == State_ClearBuffer) begin
            nextBitCount = '0;
        end
        else if (r_State == State_ReceiveData && r_CycleCount == UartCycleLength) begin
            nextBitCount = r_BitCount + 1;
        end
        else begin
            nextBitCount = r_BitCount;
        end

        // ByteCount
        if (r_State == State_ClearBuffer) begin
            nextByteCount = '0;
        end
        else if (r_State == State_ReceiveStopBit && r_CycleCount == UartCycleLength) begin
            nextByteCount = r_ByteCount + 1;
        end
        else begin
            nextByteCount = r_ByteCount;
        end

        // LineBuffer
        if (r_State == State_ClearBuffer) begin
            nextLineBuffer = '0;
        end
        else if (r_State == State_ReceiveData && r_CycleCount == UartCycleLength) begin
            nextLineBuffer = makeNextLineBuffer(r_LineBuffer, uartRx, {r_ByteCount, r_BitCount});
        end
        else begin
            nextLineBuffer = r_LineBuffer;
        end

        // TotalMemoryWriteSize
        nextTotalMemoryWriteSize = (r_State == State_ClearBuffer)
            ? r_TotalMemoryWriteSize + LineSize
            : r_TotalMemoryWriteSize;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_State <= State_None;
            r_CycleCount <= '0;
            r_BitCount <= '0;
            r_ByteCount <= '0;
            r_LineBuffer <= '0;
            r_TotalMemoryWriteSize <= '0;
        end
        else begin
            r_State <= nextState;
            r_CycleCount <= nextCycleCount;
            r_BitCount <= nextBitCount;
            r_ByteCount <= nextByteCount;
            r_LineBuffer <= nextLineBuffer;
            r_TotalMemoryWriteSize <= nextTotalMemoryWriteSize;
        end
    end
endmodule
