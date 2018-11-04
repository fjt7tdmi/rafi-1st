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
import ProcessorTypes::*;
import TlbTypes::*;

module FetchUnit (
    FetchUnitIF.FetchUnit bus,
    BusAccessUnitIF.FetchUnit mem,
    PipelineControllerIF.FetchUnit ctrl,
    ControlStatusRegisterIF.FetchUnit csr,
    input logic clk,
    input logic rst
);
    parameter LineSize = ICacheLineSize;
    parameter LineWidth = ICacheLineWidth;
    parameter IndexWidth = ICacheIndexWidth;
    parameter TagWidth = ICacheTagWidth;

    parameter IndexLsb = $clog2(LineSize);
    parameter IndexMsb = IndexLsb + IndexWidth - 1;
    parameter TagLsb = IndexLsb + IndexWidth;
    parameter TagMsb = PhysicalAddrWidth - 1;

    // Wait 2-cycle after pipeline flush
    parameter StallCycleAfterFlush = 2;

    typedef logic [TagWidth-1:0] _tag_t;
    typedef logic [IndexWidth-1:0] _index_t;
    typedef logic [LineWidth-1:0] _line_t;
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
    State r_State;
    addr_t r_Pc;
    paddr_t r_PhysicalPc;
    logic r_ICacheRead;
    logic r_TlbMiss;
    logic r_Fault;
    _stall_cycle_t r_StallCounter;

    // Wires
    State nextState;
    addr_t nextPc;
    paddr_t nextPhysicalPc;
    logic nextICacheRead;
    logic nextTlbMiss;
    logic nextFault;
    _stall_cycle_t nextStallCounter;

    logic cacheMiss;
    logic stall;

    _index_t            validTagArrayIndex;
    ValidTagArrayEntry  validTagArrayReadValue;
    ValidTagArrayEntry  validTagArrayWriteValue;
    logic               validTagArrayWriteEnable;

    _index_t                dataArrayIndex;
    logic [LineWidth-1:0]   dataArrayReadValue;
    logic [LineWidth-1:0]   dataArrayWriteValue;
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
        .DataWidth($bits(ValidTagArrayEntry)),
        .IndexWidth(IndexWidth)
    ) m_ValidTagArray (
        .readValue(validTagArrayReadValue),
        .index(validTagArrayIndex),
        .writeValue(validTagArrayWriteValue),
        .writeEnable(validTagArrayWriteEnable),
        .clk,
        .rst
    );

    BlockRam #(
        .DataWidth(LineWidth),
        .IndexWidth(IndexWidth)
    ) m_DataArray (
        .readValue(dataArrayReadValue),
        .index(dataArrayIndex),
        .writeValue(dataArrayWriteValue),
        .writeEnable(dataArrayWriteEnable),
        .clk
    );

    Tlb #(
        .TlbIndexWidth(ITlbIndexWidth)
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
        .csrSum(csr.mstatus.sum_),
        .csrMxr(csr.mstatus.mxr),
        .invalidate(tlbInvalidate),
        .clk,
        .rst
    );

    ICacheInvalidater #(
        .LineSize(LineSize),
        .IndexWidth(IndexWidth),
        .TagWidth(TagWidth)
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
        .LineWidth(LineWidth),
        .TagWidth(TagWidth),
        .IndexWidth(IndexWidth)
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
        .memReadDone(mem.icReadGrant),
        .memReadValue(mem.icReadValue),
        .miss(cacheMiss),
        .done(cacheReplacerDone),
        .enable(cacheReplacerEnable),
        .missAddr(r_PhysicalPc[PhysicalAddrWidth-1:IndexLsb]),
        .clk,
        .rst
    );

    TlbReplacer #(
        .MemAddrWidth(ICacheMemAddrWidth),
        .LineWidth(ICacheLineWidth)
    ) m_TlbReplacer (
        .tlbWriteEnable,
        .tlbWriteKey,
        .tlbWriteValue,
        .memAddr(tlbReplacerMemAddr),
        .memReadEnable(tlbReplacerMemReadEnable),
        .memReadDone(mem.icReadGrant),
        .memReadValue(mem.icReadValue),
        .memWriteEnable(mem.icWriteReq),
        .memWriteDone(mem.icWriteGrant),
        .memWriteValue(mem.icWriteValue),
        .csrSatp(csr.satp),
        .done(tlbReplacerDone),
        .enable(tlbReplacerEnable),
        .missMemoryAccessType(MemoryAccessType_Instruction),
        .missPage(r_Pc[VirtualAddrWidth-1:PageOffsetWidth]),
        .clk,
        .rst
    );

    // Wires
    always_comb begin
        tlbReadKey = nextPc[VirtualAddrWidth-1:PageOffsetWidth];
    end

    always_comb begin
        // Wires
        cacheMiss = r_ICacheRead && !r_TlbMiss &&
            (!validTagArrayReadValue.valid || r_PhysicalPc[TagMsb:TagLsb] != validTagArrayReadValue.tag);
        stall = ctrl.ifStall || (r_StallCounter != '0);

        // Module port
        bus.valid = (r_ICacheRead && !r_TlbMiss && !cacheMiss) || r_Fault;
        bus.fault = r_Fault;
        bus.pc = r_Pc;
        bus.iCacheLine = dataArrayReadValue;

        if (r_State == State_ReplaceTlb) begin
            mem.icAddr = tlbReplacerMemAddr;
            mem.icReadReq = tlbReplacerMemReadEnable;
        end
        else begin
            mem.icAddr = cacheReplacerMemAddr;
            mem.icReadReq = cacheReplacerMemReadEnable;
        end

        // Valid & tag array input signals
        unique case (r_State)
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
            validTagArrayIndex = nextPhysicalPc[IndexMsb:IndexLsb];
            validTagArrayWriteValue = '0;
            validTagArrayWriteEnable = 0;
        end
        endcase

        // Data array input signals
        if (r_State == State_ReplaceCache) begin
            dataArrayIndex = cacheReplacerArrayIndex;
            dataArrayWriteEnable = cacheReplacerArrayWriteEnable;
        end
        else begin
            dataArrayIndex = nextPhysicalPc[IndexMsb:IndexLsb];
            dataArrayWriteEnable = 0;
        end

        // Module enable signals
        tlbReadEnable = (r_State == State_Default);
        invalidaterEnable = (r_State == State_Invalidate);
        cacheReplacerEnable = (r_State == State_ReplaceCache);
        tlbReplacerEnable = (r_State == State_ReplaceTlb);
    end

    // nextPc
    always_comb begin
        if (csr.trapInfo.valid || csr.trapReturn) begin
            nextPc = csr.nextPc;
        end
        else if (ctrl.flush) begin
            nextPc = ctrl.nextPc;
        end
        else if (stall || !bus.valid || r_State != State_Default) begin
            nextPc = r_Pc;
        end
        else begin
            nextPc = r_Pc + InsnSize;
        end
    end

    // nextState
    always_comb begin
        unique case (r_State)
        State_Invalidate: begin
            if (invalidaterDone && !waitInvalidate) begin
                nextState = State_Default;
            end
            else begin
                nextState = State_Invalidate;
            end
        end
        State_ReplaceCache: begin
            if (!cacheReplacerDone) begin
                nextState = State_ReplaceCache;
            end
            else if (waitInvalidate) begin
                nextState = State_Invalidate;
            end
            else begin
                nextState = State_Default;
            end
        end
        State_ReplaceTlb: begin
            if (!tlbReplacerDone) begin
                nextState = State_ReplaceTlb;
            end
            else if (waitInvalidate) begin
                nextState = State_Invalidate;
            end
            else begin
                nextState = State_Default;
            end
        end
        default: begin
            if (waitInvalidate) begin
                nextState = State_Invalidate;
            end
            else if (r_TlbMiss) begin
                nextState = State_ReplaceTlb;
            end
            else if (cacheMiss) begin
                nextState = State_ReplaceCache;
            end
            else begin
                nextState = State_Default;
            end
        end
        endcase
    end

    // Next register values
    always_comb begin
        nextPhysicalPc = {tlbReadValue, nextPc[PageOffsetWidth-1:0]};
        nextICacheRead = (r_State == State_Default && !ctrl.flush && !stall && !waitInvalidate);
        nextTlbMiss = nextICacheRead && !tlbHit;
        nextFault = nextICacheRead && tlbHit && tlbFault;

        if (ctrl.flush) begin
            nextStallCounter = StallCycleAfterFlush;
        end
        else begin
            nextStallCounter = (r_StallCounter != '0) ? r_StallCounter - 1 : '0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_State <= State_Default;
            r_Pc <= InitialProgramCounter;
            r_PhysicalPc <= '0;
            r_ICacheRead <= '0;
            r_TlbMiss <= '0;
            r_Fault <= '0;
            r_StallCounter <= '0;
        end
        else begin
            r_State <= nextState;
            r_Pc <= nextPc;
            r_PhysicalPc <= nextPhysicalPc;
            r_ICacheRead <= nextICacheRead;
            r_TlbMiss <= nextTlbMiss;
            r_Fault <= nextFault;
            r_StallCounter <= nextStallCounter;
        end
    end
endmodule
