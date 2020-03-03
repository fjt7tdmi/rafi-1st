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
    input ReplaceLogicCommand command,
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
    State reg_state;
    _line_t reg_line;

    // Wires
    State next_state;
    _line_t next_line;

    // Cache array access
    always_comb begin
        arrayWriteEnable = (reg_state == State_Invalidate) || (reg_state == State_WriteCache);
        arrayIndex = makeIndex(commandAddr);
        arrayWriteValid = (reg_state == State_Invalidate) ? 0 : 1;
        arrayWriteTag = makeTag(commandAddr);
        arrayWriteData = reg_line;
    end

    // Memory accses
    always_comb begin
        memAddr = commandAddr;
        memReadEnable = (reg_state == State_ReadMemory);
        memWriteEnable = (reg_state == State_WriteMemory);
        memWriteValue = reg_line;
    end

    // Control
    always_comb begin
        done = (reg_state == State_WriteMemory && memWriteDone) ||
            (reg_state == State_WriteCache) ||
            (reg_state == State_Invalidate);
    end

    // Wires
    always_comb begin
        unique case (reg_state)
        State_None: begin
            if (enable && command == ReplaceLogicCommand_WriteThrough) begin
                next_state = State_ReadCache;
            end
            else if (enable && command == ReplaceLogicCommand_Replace) begin
                next_state = State_InvalidateForReplace;
            end
            else if (enable && command == ReplaceLogicCommand_Invalidate) begin
                next_state = State_Invalidate;
            end
            else begin
                next_state = reg_state;
            end
        end
        State_ReadCache: begin
            next_state = State_WriteMemory;
        end
        State_WriteMemory: begin
            next_state = (memWriteDone) ? State_None : reg_state;
        end
        State_InvalidateForReplace: begin
            next_state = State_ReadMemory;
        end
        State_ReadMemory: begin
            next_state = (memReadDone) ? State_WriteCache : reg_state;
        end
        State_WriteCache: begin
            next_state = State_None;
        end
        State_Invalidate: begin
            next_state = State_None;
        end
        default: begin
            next_state = State_None;
        end
        endcase

        unique case (reg_state)
        State_ReadCache: begin
            next_line = arrayReadData;
        end
        State_ReadMemory: begin
            next_line = memReadValue;
        end
        default: begin
            next_line = reg_line;
        end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_None;
            reg_line <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_line <= next_line;
        end
    end
endmodule
