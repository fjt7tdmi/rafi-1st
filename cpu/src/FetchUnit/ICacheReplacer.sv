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
    parameter LineWidth,
    parameter TagWidth,
    parameter IndexWidth,
    parameter MemAddrWidth = TagWidth + IndexWidth
)(
    // Cache array access
    output logic arrayWriteEnable,
    output logic [IndexWidth-1:0] arrayIndex,
    output logic arrayWriteValid,
    output logic [TagWidth-1:0] arrayWriteTag,
    output logic [LineWidth-1:0] arrayWriteData,
    input logic arrayReadValid,
    input logic [TagWidth-1:0] arrayReadTag,

    // Memory access
    output logic [MemAddrWidth-1:0] memAddr,
    output logic memReadEnable,
    input logic memReadDone,
    input logic [LineWidth-1:0] memReadValue,

    // Control
    output logic done,
    input logic enable,
    input logic miss,
    input logic [MemAddrWidth-1:0] missAddr,

    // clk & rst
    input logic clk,
    input logic rst
);
    // Internal types
    typedef logic [MemAddrWidth-1:0] _mem_addr_t;
    typedef logic [TagWidth-1:0] _tag_t;
    typedef logic [IndexWidth-1:0] _index_t;
    typedef logic [LineWidth-1:0] _line_t;

    typedef enum logic [1:0]
    {
        State_None = 2'h0,
        State_InvalidateCache = 2'h1,
        State_ReadMemory = 2'h2,
        State_WriteCache = 2'h3
    } State;

    // Internal functions
    function automatic _mem_addr_t makeAddr(_tag_t tag, _index_t index);
        return {tag, index};
    endfunction

    function automatic _tag_t makeTag(_mem_addr_t addr);
        return addr[MemAddrWidth-1:IndexWidth];
    endfunction

    function automatic _index_t makeIndex(_mem_addr_t addr);
        return addr[IndexWidth-1:0];
    endfunction

    // Registers
    State r_State;
    _line_t r_Line;
    _mem_addr_t r_MissAddr;

    // Wires
    State nextState;
    _line_t nextLine;

    always_comb begin
        // Cache array access
        arrayWriteEnable = (r_State == State_WriteCache);
        arrayIndex = makeIndex(r_MissAddr);
        arrayWriteValid = 1;
        arrayWriteTag = makeTag(r_MissAddr);
        arrayWriteData = r_Line;

        // Memory accses
        memAddr = r_MissAddr;
        memReadEnable = (r_State == State_ReadMemory);

        // Control
        done = (r_State == State_WriteCache);

        // Wires
        unique case (r_State)
        State_None: begin
            nextState = (enable) ? State_InvalidateCache : r_State;
        end
        State_InvalidateCache: begin
            nextState = State_ReadMemory;
        end
        State_ReadMemory: begin
            nextState = (memReadDone) ? State_WriteCache : r_State;
        end
        State_WriteCache: begin
            nextState = State_None;
        end
        default: begin
            nextState = State_None;
        end
        endcase

        nextLine = (r_State == State_ReadMemory && memReadDone)
            ? memReadValue
            : r_Line;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_State <= State_None;
            r_Line <= '0;
            r_MissAddr <= '0;
        end
        else begin
            r_State <= nextState;
            r_Line <= nextLine;
            r_MissAddr <= miss ? missAddr : r_MissAddr;
        end
    end
endmodule
