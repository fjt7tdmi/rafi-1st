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

module ICacheInvalidater #(
    parameter LINE_SIZE,
    parameter INDEX_WIDTH,
    parameter TAG_WIDTH
)(
    // Cache array access
    output logic arrayWriteEnable,
    output logic [INDEX_WIDTH-1:0] arrayIndex,
    output logic arrayWriteValid,
    output logic [TAG_WIDTH-1:0] arrayWriteTag,

    // TLB access
    output logic tlbInvalidate,

    // Control
    output logic waitInvalidate,
    output logic done,
    input logic enable,
    input logic invalidateICacheReq,
    input logic invalidateTlbReq,

    // clk & rst
    input logic clk,
    input logic rst
);
    localparam IndexLsb = $clog2(LINE_SIZE);
    localparam IndexMsb = IndexLsb + INDEX_WIDTH - 1;

    typedef logic [INDEX_WIDTH-1:0] _index_t;

    typedef enum logic
    {
        State_None = 1'h0,
        State_Invalidate = 1'h1
    } State;

    // Registers
    State reg_state;
    _index_t reg_index;

    logic reg_wait_icahce_invalidate;
    logic reg_wait_tlb_invalidate;

    logic reg_do_icahe_invalidate;
    logic reg_do_tlb_invalidate;

    // Wires
    State next_state;
    _index_t next_index;

    logic next_wait_icache_invalidate;
    logic next_wait_tlb_invalidate;

    logic next_do_icache_invalidate;
    logic next_do_tlb_invalidate;

    always_comb begin
        // Cache array access
        arrayWriteEnable = (reg_state == State_Invalidate);
        arrayIndex = reg_index;
        arrayWriteValid = reg_do_icahe_invalidate;
        arrayWriteTag = '0;

        // TLB access
        tlbInvalidate = reg_do_tlb_invalidate;

        // Wires
        if (reg_state == State_Invalidate) begin
            next_index = reg_index + 1;
            next_state = (next_index == '0) ? State_None : State_Invalidate;
        end
        else begin
            next_index = '0;
            next_state = enable ? State_Invalidate : State_None;
        end

        if (reg_state == State_None && next_state == State_Invalidate) begin
            next_wait_icache_invalidate = '0;
            next_wait_tlb_invalidate = '0;
        end
        else begin
            next_wait_icache_invalidate = reg_wait_icahce_invalidate || invalidateICacheReq;
            next_wait_tlb_invalidate = reg_wait_tlb_invalidate || invalidateTlbReq;
        end

        if (reg_state == State_None && next_state == State_Invalidate) begin
            next_do_icache_invalidate = reg_wait_icahce_invalidate || invalidateICacheReq;
            next_do_tlb_invalidate = reg_wait_tlb_invalidate || invalidateTlbReq;
        end
        else if (reg_state == State_Invalidate && next_state == State_None) begin
            next_do_icache_invalidate = '0;
            next_do_tlb_invalidate = '0;
        end
        else begin
            next_do_icache_invalidate = reg_do_icahe_invalidate;
            next_do_tlb_invalidate = reg_do_tlb_invalidate;
        end

        // Control
        waitInvalidate = reg_wait_icahce_invalidate || reg_wait_tlb_invalidate;
        done = (reg_state == State_Invalidate && next_state == State_None);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_None;
            reg_index <= '0;
            reg_wait_icahce_invalidate <= '0;
            reg_wait_tlb_invalidate <= '0;
            reg_do_icahe_invalidate <= '0;
            reg_do_tlb_invalidate <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_index <= next_index;
            reg_wait_icahce_invalidate <= next_wait_icache_invalidate;
            reg_wait_tlb_invalidate <= next_wait_tlb_invalidate;
            reg_do_icahe_invalidate <= next_do_icache_invalidate;
            reg_do_tlb_invalidate <= next_do_tlb_invalidate;
        end
    end
endmodule
