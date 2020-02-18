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

module DCacheReplacer #(
    parameter LINE_WIDTH,
    parameter TAG_WIDTH,
    parameter INDEX_WIDTH,
    parameter MEM_ADDR_WIDTH = TAG_WIDTH + INDEX_WIDTH
)(
    // Cache array access
    output logic arrayWriteEnable,
    output logic [INDEX_WIDTH-1:0] arrayIndex,
    output logic arrayWriteValid,
    output logic [TAG_WIDTH-1:0] arrayWriteTag,
    output logic [LINE_WIDTH-1:0] arrayWriteData,
    input logic arrayReadValid,
    input logic [TAG_WIDTH-1:0] arrayReadTag,
    input logic [LINE_WIDTH-1:0] arrayReadData,

    // Memory access
    output logic [MEM_ADDR_WIDTH-1:0] memAddr,
    output logic memReadEnable,
    output logic memWriteEnable,
    output logic [LINE_WIDTH-1:0] memWriteValue,
    input logic memReadDone,
    input logic memWriteDone,
    input logic [LINE_WIDTH-1:0] memReadValue,

    // Control
    output logic done,
    input logic enable,
    input CacheCommand command,
    input logic [MEM_ADDR_WIDTH-1:0] commandAddr,

    // clk & rst
    input logic clk,
    input logic rst
);
    // Internal types
    typedef logic [MEM_ADDR_WIDTH-1:0] _mem_addr_t;
    typedef logic [TAG_WIDTH-1:0] _tag_t;
    typedef logic [INDEX_WIDTH-1:0] _index_t;
    typedef logic [LINE_WIDTH-1:0] _line_t;

    typedef enum logic [2:0]
    {
        State_None = 3'h0,
        State_ReadCache = 3'h1,
        State_WriteMemory = 3'h2,
        State_InvalidateForReplace = 3'h3,
        State_ReadMemory = 3'h4,
        State_WriteCache = 3'h5,
        State_Invalidate = 3'h6
    } State;

    // Internal functions
    function automatic _mem_addr_t makeAddr(_tag_t tag, _index_t index);
        return {tag, index};
    endfunction

    function automatic _tag_t makeTag(_mem_addr_t addr);
        return addr[MEM_ADDR_WIDTH-1:INDEX_WIDTH];
    endfunction

    function automatic _index_t makeIndex(_mem_addr_t addr);
        return addr[INDEX_WIDTH-1:0];
    endfunction

    // Registers
    State r_State;
    _line_t r_Line;

    // Wires
    State nextState;
    _line_t nextLine;

    // Cache array access
    always_comb begin
        arrayWriteEnable = (r_State == State_Invalidate) || (r_State == State_WriteCache);
        arrayIndex = makeIndex(commandAddr);
        arrayWriteValid = (r_State == State_Invalidate) ? 0 : 1;
        arrayWriteTag = makeTag(commandAddr);
        arrayWriteData = r_Line;
    end

    // Memory accses
    always_comb begin
        memAddr = commandAddr;
        memReadEnable = (r_State == State_ReadMemory);
        memWriteEnable = (r_State == State_WriteMemory);
        memWriteValue = r_Line;
    end

    // Control
    always_comb begin
        done = (r_State == State_WriteMemory && memWriteDone) ||
            (r_State == State_WriteCache) ||
            (r_State == State_Invalidate);
    end

    // Wires
    always_comb begin
        unique case (r_State)
        State_None: begin
            if (enable && command == CacheCommand_WriteThrough) begin
                nextState = State_ReadCache;
            end
            else if (enable && command == CacheCommand_Replace) begin
                nextState = State_InvalidateForReplace;
            end
            else if (enable && command == CacheCommand_Invalidate) begin
                nextState = State_Invalidate;
            end
            else begin
                nextState = r_State;
            end
        end
        State_ReadCache: begin
            nextState = State_WriteMemory;
        end
        State_WriteMemory: begin
            nextState = (memWriteDone) ? State_None : r_State;
        end
        State_InvalidateForReplace: begin
            nextState = State_ReadMemory;
        end
        State_ReadMemory: begin
            nextState = (memReadDone) ? State_WriteCache : r_State;
        end
        State_WriteCache: begin
            nextState = State_None;
        end
        State_Invalidate: begin
            nextState = State_None;
        end
        default: begin
            nextState = State_None;
        end
        endcase

        unique case (r_State)
        State_ReadCache: begin
            nextLine = arrayReadData;
        end
        State_ReadMemory: begin
            nextLine = memReadValue;
        end
        default: begin
            nextLine = r_Line;
        end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_State <= State_None;
            r_Line <= '0;
        end
        else begin
            r_State <= nextState;
            r_Line <= nextLine;
        end
    end
endmodule
