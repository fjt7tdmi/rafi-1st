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

module UartTx #(
    parameter BaudRate,
    parameter ClockFrequency
)(
    output  logic   empty,
    output  logic   uartTx,
    input   logic   writeEnable,
    input   int8_t  writeValue,
    input   logic   clk,
    input   logic   rst
);
    // localparam
    localparam UartCycleLength = ClockFrequency / BaudRate;
    localparam StopCycleLength = UartCycleLength * 2;
    localparam CycleCountWidth = $clog2(StopCycleLength + 1);

    typedef enum logic [2:0] {
        State_None          = 3'h0,
        State_SendStartBit  = 3'h1,
        State_SendData      = 3'h2,
        State_SendStopBit   = 3'h3,
        State_ClearBuffer   = 3'h4
    } State;

    // Registers
    State r_State;
    logic [CycleCountWidth-1:0] r_CycleCount;
    logic [$clog2(ByteWidth)-1:0] r_BitCount;
    int8_t r_Buffer;

    // Wires
    State nextState;
    logic [CycleCountWidth-1:0] nextCycleCount;
    logic [$clog2(ByteWidth):0] nextBitCount;
    int8_t nextBuffer;

    always_comb begin
        // module port
        empty = (r_State == State_None);

        unique case (r_State)
        State_SendStartBit:    uartTx = 0;
        State_SendData:        uartTx = r_Buffer[r_BitCount];
        default:               uartTx = 1;
        endcase

        // State
        unique case (r_State)
        State_SendStartBit: begin
            nextState = (r_CycleCount == UartCycleLength) ? State_SendData : r_State;
        end
        State_SendData: begin
            nextState = (r_BitCount == ByteWidth - 1 && r_CycleCount == UartCycleLength)
                ? State_SendStopBit
                : r_State;
        end
        State_SendStopBit: begin
            nextState = (r_CycleCount == StopCycleLength) ? State_ClearBuffer : r_State;
        end
        State_ClearBuffer: begin
            nextState = State_None;
        end
        default: begin
            // State_None
            nextState = writeEnable ? State_SendStartBit : r_State;
        end
        endcase

        // CycleCount
        if ((r_State == State_SendStartBit && r_CycleCount != UartCycleLength) ||
            (r_State == State_SendData && r_CycleCount != UartCycleLength) ||
            (r_State == State_SendStopBit && r_CycleCount != StopCycleLength)) begin
            nextCycleCount = r_CycleCount + 1;
        end
        else begin
            nextCycleCount = '0;
        end

        // BitCount
        if (r_State == State_ClearBuffer) begin
            nextBitCount = '0;
        end
        else if (r_State == State_SendData && r_CycleCount == UartCycleLength) begin
            nextBitCount = r_BitCount + 1;
        end
        else begin
            nextBitCount = r_BitCount;
        end

        // Buffer
        if (r_State == State_ClearBuffer) begin
            nextBuffer = '0;
        end
        else if (r_State == State_None && writeEnable) begin
            nextBuffer = writeValue;
        end
        else begin
            nextBuffer = r_Buffer;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_State <= State_None;
            r_CycleCount <= '0;
            r_BitCount <= '0;
            r_Buffer <= '0;
        end
        else begin
            r_State <= nextState;
            r_CycleCount <= nextCycleCount;
            r_BitCount <= nextBitCount;
            r_Buffer <= nextBuffer;
        end
    end
endmodule
