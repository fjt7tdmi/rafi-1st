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

module ICache #(
    parameter LINE_SIZE = 8,
    parameter TAG_WIDTH = 24,
    parameter INDEX_WIDTH = 5,
    parameter LINE_WIDTH = LINE_SIZE * BYTE_WIDTH
)(
    // for Memory
    output paddr_t memAddr,
    output logic memReadEnable,
    input logic memReadDone,
    input logic [LINE_WIDTH-1:0] memReadValue,

    // for NextStage
    output logic nextStageValid,
    output logic nextStageCacheMiss,
    output logic [LINE_WIDTH-1:0] nextStageReadValue,

    // for ICacheReadStage
    output logic stall,
    input logic fetchEnable,
    input paddr_t addr,

    // for FetchPipeController
    output logic invalidateDone,
    input logic invalidateEnable,

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
        State_None           = 3'h0,
        State_ReadMemory     = 3'h1,
        State_WriteCache     = 3'h2,
        State_FetchDone      = 3'h3,
        State_Invalidate     = 3'h4,
        State_InvalidateDone = 3'h5
    } State;

    typedef struct packed
    {
        logic valid;
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

    // Registers
    State reg_state;
    _line_t reg_line;
    logic reg_fetched;
    paddr_t reg_addr;
    _index_t reg_invalidate_index;

    State next_state;
    _line_t next_line;
    logic next_fetched;
    paddr_t next_addr;
    _index_t next_invalidate_index;

    // Tag Array
    _index_t      tagArrayIndex;
    TagArrayEntry tagArrayReadValue;
    TagArrayEntry tagArrayWriteValue;
    logic         tagArrayWriteEnable;

    BlockRamWithReset #(
        .DATA_WIDTH($bits(TagArrayEntry)),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) tagArray (
        .readValue(tagArrayReadValue),
        .index(tagArrayIndex),
        .writeValue(tagArrayWriteValue),
        .writeEnable(tagArrayWriteEnable),
        .clk,
        .rst
    );

    always_comb begin
        unique case (reg_state)
        State_Invalidate: begin
            tagArrayIndex = reg_invalidate_index;
            tagArrayWriteValue = '0;
            tagArrayWriteEnable = 1;
        end
        State_WriteCache: begin
            tagArrayIndex = MakeIndex(reg_addr);
            tagArrayWriteValue.valid = 1;
            tagArrayWriteValue.tag = MakeTag(reg_addr);
            tagArrayWriteEnable = 1;
        end
        default: begin
            tagArrayIndex = MakeIndex(addr);
            tagArrayWriteValue = '0;
            tagArrayWriteEnable = 0;
        end
        endcase
    end

    // Data Array
    _index_t               dataArrayIndex;
    logic [LINE_WIDTH-1:0] dataArrayReadValue;
    logic [LINE_WIDTH-1:0] dataArrayWriteValue;
    logic                  dataArrayWriteEnable;

    BlockRam #(
        .DATA_WIDTH(LINE_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) dataArray (
        .readValue(dataArrayReadValue),
        .index(dataArrayIndex),
        .writeValue(dataArrayWriteValue),
        .writeEnable(dataArrayWriteEnable),
        .clk
    );

    always_comb begin
        // Data array input signals
        if (reg_state == State_WriteCache) begin
            dataArrayIndex = MakeIndex(reg_addr);
            dataArrayWriteEnable = 1;
        end
        else begin
            dataArrayIndex = MakeIndex(addr);
            dataArrayWriteEnable = 0;
        end

        dataArrayWriteValue = reg_line;
    end

    // Hit / Miss
    logic hit;
    always_comb begin
        hit = tagArrayReadValue.valid && MakeTag(reg_addr) == tagArrayReadValue.tag;
    end

    // Module IF
    always_comb begin
        memAddr = reg_addr;
        memReadEnable = (reg_state == State_ReadMemory);

        nextStageValid = reg_fetched && hit;
        nextStageReadValue = dataArrayReadValue;
        nextStageCacheMiss = reg_fetched && !hit;

        stall = (reg_state != State_None) && !nextStageCacheMiss;

        invalidateDone = (reg_state == State_InvalidateDone);
    end

    // next_state, next_line, next_fetched, next_addr, next_invalidate_index
    always_comb begin
        unique case (reg_state)
        State_None: begin
            if (invalidateEnable) begin
                next_state = State_Invalidate;
            end
            else if (nextStageCacheMiss) begin
                next_state = State_ReadMemory;
            end
            else begin
                next_state = reg_state;
            end
        end
        State_Invalidate: begin
            next_state = (reg_invalidate_index == '1) ? State_InvalidateDone : reg_state;
        end
        State_ReadMemory: begin
            next_state = (memReadDone) ? State_WriteCache : reg_state;
        end
        State_WriteCache: begin
            next_state = State_FetchDone;
        end
        default: begin
            next_state = State_None;
        end
        endcase

        next_line = (reg_state == State_ReadMemory && memReadDone)
            ? memReadValue
            : reg_line;

        next_fetched = (reg_state == State_None) && fetchEnable;
        next_addr = (reg_state == State_None && !nextStageCacheMiss) ? addr : reg_addr;

        next_invalidate_index = (reg_state == State_Invalidate) ? reg_invalidate_index + 1 : '0;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_None;
            reg_line <= '0;
            reg_fetched <= '0;
            reg_addr <= '0;
            reg_invalidate_index <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_line <= next_line;
            reg_fetched <= next_fetched;
            reg_addr <= next_addr;
            reg_invalidate_index <= next_invalidate_index;
        end
    end
endmodule
