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

    typedef logic [LINE_WIDTH-1:0] _line_t;

    typedef enum logic [2:0]
    {
        State_AddrGen           = 3'h0,
        State_Translate         = 3'h1,
        State_AtomicCalc        = 3'h2,
        State_CacheRead         = 3'h4,
        State_CacheWrite        = 3'h5,
        State_CacheInvalidate   = 3'h6,
        State_Done              = 3'h7
    } State;

    function automatic word_t AtomicAlu(AtomicType atomicType, word_t regValue, word_t memValue);
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
    logic reg_tlb_fault;
    MemoryAccessType reg_access_type;
    uint64_t reg_load_result;
    uint64_t reg_store_value;

    State next_state;
    vaddr_t next_vaddr;
    paddr_t next_paddr;
    logic next_tlb_fault;
    MemoryAccessType next_access_type;
    uint64_t next_load_result;
    uint64_t next_store_value;

    // Value Generation
    uint64_t loadValue;
    _line_t cacheReadValue;
    _line_t cacheWriteValue;
    logic [LINE_SIZE-1:0] cacheWriteMask;

    LoadValueUnit loadValueUnit (
        .result(loadValue),
        .addr(reg_vaddr[$clog2(LINE_SIZE)-1:0]),
        .line(cacheReadValue),
        .loadStoreType(bus.command.loadStoreType));

    StoreValueUnit storeValueUnit (
        .line(cacheWriteValue),
        .writeMask(cacheWriteMask),
        .addr(next_vaddr[$clog2(LINE_SIZE)-1:0]),
        .value(reg_store_value),
        .loadStoreType(bus.command.loadStoreType));

    // TLB
    logic tlb_done;
    logic tlb_fault;
    logic tlb_enable;
    TlbCommand tlb_command;
    always_comb begin
        // TODO: impl TlbCommand_Invalidate
        if (reg_state == State_Translate) begin
            tlb_enable = 1;
            tlb_command = TlbCommand_Translate;
        end
        else begin
            tlb_enable = 0;
            tlb_command = '0;
        end
    end

    Tlb tlb (
        .memAddr(mem.dtlbAddr),
        .memReadEnable(mem.dtlbReadReq),
        .memWriteEnable(mem.dtlbWriteReq),
        .memWriteValue(mem.dtlbWriteValue),
        .memReadDone(mem.dtlbReadGrant),
        .memWriteDone(mem.dtlbWriteGrant),
        .memReadValue(mem.dtlbReadValue),
        .done(tlb_done),
        .fault(tlb_fault),
        .paddr(next_paddr),
        .enable(tlb_enable),
        .command(tlb_command),
        .vaddr(reg_vaddr),
        .accessType(reg_access_type),
        .satp(csr.satp),
        .status(csr.status),
        .priv(csr.privilege),
        .clk,
        .rst
    );

    // DCache
    DCacheCommand cacheCommand;
    logic cacheEnable;
    always_comb begin
        unique case (bus.loadStoreUnitCommand)
        LoadStoreUnitCommand_Load:              cacheCommand = DCacheCommand_Load;
        LoadStoreUnitCommand_Store:             cacheCommand = DCacheCommand_Store;
        LoadStoreUnitCommand_Invalidate:        cacheCommand = DCacheCommand_Invalidate;
        LoadStoreUnitCommand_AtomicMemOp:       cacheCommand = (reg_state == State_CacheRead) ? DCacheCommand_Load : DCacheCommand_Store;
        LoadStoreUnitCommand_LoadReserved:      cacheCommand = DCacheCommand_LoadReserved;
        LoadStoreUnitCommand_StoreConditional:  cacheCommand = DCacheCommand_StoreConditional;
        default:                                cacheCommand = '0;
        endcase

        cacheEnable = reg_state inside {State_CacheRead, State_CacheWrite, State_CacheInvalidate};
    end

    logic cacheDone;
    logic cacheStoreConditionalFailure;

    DCache #(
        .LINE_SIZE(LINE_SIZE),
        .TAG_WIDTH(TAG_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) cache (
        .done(cacheDone),
        .storeConditionalFailure(cacheStoreConditionalFailure),
        .readValue(cacheReadValue),
        .enable(cacheEnable),
        .command(cacheCommand),
        .writeMask(cacheWriteMask),
        .writeValue(cacheWriteValue),
        .addr(reg_paddr),
        .memAddr(mem.dcacheAddr),
        .memReadEnable(mem.dcacheReadReq),
        .memReadDone(mem.dcacheReadGrant),
        .memReadValue(mem.dcacheReadValue),
        .memWriteEnable(mem.dcacheWriteReq),
        .memWriteDone(mem.dcacheWriteGrant),
        .memWriteValue(mem.dcacheWriteValue),
        .clk,
        .rst);

    // AtomicUnit
    word_t atomicResult;
    always_comb begin
        atomicResult = AtomicAlu(bus.command.atomic, bus.srcIntRegValue2, reg_load_result[31:0]);
    end

    // Module IF
    always_comb begin
        bus.done = (reg_state == State_Done) ||
            (reg_state == State_AddrGen && bus.loadStoreUnitCommand == LoadStoreUnitCommand_None);
        bus.resultAddr = reg_vaddr;
        bus.resultValue = reg_load_result;

        if (bus.loadStoreUnitCommand inside {LoadStoreUnitCommand_Store, LoadStoreUnitCommand_StoreConditional}) begin
            bus.loadPagefault = 0;
            bus.storePagefault = reg_tlb_fault;
        end
        else begin
            bus.loadPagefault = reg_tlb_fault;
            bus.storePagefault = 0;
        end
    end

    // next_state
    always_comb begin
        unique case (reg_state)
        State_AddrGen: begin
            next_state = (bus.enable && bus.loadStoreUnitCommand != LoadStoreUnitCommand_None) ? State_Translate : reg_state;
        end
        State_Translate: begin
            if (tlb_done && bus.loadStoreUnitCommand inside {LoadStoreUnitCommand_Load, LoadStoreUnitCommand_AtomicMemOp, LoadStoreUnitCommand_LoadReserved}) begin
                next_state = State_CacheRead;
            end
            else if (tlb_done && bus.loadStoreUnitCommand inside {LoadStoreUnitCommand_Store, LoadStoreUnitCommand_StoreConditional}) begin
                next_state = State_CacheWrite;
            end
            else if (tlb_done && bus.loadStoreUnitCommand == LoadStoreUnitCommand_Invalidate) begin
                next_state = State_CacheInvalidate;
            end
            else begin
                next_state = reg_state;
            end
        end
        State_AtomicCalc: begin
            next_state = State_CacheWrite;
        end
        State_CacheRead: begin
            if (bus.loadStoreUnitCommand == LoadStoreUnitCommand_AtomicMemOp) begin
                next_state = cacheDone ? State_AtomicCalc : reg_state;
            end
            else begin
                next_state = cacheDone ? State_Done : reg_state;
            end
        end
        State_CacheWrite: begin
            next_state = cacheDone ? State_Done : reg_state;
        end
        State_CacheInvalidate: begin
            next_state = cacheDone ? State_Done : reg_state;
        end
        State_Done: begin
            next_state = State_AddrGen;
        end
        default: begin
            next_state = State_AddrGen;
        end
        endcase
    end

    // next_vaddr, next_access_type
    always_comb begin
        if (reg_state == State_AddrGen) begin
            next_vaddr = bus.srcIntRegValue1 + bus.imm; // address generation
            next_access_type = (bus.loadStoreUnitCommand == LoadStoreUnitCommand_Store || bus.loadStoreUnitCommand == LoadStoreUnitCommand_AtomicMemOp)
                ? MemoryAccessType_Store
                : MemoryAccessType_Load;
        end
        else begin
            next_vaddr = reg_vaddr;
            next_access_type = reg_access_type;
        end
    end

    // next_load_result
    always_comb begin
        if (bus.loadStoreUnitCommand == LoadStoreUnitCommand_StoreConditional) begin
            next_load_result = cacheStoreConditionalFailure ? 64'h1 : 64'h0;
        end
        else if (reg_state == State_CacheRead) begin
            next_load_result = loadValue;
        end
        else begin
            next_load_result = reg_load_result;
        end
    end

    // next_store_value
    always_comb begin
        if (reg_state == State_AddrGen) begin
            unique case (bus.command.storeSrc)
            StoreSrcType_Int:   next_store_value = {32'h0, bus.srcIntRegValue2};
            StoreSrcType_Fp:    next_store_value = bus.srcFpRegValue2;
            default:            next_store_value = '0;
            endcase
        end
        else if (reg_state == State_AtomicCalc) begin
            next_store_value = {32'h0, atomicResult};
        end
        else begin
            next_store_value = reg_store_value;
        end
    end

    // next_tlb_fault
    always_comb begin
        next_tlb_fault = (reg_state == State_Translate) ? tlb_fault : reg_tlb_fault;
    end

    // Module enable signals
    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_AddrGen;
            reg_vaddr <= '0;
            reg_paddr <= '0;
            reg_tlb_fault <= '0;
            reg_access_type <= MemoryAccessType_Load;
            reg_load_result <= '0;
            reg_store_value <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_vaddr <= next_vaddr;
            reg_paddr <= next_paddr;
            reg_tlb_fault <= next_tlb_fault;
            reg_access_type <= next_access_type;
            reg_load_result <= next_load_result;
            reg_store_value <= next_store_value;
        end
    end
endmodule
