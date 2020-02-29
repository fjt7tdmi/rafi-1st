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
    output  logic [31:0] hostIoValue,
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
        int8_t [LINE_SIZE-1:0] bytes;
        int8_t [7:0] shiftedBytes;

        bytes = value;

        for (int i = 0; i < 8; i++) begin
            /* verilator lint_off WIDTH */
            if (shift + i < LINE_SIZE) begin
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
        int8_t [LINE_SIZE-1:0] shiftedBytes;

        bytes = value;

        for (int i = 0; i < LINE_SIZE; i++) begin
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
        else if (loadStoreType inside {LoadStoreType_Word, LoadStoreType_UnsignedWord, LoadStoreType_FpWord}) begin
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
        LoadStoreType_FpWord: begin
            return {32'hffff_ffff, value[31:0]};
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
    State reg_state;
    addr_t reg_addr;
    paddr_t reg_paddr;
    logic reg_dcache_read;
    logic reg_tlb_fault;
    logic reg_tlb_miss;
    MemoryAccessType reg_access_type;
    LoadStoreType reg_load_store_type;
    uint64_t reg_load_result;
    uint64_t reg_store_value;
    word_t reg_host_io_value; // special register for debug

    // Wires
    State next_state;
    addr_t next_addr;
    paddr_t next_paddr;
    logic next_dcache_read;
    logic next_tlb_fault;
    logic next_tlb_miss;
    MemoryAccessType next_access_type;
    LoadStoreType next_load_store_type;
    uint64_t next_load_result;
    uint64_t next_store_value;
    word_t next_host_io_value;

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
    logic [LINE_WIDTH-1:0]   dataArrayReadValue;
    logic [LINE_WIDTH-1:0]   dataArrayWriteValue;
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
        .DATA_WIDTH($bits(TagArrayEntry)),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) m_ValidTagArray (
        .readValue(tagArrayReadValue),
        .index(tagArrayIndex),
        .writeValue(tagArrayWriteValue),
        .writeEnable(tagArrayWriteEnable),
        .clk,
        .rst
    );

    MultiBankBlockRam #(
        .DATA_WIDTH_PER_BANK(BYTE_WIDTH),
        .BANK_COUNT(LINE_SIZE),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) m_DataArray (
        .readValue(dataArrayReadValue),
        .index(dataArrayIndex),
        .writeValue(dataArrayWriteValue),
        .writeMask(dataArrayWriteMask),
        .clk
    );

    Tlb #(
        .TLB_INDEX_WIDTH(ITLB_INDEX_WIDTH)
    ) m_Tlb (
        .hit(tlbHit),
        .fault(tlbFault),
        .readValue(tlbReadValue),
        .readEnable(tlbReadEnable),
        .readKey(next_addr[VADDR_WIDTH-1:PAGE_OFFSET_WIDTH]),
        .readAccessType(accessType),
        .writeEnable(tlbWriteEnable),
        .writeKey(tlbWriteKey),
        .writeValue(tlbWriteValue),
        .csrSatp(csr.satp),
        .csrPrivilege(csr.privilege),
        .csrSum(csr.status.SUM),
        .csrMxr(csr.status.MXR),
        .invalidate(bus.invalidateTlb),
        .clk,
        .rst
    );

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
        .MEM_ADDR_WIDTH(DCACHE_MEM_ADDR_WIDTH),
        .LINE_WIDTH(DCACHE_LINE_WIDTH)
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
        .missMemoryAccessType(reg_access_type),
        .missPage(reg_addr[VADDR_WIDTH-1:PAGE_OFFSET_WIDTH]),
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
        cacheMiss = reg_dcache_read && !reg_tlb_miss &&
            (!tagArrayReadValue.valid || reg_paddr[TAG_MSB:TAG_LSB] != tagArrayReadValue.tag);
    end

    always_comb begin
        shiftedReadData = rightShift(dataArrayReadValue, reg_addr[$clog2(LINE_SIZE)-1:0]);
    end

    always_comb begin
        commandAddr = reg_paddr[PADDR_WIDTH-1:INDEX_LSB];
    end

    always_comb begin
        loadResult = extend(shiftedReadData, reg_load_store_type);
    end

    always_comb begin
        storeAluValue = atomicAlu(bus.atomicType, reg_store_value[31:0], loadResult[31:0]);
        storeValue = (bus.command == LoadStoreUnitCommand_AtomicMemOp)
            ? storeAluValue
            : reg_store_value;
        storeConditionFlag =
            (bus.command == LoadStoreUnitCommand_StoreConditional) &&
            (reg_state == State_Load) &&
            (!reg_tlb_miss && !cacheMiss && !tlbFault && tagArrayReadValue.reserved);
    end

    always_comb begin
        unique case (reg_state)
        State_Invalidate:   command = CacheCommand_Invalidate;
        State_ReplaceCache: command = CacheCommand_Replace;
        State_WriteThrough: command = CacheCommand_WriteThrough;
        default:            command = CacheCommand_None;
        endcase
    end

    // Module port
    always_comb begin
        hostIoValue = reg_host_io_value;
    end

    always_comb begin
        bus.done =
            (bus.command == LoadStoreUnitCommand_None && reg_state == State_Default) ||
            (bus.command == LoadStoreUnitCommand_Load && reg_state == State_Load && !reg_tlb_miss && !cacheMiss) ||
            (bus.command == LoadStoreUnitCommand_StoreConditional && reg_state == State_Load && !storeConditionFlag) ||
            (reg_state == State_Reserve) ||
            (reg_state == State_WriteThrough && cacheReplacerDone) ||
            (reg_state == State_Invalidate && cacheReplacerDone);
        
        if (bus.command inside {LoadStoreUnitCommand_Store, LoadStoreUnitCommand_StoreConditional}) begin
            bus.loadPagefault = 0;
            bus.storePagefault = reg_tlb_fault;
        end
        else begin
            bus.loadPagefault = reg_tlb_fault;
            bus.storePagefault = 0;
        end

        if (bus.command == LoadStoreUnitCommand_StoreConditional) begin
            bus.result = (reg_state == State_WriteThrough) ? 0 : 1;
        end
        else if (bus.command == LoadStoreUnitCommand_LoadReserved || bus.command == LoadStoreUnitCommand_AtomicMemOp) begin
            bus.result = reg_load_result;
        end
        else begin
            bus.result = loadResult;
        end
    end

    always_comb begin
        if (reg_state == State_ReplaceTlb) begin
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

    // next_state
    always_comb begin
        unique case (reg_state)
        State_Invalidate: begin
            next_state = cacheReplacerDone ? State_Default : reg_state;
        end
        State_ReplaceCache: begin
            next_state = cacheReplacerDone ? State_Default : reg_state;
        end
        State_ReplaceTlb: begin
            next_state = tlbReplacerDone ? State_Default : reg_state;
        end
        State_Load: begin
            if (reg_tlb_miss) begin
                next_state = State_ReplaceTlb;
            end
            else if (cacheMiss) begin
                next_state = State_ReplaceCache;
            end
            else begin
                if (bus.command == LoadStoreUnitCommand_LoadReserved) begin
                    next_state = State_Reserve;
                end
                else if (bus.command == LoadStoreUnitCommand_StoreConditional) begin
                    next_state = storeConditionFlag ? State_Store : State_Default;
                end
                else if (bus.command == LoadStoreUnitCommand_AtomicMemOp) begin
                    next_state = State_Store;
                end
                else begin
                    // Normal Load
                    next_state = State_Default;
                end
            end
        end
        State_Store: begin
            if (reg_tlb_miss) begin
                next_state = State_ReplaceTlb;
            end
            else if (cacheMiss) begin
                next_state = State_ReplaceCache;
            end
            else begin
                next_state = State_WriteThrough;
            end
        end
        State_WriteThrough: begin
            next_state = cacheReplacerDone ? State_Default : reg_state;
        end
        State_Reserve: begin
            next_state = State_Default;
        end
        default: begin
            if ((bus.enable && bus.command == LoadStoreUnitCommand_Load) ||
                (bus.enable && bus.command == LoadStoreUnitCommand_AtomicMemOp) ||
                (bus.enable && bus.command == LoadStoreUnitCommand_LoadReserved) ||
                (bus.enable && bus.command == LoadStoreUnitCommand_StoreConditional)) begin
                next_state = State_Load;
            end
            else if (bus.enable && bus.command == LoadStoreUnitCommand_Store) begin
                next_state = State_Store;
            end
            else if (bus.enable && bus.command == LoadStoreUnitCommand_Invalidate) begin
                next_state = State_Invalidate;
            end
            else begin
                next_state = State_Default;
            end
        end
        endcase
    end

    // next_addr, next_access_type, next_load_store_type, next_store_value
    always_comb begin
        if (reg_state == State_Default) begin
            next_addr = bus.addr;
            next_access_type = accessType;
            next_load_store_type = bus.loadStoreType;
            next_store_value = bus.storeRegValue;
        end
        else begin
            next_addr = reg_addr;
            next_access_type = reg_access_type;
            next_load_store_type = reg_load_store_type;
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
        next_dcache_read = (reg_state == State_Default) && bus.enable;
        next_tlb_miss = next_dcache_read && !tlbHit;
        next_paddr = {tlbReadValue, next_addr[PAGE_OFFSET_WIDTH-1:0]};

        if (bus.done) begin
            next_tlb_fault = 0;
        end
        else begin
            next_tlb_fault = (next_dcache_read && tlbHit && tlbFault);
        end
    end

    always_comb begin
        next_host_io_value = (reg_state == State_WriteThrough) && cacheReplacerDone && (next_paddr == HOST_IO_ADDR) ?
            reg_store_value[31:0] :
            reg_host_io_value;
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
            dataArrayWriteMask = (!reg_tlb_miss && !cacheMiss && !tlbFault) ?
                makeWriteMask(next_paddr[$clog2(DCACHE_LINE_SIZE)-1:0], next_load_store_type) :
                '0;
            dataArrayWriteValue = leftShift(storeValue, reg_addr[$clog2(LINE_SIZE)-1:0]);
        end
        default: begin
            dataArrayWriteMask = '0;
            dataArrayWriteValue = '0;
        end
        endcase
    end

    // Module enable signals
    always_comb begin
        tlbReadEnable = (reg_state == State_Default);
        cacheReplacerEnable = (reg_state == State_Invalidate || reg_state == State_ReplaceCache || reg_state == State_WriteThrough);
        tlbReplacerEnable = (reg_state == State_ReplaceTlb);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_Default;
            reg_addr <= '0;
            reg_paddr <= '0;
            reg_dcache_read <= '0;
            reg_tlb_fault <= '0;
            reg_tlb_miss <= '0;
            reg_access_type <= MemoryAccessType_Load;
            reg_load_store_type <= LoadStoreType_Word;
            reg_load_result <= '0;
            reg_store_value <= '0;
            reg_host_io_value <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_addr <= next_addr;
            reg_paddr <= next_paddr;
            reg_dcache_read <= next_dcache_read;
            reg_tlb_fault <= next_tlb_fault;
            reg_tlb_miss <= next_tlb_miss;
            reg_access_type <= next_access_type;
            reg_load_store_type <= next_load_store_type;
            reg_load_result <= next_load_result;
            reg_store_value <= next_store_value;
            reg_host_io_value <= next_host_io_value;
        end
    end
endmodule
