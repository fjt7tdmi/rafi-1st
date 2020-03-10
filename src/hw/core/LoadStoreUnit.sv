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

import OpTypes::*;
import CacheTypes::*;

module LoadStoreUnit (
    LoadStoreUnitIF.LoadStoreUnit bus,
    BusAccessUnitIF.LoadStoreUnit mem,
    CsrIF.LoadStoreUnit csr,
    input   logic clk,
    input   logic rst
);
    localparam LINE_SIZE = DCACHE_LINE_SIZE;
    localparam LINE_WIDTH = DCACHE_LINE_WIDTH;
    localparam INDEX_WIDTH = DCACHE_INDEX_WIDTH;
    localparam TAG_WIDTH = DCACHE_TAG_WIDTH;

    localparam INDEX_LSB = $clog2(LINE_SIZE);
    localparam INDEX_MSB = INDEX_LSB + INDEX_WIDTH - 1;
    localparam TAG_LSB = INDEX_LSB + INDEX_WIDTH;
    localparam TAG_MSB = PADDR_WIDTH - 1;

    typedef logic [TAG_WIDTH-1:0] _tag_t;
    typedef logic [INDEX_WIDTH-1:0] _index_t;
    typedef logic [LINE_WIDTH-1:0] _line_t;
    typedef logic [$clog2(LINE_SIZE)-1:0] _shift_amount_t;
    typedef logic [LINE_SIZE-1:0] _write_mask_t;

    typedef enum logic [2:0]
    {
        State_AddrGen       = 3'h0,
        State_Translate     = 3'h1,
        State_Invalidate    = 3'h2,
        State_ReplaceCache  = 3'h3,
        State_Load          = 3'h4,
        State_Store         = 3'h5,
        State_WriteThrough  = 3'h6,
        State_Reserve       = 3'h7
    } State;

    typedef struct packed
    {
        logic valid;
        logic reserved;
        _tag_t tag;
    } TagArrayEntry;

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
    State reg_state;
    vaddr_t reg_vaddr;
    paddr_t reg_paddr;
    logic reg_dcache_read;
    logic reg_tlb_fault;
    MemoryAccessType reg_access_type;
    uint64_t reg_load_result;
    uint64_t reg_store_value;

    State next_state;
    vaddr_t next_vaddr;
    paddr_t next_paddr;
    logic next_dcache_read;
    logic next_tlb_fault;
    MemoryAccessType next_access_type;
    uint64_t next_load_result;
    uint64_t next_store_value;

    // Signals
    logic cacheMiss;
    uint64_t storeValue;
    word_t storeAluValue;
    logic storeConditionFlag;

    // Value Generation
    uint64_t loadResult;
    logic [LINE_WIDTH-1:0] storeLine;
    logic [LINE_SIZE-1:0] storeWriteMask;

    LoadValueUnit m_LoadValueUnit (
        .result(loadResult),
        .addr(reg_vaddr[$clog2(LINE_SIZE)-1:0]),
        .line(dataArrayReadValue),
        .loadStoreType(bus.command.loadStoreType));

    StoreValueUnit m_StoreValueUnit (
        .line(storeLine),
        .writeMask(storeWriteMask),
        .addr(next_vaddr[$clog2(LINE_SIZE)-1:0]),
        .value(storeValue),
        .loadStoreType(bus.command.loadStoreType));

    // TLB
    logic                   tlbHit;
    logic                   tlbFault;
    physical_page_number_t  tlbReadValue;
    logic                   tlbReadEnable;
    logic                   tlbWriteEnable;
    virtual_page_number_t   tlbWriteKey;
    TlbEntry                tlbWriteValue;

    dcache_mem_addr_t   tlbReplacerMemAddr;
    logic               tlbReplacerMemReadEnable;
    logic               tlbReplacerMemWriteEnable;
    _line_t             tlbReplacerMemWriteValue;
    logic               tlbReplacerDone;
    logic               tlbReplacerEnable;

    TlbArray #(
        .TLB_INDEX_WIDTH(ITLB_INDEX_WIDTH)
    ) m_TlbArray (
        .hit(tlbHit),
        .fault(tlbFault),
        .readValue(tlbReadValue),
        .readEnable(tlbReadEnable),
        .readKey(reg_vaddr[VADDR_WIDTH-1:PAGE_OFFSET_WIDTH]),
        .readAccessType(reg_access_type),
        .writeEnable(tlbWriteEnable),
        .writeKey(tlbWriteKey),
        .writeValue(tlbWriteValue),
        .csrSatp(csr.satp),
        .csrPrivilege(csr.privilege),
        .csrSum(csr.status.SUM),
        .csrMxr(csr.status.MXR),
        .invalidate(bus.invalidateTlb),
        .clk,
        .rst);

    TlbReplacer #(
        .MEM_ADDR_WIDTH(DCACHE_MEM_ADDR_WIDTH),
        .LINE_WIDTH(DCACHE_LINE_WIDTH)
    ) m_TlbReplacer (
        .tlbWriteEnable,
        .tlbWriteKey,
        .tlbWriteValue,
        .memAddr(tlbReplacerMemAddr),
        .memReadDone(mem.dcacheReadGrant),
        .memReadEnable(tlbReplacerMemReadEnable),
        .memReadValue(mem.dcacheReadValue),
        .memWriteDone(mem.dcacheWriteGrant),
        .memWriteEnable(tlbReplacerMemWriteEnable),
        .memWriteValue(tlbReplacerMemWriteValue),
        .csrSatp(csr.satp),
        .done(tlbReplacerDone),
        .enable(tlbReplacerEnable),
        .missMemoryAccessType(reg_access_type),
        .missPage(reg_vaddr[VADDR_WIDTH-1:PAGE_OFFSET_WIDTH]),
        .clk,
        .rst);

    // TODO: connect to new TLB
    always_comb begin
        mem.dtlbAddr = '0;
        mem.dtlbReadReq = '0;
        mem.dtlbWriteReq = '0;
        mem.dtlbWriteValue = '0;
    end

    // DCache
    _index_t        tagArrayIndex;
    TagArrayEntry   tagArrayReadValue;
    TagArrayEntry   tagArrayWriteValue;
    logic           tagArrayWriteEnable;

    _index_t                dataArrayIndex;
    logic [LINE_WIDTH-1:0]   dataArrayReadValue;
    logic [LINE_WIDTH-1:0]   dataArrayWriteValue;
    _write_mask_t           dataArrayWriteMask;

    ReplaceLogicCommand replaceLogicCommand;
    dcache_mem_addr_t replaceLogicAddr;

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

    BlockRamWithReset #(
        .DATA_WIDTH($bits(TagArrayEntry)),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) m_ValidTagArray (
        .readValue(tagArrayReadValue),
        .index(tagArrayIndex),
        .writeValue(tagArrayWriteValue),
        .writeEnable(tagArrayWriteEnable),
        .clk,
        .rst);

    MultiBankBlockRam #(
        .DATA_WIDTH_PER_BANK(BYTE_WIDTH),
        .BANK_COUNT(LINE_SIZE),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) m_DataArray (
        .readValue(dataArrayReadValue),
        .index(dataArrayIndex),
        .writeValue(dataArrayWriteValue),
        .writeMask(dataArrayWriteMask),
        .clk);

    DCacheReplacer #(
        .LINE_WIDTH(LINE_WIDTH),
        .TAG_WIDTH(TAG_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH)
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
        .memReadDone(mem.dcacheReadGrant),
        .memReadValue(mem.dcacheReadValue),
        .memWriteEnable(cacheReplacerMemWriteEnable),
        .memWriteDone(mem.dcacheWriteGrant),
        .memWriteValue(cacheReplacerMemWriteValue),
        .done(cacheReplacerDone),
        .enable(cacheReplacerEnable),
        .command(replaceLogicCommand),
        .commandAddr(replaceLogicAddr),
        .clk,
        .rst);

    // Wires
    always_comb begin
        cacheMiss = reg_dcache_read &&
            (!tagArrayReadValue.valid || reg_paddr[TAG_MSB:TAG_LSB] != tagArrayReadValue.tag);
    end

    always_comb begin
        storeAluValue = atomicAlu(bus.command.atomic, reg_store_value[31:0], loadResult[31:0]);
        storeValue = (bus.loadStoreUnitCommand == LoadStoreUnitCommand_AtomicMemOp)
            ? {32'h0, storeAluValue}
            : reg_store_value;
        storeConditionFlag =
            (bus.loadStoreUnitCommand == LoadStoreUnitCommand_StoreConditional) &&
            (reg_state == State_Load) &&
            (!cacheMiss && !tlbFault && tagArrayReadValue.reserved);
    end

    always_comb begin
        replaceLogicAddr = reg_paddr[PADDR_WIDTH-1:INDEX_LSB];

        unique case (reg_state)
        State_Invalidate:   replaceLogicCommand = ReplaceLogicCommand_Invalidate;
        State_ReplaceCache: replaceLogicCommand = ReplaceLogicCommand_Replace;
        State_WriteThrough: replaceLogicCommand = ReplaceLogicCommand_WriteThrough;
        default:            replaceLogicCommand = ReplaceLogicCommand_None;
        endcase
    end

    // Module IF
    always_comb begin
        bus.done =
            (bus.loadStoreUnitCommand == LoadStoreUnitCommand_None && reg_state == State_AddrGen) ||
            (bus.loadStoreUnitCommand == LoadStoreUnitCommand_Load && reg_state == State_Load && !cacheMiss) ||
            (bus.loadStoreUnitCommand == LoadStoreUnitCommand_StoreConditional && reg_state == State_Load && !storeConditionFlag) ||
            (reg_state == State_Reserve) ||
            (reg_state == State_WriteThrough && cacheReplacerDone) ||
            (reg_state == State_Invalidate && cacheReplacerDone);

        if (bus.loadStoreUnitCommand inside {LoadStoreUnitCommand_Store, LoadStoreUnitCommand_StoreConditional}) begin
            bus.loadPagefault = 0;
            bus.storePagefault = reg_tlb_fault;
        end
        else begin
            bus.loadPagefault = reg_tlb_fault;
            bus.storePagefault = 0;
        end

        bus.resultAddr = reg_vaddr;

        if (bus.loadStoreUnitCommand == LoadStoreUnitCommand_StoreConditional) begin
            bus.resultValue = (reg_state == State_WriteThrough) ? 0 : 1;
        end
        else if (bus.loadStoreUnitCommand == LoadStoreUnitCommand_LoadReserved || bus.loadStoreUnitCommand == LoadStoreUnitCommand_AtomicMemOp) begin
            bus.resultValue = reg_load_result;
        end
        else begin
            bus.resultValue = loadResult;
        end

        mem.dcacheAddr = cacheReplacerMemAddr;
        mem.dcacheReadReq = cacheReplacerMemReadEnable;
        mem.dcacheWriteReq = cacheReplacerMemWriteEnable;
        mem.dcacheWriteValue = cacheReplacerMemWriteValue;
    end

    // next_state
    always_comb begin
        unique case (reg_state)
        State_AddrGen: begin
            next_state = (bus.enable && bus.loadStoreUnitCommand != LoadStoreUnitCommand_None) ? State_Translate : reg_state;
        end
        State_Translate: begin
            if (bus.loadStoreUnitCommand inside {LoadStoreUnitCommand_Load, LoadStoreUnitCommand_AtomicMemOp, LoadStoreUnitCommand_LoadReserved, LoadStoreUnitCommand_StoreConditional}) begin
                next_state = State_Load;
            end
            else if (bus.loadStoreUnitCommand == LoadStoreUnitCommand_Store) begin
                next_state = State_Store;
            end
            else if (bus.loadStoreUnitCommand == LoadStoreUnitCommand_Invalidate) begin
                next_state = State_Invalidate;
            end
            else begin
                next_state = State_AddrGen;
            end
        end
        State_Invalidate: begin
            next_state = cacheReplacerDone ? State_AddrGen : reg_state;
        end
        State_ReplaceCache: begin
            next_state = cacheReplacerDone ? State_AddrGen : reg_state;
        end
        State_Load: begin
            if (cacheMiss) begin
                next_state = State_ReplaceCache;
            end
            else begin
                if (bus.loadStoreUnitCommand == LoadStoreUnitCommand_LoadReserved) begin
                    next_state = State_Reserve;
                end
                else if (bus.loadStoreUnitCommand == LoadStoreUnitCommand_StoreConditional) begin
                    next_state = storeConditionFlag ? State_Store : State_AddrGen;
                end
                else if (bus.loadStoreUnitCommand == LoadStoreUnitCommand_AtomicMemOp) begin
                    next_state = State_Store;
                end
                else begin
                    // Normal Load
                    next_state = State_AddrGen;
                end
            end
        end
        State_Store: begin
            if (cacheMiss) begin
                next_state = State_ReplaceCache;
            end
            else begin
                next_state = State_WriteThrough;
            end
        end
        State_WriteThrough: begin
            next_state = cacheReplacerDone ? State_AddrGen : reg_state;
        end
        State_Reserve: begin
            next_state = State_AddrGen;
        end
        default: begin
            next_state = State_AddrGen;
        end
        endcase
    end

    // next_vaddr, next_access_type, next_load_store_type, next_store_value
    always_comb begin
        if (reg_state == State_AddrGen) begin
            next_vaddr = bus.srcIntRegValue1 + bus.imm; // address generation
            next_access_type = (bus.loadStoreUnitCommand == LoadStoreUnitCommand_Store || bus.loadStoreUnitCommand == LoadStoreUnitCommand_AtomicMemOp)
                ? MemoryAccessType_Store
                : MemoryAccessType_Load;

            unique case (bus.command.storeSrc)
            StoreSrcType_Int:   next_store_value = {32'h0, bus.srcIntRegValue2};
            StoreSrcType_Fp:    next_store_value = bus.srcFpRegValue2;
            default:            next_store_value = '0;
            endcase
        end
        else begin
            next_vaddr = reg_vaddr;
            next_access_type = reg_access_type;
            next_store_value = reg_store_value;
        end
    end

    // next_load_result
    always_comb begin
        if (reg_state == State_Load) begin
            next_load_result = loadResult;
        end
        else begin
            next_load_result = reg_load_result;
        end
    end

    always_comb begin
        next_dcache_read = (reg_state == State_Translate) && bus.enable;
        next_paddr = {tlbReadValue, next_vaddr[PAGE_OFFSET_WIDTH-1:0]};

        if (bus.done) begin
            next_tlb_fault = 0;
        end
        else begin
            next_tlb_fault = (next_dcache_read && tlbHit && tlbFault);
        end
    end

    // Array input signals
    always_comb begin
        if (reg_state == State_ReplaceCache || reg_state == State_Invalidate) begin
            tagArrayIndex = cacheReplacerArrayIndex;
            tagArrayWriteValue.valid = cacheReplacerArrayWriteValid;
            tagArrayWriteValue.reserved = '0;
            tagArrayWriteValue.tag = cacheReplacerArrayWriteTag;
            tagArrayWriteEnable = cacheReplacerArrayWriteEnable;
        end
        else if (reg_state == State_Reserve) begin
            // Set 'reserved' field.
            tagArrayIndex = next_paddr[INDEX_MSB:INDEX_LSB];
            tagArrayWriteValue.valid = tagArrayReadValue.valid;
            tagArrayWriteValue.reserved = 1;
            tagArrayWriteValue.tag = tagArrayReadValue.tag;
            tagArrayWriteEnable = 1;
        end
        else if (reg_state == State_Store) begin
            // Reset 'reserved' field.
            tagArrayIndex = next_paddr[INDEX_MSB:INDEX_LSB];
            tagArrayWriteValue.valid = tagArrayReadValue.valid;
            tagArrayWriteValue.reserved = 0;
            tagArrayWriteValue.tag = tagArrayReadValue.tag;
            tagArrayWriteEnable = 1;
        end
        else begin
            tagArrayIndex = next_paddr[INDEX_MSB:INDEX_LSB];
            tagArrayWriteValue.valid = '0;
            tagArrayWriteValue.reserved = '0;
            tagArrayWriteValue.tag = '0;
            tagArrayWriteEnable = '0;
        end

        // Data array input signals
        if (reg_state == State_ReplaceCache || reg_state == State_Invalidate) begin
            dataArrayIndex = cacheReplacerArrayIndex;
        end
        else begin
            dataArrayIndex = next_paddr[INDEX_MSB:INDEX_LSB];
        end

        unique case (reg_state)
        State_ReplaceCache: begin
            dataArrayWriteMask = cacheReplacerArrayWriteEnable ? '1 : '0;
            dataArrayWriteValue = cacheReplacerArrayWriteData;
        end
        State_Store: begin
            dataArrayWriteMask = (cacheMiss || tlbFault) ? '0 : storeWriteMask;
            dataArrayWriteValue = storeLine;
        end
        default: begin
            dataArrayWriteMask = '0;
            dataArrayWriteValue = '0;
        end
        endcase
    end

    // Module enable signals
    always_comb begin
        tlbReadEnable = (reg_state == State_Translate);
        cacheReplacerEnable = (reg_state == State_Invalidate || reg_state == State_ReplaceCache || reg_state == State_WriteThrough);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_AddrGen;
            reg_vaddr <= '0;
            reg_paddr <= '0;
            reg_dcache_read <= '0;
            reg_tlb_fault <= '0;
            reg_access_type <= MemoryAccessType_Load;
            reg_load_result <= '0;
            reg_store_value <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_vaddr <= next_vaddr;
            reg_paddr <= next_paddr;
            reg_dcache_read <= next_dcache_read;
            reg_tlb_fault <= next_tlb_fault;
            reg_access_type <= next_access_type;
            reg_load_result <= next_load_result;
            reg_store_value <= next_store_value;
        end
    end
endmodule
