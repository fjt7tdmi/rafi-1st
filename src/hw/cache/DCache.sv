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

module DCache #(
    parameter LINE_SIZE = 8,
    parameter TAG_WIDTH = 24,
    parameter INDEX_WIDTH = 5,
    parameter LINE_WIDTH = LINE_SIZE * BYTE_WIDTH,
    parameter MEM_ADDR_WIDTH = TAG_WIDTH + INDEX_WIDTH
)(
    // for Core
    output logic done,
    output logic storeConditionalFailure,
    output logic [LINE_WIDTH-1:0] readValue,
    input logic enable,
    input DCacheCommand command,
    input logic [LINE_SIZE-1:0] writeMask,
    input logic [LINE_WIDTH-1:0] writeValue,
    input paddr_t addr,

    // for Memory
    output paddr_t memAddr,
    output logic memReadEnable,
    output logic memWriteEnable,
    output logic [LINE_WIDTH-1:0] memWriteValue,
    input logic memReadDone,
    input logic memWriteDone,
    input logic [LINE_WIDTH-1:0] memReadValue,

    // clk & rst
    input logic clk,
    input logic rst
);
    localparam OFFSET_WIDTH = $clog2(LINE_SIZE);

    // Internal types
    typedef logic [TAG_WIDTH-1:0] _tag_t;
    typedef logic [INDEX_WIDTH-1:0] _index_t;
    typedef logic [LINE_WIDTH-1:0] _line_t;

    typedef enum logic [2:0]
    {
        State_Initial       = 3'h0,
        State_ReadCache     = 3'h1,
        State_Invalidate    = 3'h2,
        State_ReadMemory    = 3'h3,
        State_WriteCache    = 3'h4,
        State_Store         = 3'h5,
        State_WriteMemory   = 3'h6
    } State;

    typedef struct packed
    {
        logic valid;
        logic reserved;
        _tag_t tag;
    } TagArrayEntry;

    // Internal functions
    function automatic paddr_t MakeAddr(_tag_t tag, _index_t index);
        paddr_t addr;

        addr[TAG_WIDTH + INDEX_WIDTH + OFFSET_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH] = tag;
        addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH] = index;
        addr[OFFSET_WIDTH - 1 : 0] = '0;

        return addr;
    endfunction

    function automatic _tag_t MakeTag(paddr_t addr);
        return addr[TAG_WIDTH + INDEX_WIDTH + OFFSET_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH];
    endfunction

    function automatic _index_t MakeIndex(paddr_t addr);
        return addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    endfunction

    function automatic _line_t MakeLineWithWriteMask(logic [LINE_SIZE-1:0][BYTE_WIDTH-1:0] value, logic [LINE_SIZE-1:0][BYTE_WIDTH-1:0] writeValue, logic [LINE_SIZE-1:0] writeMask);
        logic [LINE_SIZE-1:0][BYTE_WIDTH-1:0] line;

        for (int i = 0; i < LINE_SIZE; i++) begin
            line[i] = writeMask[i] ? writeValue[i] : value[i];
        end

        return line;
    endfunction

    // Registers
    State reg_state;
    _line_t reg_line;

    State next_state;
    _line_t next_line;

    // Tag Array
    logic [INDEX_WIDTH-1:0] tagArrayIndex;
    TagArrayEntry           tagArrayReadValue;
    TagArrayEntry           tagArrayWriteValue;
    logic                   tagArrayWriteEnable;

    BlockRamWithReset #(
        .DATA_WIDTH($bits(TagArrayEntry)),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) tagArray (
        .readValue(tagArrayReadValue),
        .index(tagArrayIndex),
        .writeValue(tagArrayWriteValue),
        .writeEnable(tagArrayWriteEnable),
        .clk,
        .rst);

    // Data Array
    logic [INDEX_WIDTH-1:0] dataArrayIndex;
    logic [LINE_WIDTH-1:0]  dataArrayReadValue;
    logic [LINE_WIDTH-1:0]  dataArrayWriteValue;
    logic [LINE_SIZE-1:0]   dataArrayWriteMask;

    MultiBankBlockRam #(
        .DATA_WIDTH_PER_BANK(BYTE_WIDTH),
        .BANK_COUNT(LINE_SIZE),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) dataArray (
        .readValue(dataArrayReadValue),
        .index(dataArrayIndex),
        .writeValue(dataArrayWriteValue),
        .writeMask(dataArrayWriteMask),
        .clk);

    // Cache Hit
    logic hit;
    always_comb begin
        hit = tagArrayReadValue.valid && MakeTag(addr) == tagArrayReadValue.tag;
    end

    // Array input signals
    always_comb begin
        tagArrayIndex = MakeIndex(addr);

        if (reg_state == State_ReadCache && hit && command == DCacheCommand_LoadReserved) begin            
            tagArrayWriteEnable = 1;
            tagArrayWriteValue.valid = 1;
            tagArrayWriteValue.reserved = 1; // Set 'reserved' field.
        end
        else if (reg_state == State_Invalidate) begin
            tagArrayWriteEnable = 1;
            tagArrayWriteValue.valid = 0;
            tagArrayWriteValue.reserved = 0;
        end
        else if (reg_state == State_WriteCache && command == DCacheCommand_LoadReserved) begin            
            tagArrayWriteEnable = 1;
            tagArrayWriteValue.valid = 1;
            tagArrayWriteValue.reserved = 1; // Set 'reserved' field.
        end
        else if (reg_state == State_WriteCache) begin
            tagArrayWriteEnable = 1;
            tagArrayWriteValue.valid = 1;
            tagArrayWriteValue.reserved = 0;
        end
        else if (reg_state == State_Store) begin            
            tagArrayWriteEnable = 1;
            tagArrayWriteValue.valid = 1;
            tagArrayWriteValue.reserved = 0; // Reset 'reserved' field.
        end
        else begin
            tagArrayWriteEnable = 0;
            tagArrayWriteValue.valid = 0;
            tagArrayWriteValue.reserved = 0;
        end

        tagArrayWriteValue.tag = MakeTag(addr);

        dataArrayIndex = MakeIndex(addr);

        unique case (reg_state)
        State_WriteCache: begin
            dataArrayWriteMask = '1;
            dataArrayWriteValue = reg_line;
        end
        State_Store: begin
            dataArrayWriteMask = writeMask;
            dataArrayWriteValue = writeValue;
        end
        default: begin
            dataArrayWriteMask = '0;
            dataArrayWriteValue = '0;
        end
        endcase
    end

    // Module IF
    always_comb begin
        storeConditionalFailure =
            (command == DCacheCommand_StoreConditional) &&
            (reg_state == State_ReadCache) &&
            (!hit || !tagArrayReadValue.reserved);

        unique case (command)
        DCacheCommand_Load:             done = (reg_state == State_ReadCache && hit) || (reg_state == State_WriteCache);
        DCacheCommand_LoadReserved:     done = (reg_state == State_ReadCache && hit) || (reg_state == State_WriteCache);
        DCacheCommand_Store:            done = (reg_state == State_WriteMemory && memWriteDone);
        DCacheCommand_StoreConditional: done = (reg_state == State_WriteMemory && memWriteDone) || storeConditionalFailure;
        DCacheCommand_Invalidate:       done = (reg_state == State_Invalidate);
        default:                        done = 0;
        endcase

        readValue = (reg_state == State_ReadCache) ? dataArrayReadValue : reg_line;

        memAddr = addr;
        memReadEnable = (reg_state == State_ReadMemory);
        memWriteEnable = (reg_state == State_WriteMemory);
        memWriteValue = reg_line;
    end

    // next_state
    always_comb begin
        unique case (reg_state)
        State_Initial: begin
            if (enable && command == DCacheCommand_Invalidate) begin
                next_state = State_Invalidate;
            end
            else if (enable) begin
                next_state = State_ReadCache;
            end
            else begin
                next_state = reg_state;
            end
        end
        State_ReadCache: begin
            if (storeConditionalFailure) begin
                next_state = State_Initial;
            end
            else if (hit && command inside {DCacheCommand_Load, DCacheCommand_LoadReserved}) begin
                next_state = State_Initial;
            end
            else if (hit && command inside {DCacheCommand_Store, DCacheCommand_StoreConditional}) begin
                next_state = State_Store;
            end
            else begin
                next_state = State_Invalidate;
            end
        end
        State_Invalidate: begin
            next_state = (command == DCacheCommand_Invalidate) ? State_Initial : State_ReadMemory;
        end
        State_ReadMemory: begin
            next_state = (memReadDone) ? State_WriteCache : reg_state;
        end
        State_WriteCache: begin
            next_state = (command inside {DCacheCommand_Store, DCacheCommand_StoreConditional}) ? State_Store : State_Initial;
        end
        State_Store: begin
            next_state = State_WriteMemory;
        end
        State_WriteMemory: begin
            next_state = (memWriteDone) ? State_Initial : reg_state;
        end
        default: begin
            next_state = State_Initial;
        end
        endcase

        unique case (reg_state)
        State_ReadCache: begin
            next_line = dataArrayReadValue;
        end
        State_ReadMemory: begin
            next_line = memReadValue;
        end
        State_WriteCache: begin
            next_line = MakeLineWithWriteMask(reg_line, writeValue, writeMask);
        end
        State_Store: begin
            next_line = MakeLineWithWriteMask(reg_line, writeValue, writeMask);
        end
        default: begin
            next_line = reg_line;
        end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_Initial;
            reg_line <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_line <= next_line;
        end
    end
endmodule
