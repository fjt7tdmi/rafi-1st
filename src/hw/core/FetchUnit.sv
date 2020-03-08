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

import RafiTypes::*;
import CacheTypes::*;

module FetchUnit (
    FetchUnitIF.FetchUnit bus,
    BusAccessUnitIF.FetchUnit mem,
    CsrIF.FetchUnit csr,
    input logic clk,
    input logic rst
);
    localparam LINE_SIZE = ICACHE_LINE_SIZE;
    localparam LINE_WIDTH = ICACHE_LINE_WIDTH;
    localparam INDEX_WIDTH = ICACHE_INDEX_WIDTH;
    localparam TAG_WIDTH = ICACHE_TAG_WIDTH;

    localparam INDEX_LSB = $clog2(LINE_SIZE);
    localparam INDEX_MSB = INDEX_LSB + INDEX_WIDTH - 1;
    localparam TAG_LSB = INDEX_LSB + INDEX_WIDTH;
    localparam TAG_MSB = PADDR_WIDTH - 1;

    // Wait 2-cycle after pipeline flush
    localparam StallCycleAfterFlush = 2;

    typedef logic [TAG_WIDTH-1:0] _tag_t;
    typedef logic [INDEX_WIDTH-1:0] _index_t;
    typedef logic [LINE_WIDTH-1:0] _line_t;
    typedef logic [$clog2(StallCycleAfterFlush):0] _stall_cycle_t;

    typedef enum logic [1:0]
    {
        State_Default = 2'h0,
        State_Invalidate = 2'h1,
        State_ReplaceCache = 2'h2,
        State_ReplaceTlb = 2'h3
    } State;

    typedef struct packed
    {
        logic valid;
        _tag_t tag;
    } ValidTagArrayEntry;

    // Registers
    State reg_state;
    vaddr_t reg_pc;
    paddr_t reg_physical_pc;
    logic reg_icache_read;
    logic reg_tlb_miss;
    logic reg_fault;
    _stall_cycle_t reg_stall_counter;

    // Wires
    State next_state;
    vaddr_t next_pc;
    paddr_t next_physical_pc;
    logic next_icache_read;
    logic next_tlb_miss;
    logic next_fault;
    _stall_cycle_t next_stall_counter;

    logic cacheMiss;
    logic stall;

    _index_t            validTagArrayIndex;
    ValidTagArrayEntry  validTagArrayReadValue;
    ValidTagArrayEntry  validTagArrayWriteValue;
    logic               validTagArrayWriteEnable;

    _index_t                dataArrayIndex;
    logic [LINE_WIDTH-1:0]   dataArrayReadValue;
    logic [LINE_WIDTH-1:0]   dataArrayWriteValue;
    logic                   dataArrayWriteEnable;

    logic                   tlbHit;
    logic                   tlbFault;
    virtual_page_number_t   tlbReadKey;
    physical_page_number_t  tlbReadValue;
    logic                   tlbReadEnable;
    logic                   tlbWriteEnable;
    virtual_page_number_t   tlbWriteKey;
    TlbEntry                tlbWriteValue;
    logic                   tlbInvalidate;

    logic       waitInvalidate;

    logic       invalidaterArrayWriteEnable;
    _index_t    invalidaterArrayIndex;
    logic       invalidaterArrayWriteValid;
    _tag_t      invalidaterArrayWriteTag;
    logic       invalidaterDone;
    logic       invalidaterEnable;

    logic               cacheReplacerArrayWriteEnable;
    _index_t            cacheReplacerArrayIndex;
    logic               cacheReplacerArrayWriteValid;
    _tag_t              cacheReplacerArrayWriteTag;
    icache_mem_addr_t   cacheReplacerMemAddr;
    logic               cacheReplacerMemReadEnable;
    logic               cacheReplacerDone;
    logic               cacheReplacerEnable;

    icache_mem_addr_t   tlbReplacerMemAddr;
    logic               tlbReplacerMemReadEnable;
    logic               tlbReplacerDone;
    logic               tlbReplacerEnable;

    // Modules
    BlockRamWithReset #(
        .DATA_WIDTH($bits(ValidTagArrayEntry)),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) m_ValidTagArray (
        .readValue(validTagArrayReadValue),
        .index(validTagArrayIndex),
        .writeValue(validTagArrayWriteValue),
        .writeEnable(validTagArrayWriteEnable),
        .clk,
        .rst
    );

    BlockRam #(
        .DATA_WIDTH(LINE_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) m_DataArray (
        .readValue(dataArrayReadValue),
        .index(dataArrayIndex),
        .writeValue(dataArrayWriteValue),
        .writeEnable(dataArrayWriteEnable),
        .clk
    );

    TlbArray #(
        .TLB_INDEX_WIDTH(ITLB_INDEX_WIDTH)
    ) m_Tlb (
        .hit(tlbHit),
        .fault(tlbFault),
        .readValue(tlbReadValue),
        .readEnable(tlbReadEnable),
        .readKey(tlbReadKey),
        .readAccessType(MemoryAccessType_Instruction),
        .writeEnable(tlbWriteEnable),
        .writeKey(tlbWriteKey),
        .writeValue(tlbWriteValue),
        .csrSatp(csr.satp),
        .csrPrivilege(csr.privilege),
        .csrSum(csr.status.SUM),
        .csrMxr(csr.status.MXR),
        .invalidate(tlbInvalidate),
        .clk,
        .rst
    );

    ICacheInvalidater #(
        .LINE_SIZE(LINE_SIZE),
        .INDEX_WIDTH(INDEX_WIDTH),
        .TAG_WIDTH(TAG_WIDTH)
    ) m_Invalidater (
        .arrayWriteEnable(invalidaterArrayWriteEnable),
        .arrayIndex(invalidaterArrayIndex),
        .arrayWriteValid(invalidaterArrayWriteValid),
        .arrayWriteTag(invalidaterArrayWriteTag),
        .tlbInvalidate,
        .done(invalidaterDone),
        .enable(invalidaterEnable),
        .waitInvalidate,
        .invalidateICacheReq(bus.invalidateICache),
        .invalidateTlbReq(bus.invalidateTlb),
        .clk,
        .rst
    );

    ICacheReplacer #(
        .LINE_WIDTH(LINE_WIDTH),
        .TAG_WIDTH(TAG_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) m_CacheReplacer (
        .arrayWriteEnable(cacheReplacerArrayWriteEnable),
        .arrayIndex(cacheReplacerArrayIndex),
        .arrayWriteValid(cacheReplacerArrayWriteValid),
        .arrayWriteTag(cacheReplacerArrayWriteTag),
        .arrayWriteData(dataArrayWriteValue),
        .arrayReadValid(validTagArrayReadValue.valid),
        .arrayReadTag(validTagArrayReadValue.tag),
        .memAddr(cacheReplacerMemAddr),
        .memReadEnable(cacheReplacerMemReadEnable),
        .memReadDone(mem.icacheReadGrant),
        .memReadValue(mem.icacheReadValue),
        .miss(cacheMiss),
        .done(cacheReplacerDone),
        .enable(cacheReplacerEnable),
        .missAddr(reg_physical_pc[PADDR_WIDTH-1:INDEX_LSB]),
        .clk,
        .rst
    );

    TlbReplacer #(
        .MEM_ADDR_WIDTH(ICACHE_MEM_ADDR_WIDTH),
        .LINE_WIDTH(ICACHE_LINE_WIDTH)
    ) m_TlbReplacer (
        .tlbWriteEnable,
        .tlbWriteKey,
        .tlbWriteValue,
        .memAddr(tlbReplacerMemAddr),
        .memReadEnable(tlbReplacerMemReadEnable),
        .memReadDone(mem.icacheReadGrant),
        .memReadValue(mem.icacheReadValue),
        .memWriteEnable(mem.icacheWriteReq),
        .memWriteDone(mem.icacheWriteGrant),
        .memWriteValue(mem.icacheWriteValue),
        .csrSatp(csr.satp),
        .done(tlbReplacerDone),
        .enable(tlbReplacerEnable),
        .missMemoryAccessType(MemoryAccessType_Instruction),
        .missPage(reg_pc[VADDR_WIDTH-1:PAGE_OFFSET_WIDTH]),
        .clk,
        .rst
    );

    // TODO: connect to new TLB
    always_comb begin
        mem.itlbAddr = '0;
        mem.itlbReadReq = '0;
        mem.itlbWriteReq = '0;
        mem.itlbWriteValue = '0;
    end

    // Wires
    always_comb begin
        tlbReadKey = next_pc[VADDR_WIDTH-1:PAGE_OFFSET_WIDTH];
    end

    always_comb begin
        // Wires
        cacheMiss = reg_icache_read && !reg_tlb_miss &&
            (!validTagArrayReadValue.valid || reg_physical_pc[TAG_MSB:TAG_LSB] != validTagArrayReadValue.tag);
        stall = bus.stall || (reg_stall_counter != '0);

        // Module port
        bus.valid = (reg_icache_read && !reg_tlb_miss && !cacheMiss) || reg_fault;
        bus.fault = reg_fault;
        bus.pc = reg_pc;
        bus.iCacheLine = dataArrayReadValue;

        if (reg_state == State_ReplaceTlb) begin
            mem.icacheAddr = tlbReplacerMemAddr;
            mem.icacheReadReq = tlbReplacerMemReadEnable;
        end
        else begin
            mem.icacheAddr = cacheReplacerMemAddr;
            mem.icacheReadReq = cacheReplacerMemReadEnable;
        end

        // Valid & tag array input signals
        unique case (reg_state)
        State_Invalidate: begin
            validTagArrayIndex = invalidaterArrayIndex;
            validTagArrayWriteValue = {invalidaterArrayWriteValid, invalidaterArrayWriteTag};
            validTagArrayWriteEnable = invalidaterArrayWriteEnable;
        end
        State_ReplaceCache: begin
            validTagArrayIndex = cacheReplacerArrayIndex;
            validTagArrayWriteValue = {cacheReplacerArrayWriteValid, cacheReplacerArrayWriteTag};
            validTagArrayWriteEnable = cacheReplacerArrayWriteEnable;
        end
        default: begin
            validTagArrayIndex = next_physical_pc[INDEX_MSB:INDEX_LSB];
            validTagArrayWriteValue = '0;
            validTagArrayWriteEnable = 0;
        end
        endcase

        // Data array input signals
        if (reg_state == State_ReplaceCache) begin
            dataArrayIndex = cacheReplacerArrayIndex;
            dataArrayWriteEnable = cacheReplacerArrayWriteEnable;
        end
        else begin
            dataArrayIndex = next_physical_pc[INDEX_MSB:INDEX_LSB];
            dataArrayWriteEnable = 0;
        end

        // Module enable signals
        tlbReadEnable = (reg_state == State_Default);
        invalidaterEnable = (reg_state == State_Invalidate);
        cacheReplacerEnable = (reg_state == State_ReplaceCache);
        tlbReplacerEnable = (reg_state == State_ReplaceTlb);
    end

    // next_pc
    always_comb begin
        if (bus.flush) begin
            next_pc = bus.nextPc;
        end
        else if (stall || !bus.valid || reg_state != State_Default) begin
            next_pc = reg_pc;
        end
        else begin
            next_pc = reg_pc + (reg_pc[1] ? 2 : 4);
        end
    end

    // next_state
    always_comb begin
        unique case (reg_state)
        State_Invalidate: begin
            if (invalidaterDone && !waitInvalidate) begin
                next_state = State_Default;
            end
            else begin
                next_state = State_Invalidate;
            end
        end
        State_ReplaceCache: begin
            if (!cacheReplacerDone) begin
                next_state = State_ReplaceCache;
            end
            else if (waitInvalidate) begin
                next_state = State_Invalidate;
            end
            else begin
                next_state = State_Default;
            end
        end
        State_ReplaceTlb: begin
            if (!tlbReplacerDone) begin
                next_state = State_ReplaceTlb;
            end
            else if (waitInvalidate) begin
                next_state = State_Invalidate;
            end
            else begin
                next_state = State_Default;
            end
        end
        default: begin
            if (waitInvalidate) begin
                next_state = State_Invalidate;
            end
            else if (reg_tlb_miss) begin
                next_state = State_ReplaceTlb;
            end
            else if (!reg_fault && cacheMiss) begin
                next_state = State_ReplaceCache;
            end
            else begin
                next_state = State_Default;
            end
        end
        endcase
    end

    // Next register values
    always_comb begin
        next_physical_pc = {tlbReadValue, next_pc[PAGE_OFFSET_WIDTH-1:0]};
        next_icache_read = (reg_state == State_Default && !bus.flush && !stall && !waitInvalidate);
        next_tlb_miss = next_icache_read && !tlbHit;
        next_fault = next_icache_read && tlbHit && tlbFault;

        if (bus.flush) begin
            next_stall_counter = StallCycleAfterFlush;
        end
        else begin
            next_stall_counter = (reg_stall_counter != '0) ? reg_stall_counter - 1 : '0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_Default;
            reg_pc <= INITIAL_PC;
            reg_physical_pc <= '0;
            reg_icache_read <= '0;
            reg_tlb_miss <= '0;
            reg_fault <= '0;
            reg_stall_counter <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_pc <= next_pc;
            reg_physical_pc <= next_physical_pc;
            reg_icache_read <= next_icache_read;
            reg_tlb_miss <= next_tlb_miss;
            reg_fault <= next_fault;
            reg_stall_counter <= next_stall_counter;
        end
    end
endmodule
