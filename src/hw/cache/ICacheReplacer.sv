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

module ICacheReplacer #(
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

    // Memory access
    output logic [MEM_ADDR_WIDTH-1:0] memAddr,
    output logic memReadEnable,
    input logic memReadDone,
    input logic [LINE_WIDTH-1:0] memReadValue,

    // Control
    output logic done,
    input logic enable,
    input logic miss,
    input logic [MEM_ADDR_WIDTH-1:0] missAddr,

    // clk & rst
    input logic clk,
    input logic rst
);
    // Internal types
    typedef logic [MEM_ADDR_WIDTH-1:0] _mem_addr_t;
    typedef logic [TAG_WIDTH-1:0] _tag_t;
    typedef logic [INDEX_WIDTH-1:0] _index_t;
    typedef logic [LINE_WIDTH-1:0] _line_t;

    typedef enum logic [1:0]
    {
        State_None = 2'h0,
        State_InvalidateCache = 2'h1,
        State_ReadMemory = 2'h2,
        State_WriteCache = 2'h3
    } State;

    // Internal functions
    function automatic _mem_addr_t MakeAddr(_tag_t tag, _index_t index);
        return {tag, index};
    endfunction

    function automatic _tag_t MakeTag(_mem_addr_t addr);
        return addr[MEM_ADDR_WIDTH-1:INDEX_WIDTH];
    endfunction

    function automatic _index_t MakeIndex(_mem_addr_t addr);
        return addr[INDEX_WIDTH-1:0];
    endfunction

    // Registers
    State reg_state;
    _line_t reg_line;
    _mem_addr_t reg_miss_addr;

    // Wires
    State next_state;
    _line_t next_line;

        // Cache array access
    always_comb begin
        arrayWriteEnable = (reg_state == State_WriteCache);
        arrayIndex = MakeIndex(reg_miss_addr);
        arrayWriteValid = 1;
        arrayWriteTag = MakeTag(reg_miss_addr);
        arrayWriteData = reg_line;
    end

    // Memory accses
    always_comb begin
        memAddr = reg_miss_addr;
        memReadEnable = (reg_state == State_ReadMemory);
    end

    // Control
    always_comb begin
        done = (reg_state == State_WriteCache);
    end

    // Wires
    always_comb begin
        unique case (reg_state)
        State_None: begin
            next_state = (enable) ? State_InvalidateCache : reg_state;
        end
        State_InvalidateCache: begin
            next_state = State_ReadMemory;
        end
        State_ReadMemory: begin
            next_state = (memReadDone) ? State_WriteCache : reg_state;
        end
        State_WriteCache: begin
            next_state = State_None;
        end
        default: begin
            next_state = State_None;
        end
        endcase

        next_line = (reg_state == State_ReadMemory && memReadDone)
            ? memReadValue
            : reg_line;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_None;
            reg_line <= '0;
            reg_miss_addr <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_line <= next_line;
            reg_miss_addr <= miss ? missAddr : reg_miss_addr;
        end
    end
endmodule
