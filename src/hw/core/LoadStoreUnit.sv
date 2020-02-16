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
import MemoryTypes::*;
import OpTypes::*;
import LoadStoreUnitTypes::*;
import TlbTypes::*;

module LoadStoreUnit (
    LoadStoreUnitIF.LoadStoreUnit bus,
    BusAccessUnitIF.LoadStoreUnit mem,
    CsrIF.LoadStoreUnit csr,
    output  logic [31:0] hostIoValue,
    input   logic clk,
    input   logic rst
);
    parameter LineSize = DCacheLineSize;
    parameter LineWidth = DCacheLineWidth;
    parameter IndexWidth = DCacheIndexWidth;
    parameter TagWidth = DCacheTagWidth;

    parameter IndexLsb = $clog2(LineSize);
    parameter IndexMsb = IndexLsb + IndexWidth - 1;
    parameter TagLsb = IndexLsb + IndexWidth;
    parameter TagMsb = PhysicalAddrWidth - 1;

    typedef logic unsigned [TagWidth-1:0] _tag_t;
    typedef logic unsigned [IndexWidth-1:0] _index_t;
    typedef logic unsigned [LineWidth-1:0] _line_t;
    typedef logic unsigned [$clog2(LineSize)-1:0] _shift_amount_t;
    typedef logic unsigned [LineSize-1:0] _write_mask_t;

    typedef enum logic [2:0]
    {
        State_Default = 3'h0,
        State_Invalidate = 3'h1,
        State_ReplaceCache = 3'h2,
        State_ReplaceTlb = 3'h3,
        State_Load = 3'h4,
        State_Store = 3'h5,
        State_WriteThrough = 3'h6,
        State_Reserve = 3'h7
    } State;

    typedef struct packed
    {
        logic valid;
        logic reserved;
        _tag_t tag;
    } TagArrayEntry;

    // Functions
    function automatic uint64_t rightShift(_line_t value, _shift_amount_t shift);
        int8_t [LineSize-1:0] bytes;
        int8_t [7:0] shiftedBytes;

        bytes = value;

        for (int i = 0; i < 8; i++) begin
            /* verilator lint_off WIDTH */
            if (shift + i < LineSize) begin
                shiftedBytes[i] = bytes[shift + i];
            end
            else begin
                shiftedBytes[i] = '0;
            end
        end

        return shiftedBytes;
    endfunction

    function automatic _line_t leftShift(uint64_t value, _shift_amount_t shift);
        int8_t [7:0] bytes;
        int8_t [LineSize-1:0] shiftedBytes;

        bytes = value;

        for (int i = 0; i < LineSize; i++) begin
            if (shift <= i) begin
                shiftedBytes[i] = bytes[i - shift];
            end
            else begin
                shiftedBytes[i] = '0;
            end
        end

        return shiftedBytes;
    endfunction

    function automatic _write_mask_t makeWriteMask(_shift_amount_t shift, LoadStoreType loadStoreType);
        _write_mask_t mask;

        /* verilator lint_off WIDTH */
        if (loadStoreType inside {LoadStoreType_Byte, LoadStoreType_UnsignedByte}) begin
            mask = 8'b0000_0001;
        end
        else if (loadStoreType inside {LoadStoreType_HalfWord, LoadStoreType_UnsignedHalfWord}) begin
            mask = 8'b0000_0011;
        end
        else if (loadStoreType inside {LoadStoreType_Word, LoadStoreType_UnsignedWord}) begin
            mask = 8'b0000_1111;
        end
        else if (loadStoreType inside {LoadStoreType_DoubleWord}) begin
            mask = 8'b1111_1111;
        end
        else begin
            mask = '0;
        end

        return mask << shift;
    endfunction

    function automatic uint64_t extend(uint64_t value, LoadStoreType loadStoreType);
        unique case(loadStoreType)
        LoadStoreType_Byte: begin
            if (value[7]) begin
                return {56'hffff_ffff_ffff_ff, value[7:0]};
            end
            else begin
                return {56'h0000_0000_0000_00, value[7:0]};
            end
        end
        LoadStoreType_HalfWord: begin
            if (value[15]) begin
                return {48'hffff_ffff_ffff, value[15:0]};
            end
            else begin
                return {48'h0000_0000_0000, value[15:0]};
            end
        end
        LoadStoreType_Word: begin
            if (value[31]) begin
                return {32'hffff_ffff, value[31:0]};
            end
            else begin
                return {32'h0000_0000, value[31:0]};
            end
        end
        LoadStoreType_DoubleWord: begin
            return value;
        end
        LoadStoreType_UnsignedByte: begin
            return {56'h0000_0000_0000_00, value[7:0]};
        end
        LoadStoreType_UnsignedHalfWord: begin
            return {48'h0000_0000_0000, value[15:0]};
        end
        LoadStoreType_UnsignedWord: begin
            return {32'h0000_0000, value[31:0]};
        end
        default: return '0;
        endcase
    endfunction

    function automatic word_t atomicAlu(AtomicType atomicType, word_t regValue, word_t memValue);
        unique case(atomicType)
        AtomicType_Swap:    return regValue;
        AtomicType_Add:     return regValue + memValue;
        AtomicType_Xor:     return regValue ^ memValue;
        AtomicType_And:     return regValue & memValue;
        AtomicType_Or:      return regValue | memValue;
        AtomicType_Min:     return ($signed(regValue) < $signed(memValue)) ? regValue : memValue;
        AtomicType_Max:     return ($signed(regValue) > $signed(memValue)) ? regValue : memValue;
        AtomicType_Minu:    return ($unsigned(regValue) < $unsigned(memValue)) ? regValue : memValue;
        AtomicType_Maxu:    return ($unsigned(regValue) > $unsigned(memValue)) ? regValue : memValue;
        default: return '0;
        endcase
    endfunction

    // Registers
    State r_State;
    addr_t r_Addr;
    paddr_t r_PhysicalAddr;
    logic r_DCacheRead;
    logic r_TlbFault;
    logic r_TlbMiss;
    MemoryAccessType r_AccessType;
    LoadStoreType r_LoadStoreType;
    uint64_t r_LoadResult;
    uint64_t r_StoreRegValue;
    word_t r_HostIoValue; // special register for debug

    // Wires
    State nextState;
    addr_t nextAddr;
    paddr_t nextPhysicalAddr;
    logic nextDCacheRead;
    logic nextTlbFault;
    logic nextTlbMiss;
    MemoryAccessType nextAccessType;
    LoadStoreType nextLoadStoreType;
    uint64_t nextLoadResult;
    uint64_t nextStoreRegValue;
    word_t nextHostIoValue;

    MemoryAccessType accessType;
    logic cacheMiss;
    uint64_t shiftedReadData;
    CacheCommand command;
    dcache_mem_addr_t commandAddr;
    uint64_t loadResult;
    uint64_t storeValue;
    word_t storeAluValue;
    logic storeConditionFlag;

    _index_t        tagArrayIndex;
    TagArrayEntry   tagArrayReadValue;
    TagArrayEntry   tagArrayWriteValue;
    logic           tagArrayWriteEnable;

    _index_t                dataArrayIndex;
    logic [LineWidth-1:0]   dataArrayReadValue;
    logic [LineWidth-1:0]   dataArrayWriteValue;
    _write_mask_t           dataArrayWriteMask;

    logic                   tlbHit;
    logic                   tlbFault;
    physical_page_number_t  tlbReadValue;
    logic                   tlbReadEnable;
    logic                   tlbWriteEnable;
    virtual_page_number_t   tlbWriteKey;
    TlbEntry                tlbWriteValue;

    logic               cacheReplacerArrayWriteEnable;
    _index_t            cacheReplacerArrayIndex;
    logic               cacheReplacerArrayWriteValid;
    _tag_t              cacheReplacerArrayWriteTag;
    _line_t             cacheReplacerArrayWriteData;
    dcache_mem_addr_t   cacheReplacerMemAddr;
    logic               cacheReplacerMemReadEnable;
    logic               cacheReplacerMemWriteEnable;
    _line_t             cacheReplacerMemWriteValue;
    logic               cacheReplacerDone;
    logic               cacheReplacerEnable;

    dcache_mem_addr_t   tlbReplacerMemAddr;
    logic               tlbReplacerMemReadEnable;
    logic               tlbReplacerMemWriteEnable;
    _line_t             tlbReplacerMemWriteValue;
    logic               tlbReplacerDone;
    logic               tlbReplacerEnable;

    // Modules
    BlockRamWithReset #(
        .DataWidth($bits(TagArrayEntry)),
        .IndexWidth(IndexWidth)
    ) m_ValidTagArray (
        .readValue(tagArrayReadValue),
        .index(tagArrayIndex),
        .writeValue(tagArrayWriteValue),
        .writeEnable(tagArrayWriteEnable),
        .clk,
        .rst
    );

    MultiBankBlockRam #(
        .DataWidthPerBank(ByteWidth),
        .BankCount(LineSize),
        .IndexWidth(IndexWidth)
    ) m_DataArray (
        .readValue(dataArrayReadValue),
        .index(dataArrayIndex),
        .writeValue(dataArrayWriteValue),
        .writeMask(dataArrayWriteMask),
        .clk
    );

    Tlb #(
        .TlbIndexWidth(ITlbIndexWidth)
    ) m_Tlb (
        .hit(tlbHit),
        .fault(tlbFault),
        .readValue(tlbReadValue),
        .readEnable(tlbReadEnable),
        .readKey(nextAddr[VirtualAddrWidth-1:PageOffsetWidth]),
        .readAccessType(accessType),
        .writeEnable(tlbWriteEnable),
        .writeKey(tlbWriteKey),
        .writeValue(tlbWriteValue),
        .csrSatp(csr.satp),
        .csrPrivilege(csr.privilege),
        .csrSum(csr.mstatus.sum_),
        .csrMxr(csr.mstatus.mxr),
        .invalidate(bus.invalidateTlb),
        .clk,
        .rst
    );

    DCacheReplacer #(
        .LineWidth(LineWidth),
        .TagWidth(TagWidth),
        .IndexWidth(IndexWidth)
    ) m_CacheReplacer (
        .arrayWriteEnable(cacheReplacerArrayWriteEnable),
        .arrayIndex(cacheReplacerArrayIndex),
        .arrayWriteValid(cacheReplacerArrayWriteValid),
        .arrayWriteTag(cacheReplacerArrayWriteTag),
        .arrayWriteData(cacheReplacerArrayWriteData),
        .arrayReadValid(tagArrayReadValue.valid),
        .arrayReadTag(tagArrayReadValue.tag),
        .arrayReadData(dataArrayReadValue),
        .memAddr(cacheReplacerMemAddr),
        .memReadEnable(cacheReplacerMemReadEnable),
        .memReadDone(mem.dcReadGrant),
        .memReadValue(mem.dcReadValue),
        .memWriteEnable(cacheReplacerMemWriteEnable),
        .memWriteDone(mem.dcWriteGrant),
        .memWriteValue(cacheReplacerMemWriteValue),
        .done(cacheReplacerDone),
        .enable(cacheReplacerEnable),
        .command(command),
        .commandAddr(commandAddr),
        .clk,
        .rst
    );

    TlbReplacer #(
        .MemAddrWidth(DCacheMemAddrWidth),
        .LineWidth(DCacheLineWidth)
    ) m_TlbReplacer (
        .tlbWriteEnable,
        .tlbWriteKey,
        .tlbWriteValue,
        .memAddr(tlbReplacerMemAddr),
        .memReadDone(mem.dcReadGrant),
        .memReadEnable(tlbReplacerMemReadEnable),
        .memReadValue(mem.dcReadValue),
        .memWriteDone(mem.dcWriteGrant),
        .memWriteEnable(tlbReplacerMemWriteEnable),
        .memWriteValue(tlbReplacerMemWriteValue),
        .csrSatp(csr.satp),
        .done(tlbReplacerDone),
        .enable(tlbReplacerEnable),
        .missMemoryAccessType(r_AccessType),
        .missPage(r_Addr[VirtualAddrWidth-1:PageOffsetWidth]),
        .clk,
        .rst
    );

    // Wires
    always_comb begin
        accessType = (bus.command == LoadStoreUnitCommand_Store || bus.command == LoadStoreUnitCommand_AtomicMemOp)
            ? MemoryAccessType_Store
            : MemoryAccessType_Load;
    end

    always_comb begin
        cacheMiss = r_DCacheRead && !r_TlbMiss &&
            (!tagArrayReadValue.valid || r_PhysicalAddr[TagMsb:TagLsb] != tagArrayReadValue.tag);
    end

    always_comb begin
        shiftedReadData = rightShift(dataArrayReadValue, r_Addr[$clog2(LineSize)-1:0]);
    end

    always_comb begin
        commandAddr = r_PhysicalAddr[PhysicalAddrWidth-1:IndexLsb];
    end

    always_comb begin
        loadResult = extend(shiftedReadData, r_LoadStoreType);
    end

    always_comb begin
        storeAluValue = atomicAlu(bus.atomicType, r_StoreRegValue[31:0], loadResult[31:0]);
        storeValue = (bus.command == LoadStoreUnitCommand_AtomicMemOp)
            ? storeAluValue
            : r_StoreRegValue;
        storeConditionFlag =
            (bus.command == LoadStoreUnitCommand_StoreConditional) &&
            (r_State == State_Load) &&
            (!r_TlbMiss && !cacheMiss && !tlbFault && tagArrayReadValue.reserved);
    end

    always_comb begin
        unique case (r_State)
        State_Invalidate:   command = CacheCommand_Invalidate;
        State_ReplaceCache: command = CacheCommand_Replace;
        State_WriteThrough: command = CacheCommand_WriteThrough;
        default:            command = CacheCommand_None;
        endcase
    end

    // Module port
    always_comb begin
        hostIoValue = r_HostIoValue;
    end

    always_comb begin
        bus.done =
            (bus.command == LoadStoreUnitCommand_None && r_State == State_Default) ||
            (bus.command == LoadStoreUnitCommand_Load && r_State == State_Load && !r_TlbMiss && !cacheMiss) ||
            (bus.command == LoadStoreUnitCommand_StoreConditional && r_State == State_Load && !storeConditionFlag) ||
            (r_State == State_Reserve) ||
            (r_State == State_WriteThrough && cacheReplacerDone) ||
            (r_State == State_Invalidate && cacheReplacerDone);
        bus.fault = r_TlbFault;

        if (bus.command == LoadStoreUnitCommand_StoreConditional) begin
            bus.result = (r_State == State_WriteThrough) ? 0 : 1;
        end
        else if (bus.command == LoadStoreUnitCommand_LoadReserved || bus.command == LoadStoreUnitCommand_AtomicMemOp) begin
            bus.result = r_LoadResult;
        end
        else begin
            bus.result = loadResult;
        end
    end

    always_comb begin
        if (r_State == State_ReplaceTlb) begin
            mem.dcAddr = tlbReplacerMemAddr;
            mem.dcReadReq = tlbReplacerMemReadEnable;
            mem.dcWriteReq = tlbReplacerMemWriteEnable;
            mem.dcWriteValue = tlbReplacerMemWriteValue;
        end
        else begin
            mem.dcAddr = cacheReplacerMemAddr;
            mem.dcReadReq = cacheReplacerMemReadEnable;
            mem.dcWriteReq = cacheReplacerMemWriteEnable;
            mem.dcWriteValue = cacheReplacerMemWriteValue;
        end
    end

    // nextState
    always_comb begin
        unique case (r_State)
        State_Invalidate: begin
            nextState = cacheReplacerDone ? State_Default : r_State;
        end
        State_ReplaceCache: begin
            nextState = cacheReplacerDone ? State_Default : r_State;
        end
        State_ReplaceTlb: begin
            nextState = tlbReplacerDone ? State_Default : r_State;
        end
        State_Load: begin
            if (r_TlbMiss) begin
                nextState = State_ReplaceTlb;
            end
            else if (cacheMiss) begin
                nextState = State_ReplaceCache;
            end
            else begin
                if (bus.command == LoadStoreUnitCommand_LoadReserved) begin
                    nextState = State_Reserve;
                end
                else if (bus.command == LoadStoreUnitCommand_StoreConditional) begin
                    nextState = storeConditionFlag ? State_Store : State_Default;
                end
                else if (bus.command == LoadStoreUnitCommand_AtomicMemOp) begin
                    nextState = State_Store;
                end
                else begin
                    // Normal Load
                    nextState = State_Default;
                end
            end
        end
        State_Store: begin
            if (r_TlbMiss) begin
                nextState = State_ReplaceTlb;
            end
            else if (cacheMiss) begin
                nextState = State_ReplaceCache;
            end
            else begin
                nextState = State_WriteThrough;
            end
        end
        State_WriteThrough: begin
            nextState = cacheReplacerDone ? State_Default : r_State;
        end
        State_Reserve: begin
            nextState = State_Default;
        end
        default: begin
            if ((bus.enable && bus.command == LoadStoreUnitCommand_Load) ||
                (bus.enable && bus.command == LoadStoreUnitCommand_AtomicMemOp) ||
                (bus.enable && bus.command == LoadStoreUnitCommand_LoadReserved) ||
                (bus.enable && bus.command == LoadStoreUnitCommand_StoreConditional)) begin
                nextState = State_Load;
            end
            else if (bus.enable && bus.command == LoadStoreUnitCommand_Store) begin
                nextState = State_Store;
            end
            else if (bus.enable && bus.command == LoadStoreUnitCommand_Invalidate) begin
                nextState = State_Invalidate;
            end
            else begin
                nextState = State_Default;
            end
        end
        endcase
    end

    // nextAddr, nextAccessType, nextLoadStoreType, nextStoreRegValue
    always_comb begin
        if (r_State == State_Default) begin
            nextAddr = bus.addr;
            nextAccessType = accessType;
            nextLoadStoreType = bus.loadStoreType;
            nextStoreRegValue = bus.storeRegValue;
        end
        else begin
            nextAddr = r_Addr;
            nextAccessType = r_AccessType;
            nextLoadStoreType = r_LoadStoreType;
            nextStoreRegValue = r_StoreRegValue;
        end
    end

    // nextLoadResult
    always_comb begin
        if (r_State == State_Load) begin
            nextLoadResult = loadResult;
        end
        else begin
            nextLoadResult = r_LoadResult;
        end
    end

    always_comb begin
        nextDCacheRead = (r_State == State_Default) && bus.enable;
        nextTlbMiss = nextDCacheRead && !tlbHit;
        nextPhysicalAddr = {tlbReadValue, nextAddr[PageOffsetWidth-1:0]};

        if (bus.done) begin
            nextTlbFault = 0;
        end
        else begin
            nextTlbFault = (nextDCacheRead && tlbHit && tlbFault);
        end
    end

    always_comb begin
        nextHostIoValue = (r_State == State_WriteThrough) && cacheReplacerDone && (nextPhysicalAddr == HostIoAddr) ?
            r_StoreRegValue[31:0] :
            r_HostIoValue;
    end

    // Array input signals
    always_comb begin
        if (r_State == State_ReplaceCache || r_State == State_Invalidate) begin
            tagArrayIndex = cacheReplacerArrayIndex;
            tagArrayWriteValue.valid = cacheReplacerArrayWriteValid;
            tagArrayWriteValue.reserved = '0;
            tagArrayWriteValue.tag = cacheReplacerArrayWriteTag;
            tagArrayWriteEnable = cacheReplacerArrayWriteEnable;
        end
        else if (r_State == State_Reserve) begin
            tagArrayIndex = cacheReplacerArrayIndex;
            tagArrayWriteValue.valid = tagArrayReadValue.valid;
            tagArrayWriteValue.reserved = 1;
            tagArrayWriteValue.tag = tagArrayReadValue.tag;
            tagArrayWriteEnable = 1;
        end
        else begin
            tagArrayIndex = nextPhysicalAddr[IndexMsb:IndexLsb];
            tagArrayWriteValue.valid = '0;
            tagArrayWriteValue.reserved = '0;
            tagArrayWriteValue.tag = '0;
            tagArrayWriteEnable = '0;
        end

        // Data array input signals
        if (r_State == State_ReplaceCache || r_State == State_Invalidate) begin
            dataArrayIndex = cacheReplacerArrayIndex;
        end
        else begin
            dataArrayIndex = nextPhysicalAddr[IndexMsb:IndexLsb];
        end

        unique case (r_State)
        State_ReplaceCache: begin
            dataArrayWriteMask = cacheReplacerArrayWriteEnable ? '1 : '0;
            dataArrayWriteValue = cacheReplacerArrayWriteData;
        end
        State_Store: begin
            dataArrayWriteMask = (!r_TlbMiss && !cacheMiss && !tlbFault) ?
                makeWriteMask(nextPhysicalAddr[$clog2(DCacheLineSize)-1:0], nextLoadStoreType) :
                '0;
            dataArrayWriteValue = leftShift(storeValue, r_Addr[$clog2(LineSize)-1:0]);
        end
        default: begin
            dataArrayWriteMask = '0;
            dataArrayWriteValue = '0;
        end
        endcase
    end

    // Module enable signals
    always_comb begin
        tlbReadEnable = (r_State == State_Default);
        cacheReplacerEnable = (r_State == State_Invalidate || r_State == State_ReplaceCache || r_State == State_WriteThrough);
        tlbReplacerEnable = (r_State == State_ReplaceTlb);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_State <= State_Default;
            r_Addr <= '0;
            r_PhysicalAddr <= '0;
            r_DCacheRead <= '0;
            r_TlbFault <= '0;
            r_TlbMiss <= '0;
            r_AccessType <= MemoryAccessType_Load;
            r_LoadStoreType <= LoadStoreType_Word;
            r_LoadResult <= '0;
            r_StoreRegValue <= '0;
            r_HostIoValue <= '0;
        end
        else begin
            r_State <= nextState;
            r_Addr <= nextAddr;
            r_PhysicalAddr <= nextPhysicalAddr;
            r_DCacheRead <= nextDCacheRead;
            r_TlbFault <= nextTlbFault;
            r_TlbMiss <= nextTlbMiss;
            r_AccessType <= nextAccessType;
            r_LoadStoreType <= nextLoadStoreType;
            r_LoadResult <= nextLoadResult;
            r_StoreRegValue <= nextStoreRegValue;
            r_HostIoValue <= nextHostIoValue;
        end
    end
endmodule
