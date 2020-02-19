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

import TlbTypes::*;

module TlbReplacer #(
    parameter LINE_WIDTH,
    parameter MEM_ADDR_WIDTH
)(
    // TLB access
    output logic tlbWriteEnable,
    output virtual_page_number_t tlbWriteKey,
    output TlbEntry tlbWriteValue,

    // Memory access
    output logic [MEM_ADDR_WIDTH-1:0] memAddr,
    output logic memReadEnable,
    output logic memWriteEnable,
    output logic [LINE_WIDTH-1:0] memWriteValue,
    input logic memReadDone,
    input logic memWriteDone,
    input logic [LINE_WIDTH-1:0] memReadValue,

    // CSR
    input csr_satp_t csrSatp,

    // Control
    output logic done,
    input logic enable,
    input MemoryAccessType missMemoryAccessType,
    input virtual_page_number_t missPage,

    // clk & rst
    input logic clk,
    input logic rst
);
    localparam EntryCountInLine = LINE_WIDTH / PAGE_TABLE_ENTRY_WIDTH;
    localparam EntryIndexInLINE_WIDTH = $clog2(EntryCountInLine);

    typedef logic [LINE_WIDTH-1:0] _line_t;
    typedef logic [EntryIndexInLINE_WIDTH-1:0] _entry_index_t;

    typedef enum logic [3:0]
    {
        State_Default           = 4'h0,
        State_PageTableRead1    = 4'h1,
        State_PageTableDecode1  = 4'h2,
        State_PageTableWrite1   = 4'h3,
        State_PageTableRead0    = 4'h4,
        State_PageTableDecode0  = 4'h5,
        State_PageTableWrite0   = 4'h6,
        State_TlbWrite          = 4'h7,
        State_TlbWriteForFault  = 4'h8
    } State;

    // Functions
    function automatic logic isLeafEntry(PageTableEntry entry);
        return entry.read || entry.execute;
    endfunction

    function automatic logic isFault(PageTableEntry entry);
        return !entry.valid || (!entry.read && entry.write);
    endfunction

    function automatic _entry_index_t getEntryIndex(paddr_t entryAddr);
        return entryAddr[$clog2(PAGE_TABLE_ENTRY_SIZE) + EntryIndexInLINE_WIDTH - 1 : $clog2(PAGE_TABLE_ENTRY_SIZE)];
    endfunction

    function automatic PageTableEntry readEntry(_line_t memValue, _entry_index_t entryIndex);
        PageTableEntry [EntryCountInLine-1:0] entries = memValue;
        return entries[entryIndex];
    endfunction

    function automatic _line_t writeEntry(_line_t memValue, PageTableEntry entry, _entry_index_t entryIndex);
        PageTableEntry [EntryCountInLine-1:0] entries = memValue;
        PageTableEntry [EntryCountInLine-1:0] retEntries;
        _line_t ret;

        /* verilator lint_off WIDTH */
        for (int i = 0; i < EntryCountInLine; i++) begin
            if (i == entryIndex) begin
                retEntries[i] = entry;
            end
            else begin
                retEntries[i] = entries[i];
            end
        end

        ret = retEntries;
        return ret;
    endfunction

    function automatic PageTableEntry makeEntryForWrite(PageTableEntry entry, MemoryAccessType accessType);
        PageTableEntry ret = entry;

        ret.accessed = 1;
        ret.dirty |= (accessType == MemoryAccessType_Store);
        return ret;
    endfunction

    // Registers
    State reg_state;
    MemoryAccessType reg_access_type;
    virtual_page_number_t reg_virtual_page_number;
    physical_page_number_t reg_physical_page_number;
    PageTableEntry reg_page_table_entry1;
    PageTableEntry reg_page_table_entry0;
    TlbEntryFlags reg_flags;
    _line_t reg_line;

    // Wires
    State next_state;
    MemoryAccessType next_access_type;
    virtual_page_number_t next_virtual_page_number;
    physical_page_number_t next_physical_page_number;
    PageTableEntry next_page_table_entry1;
    PageTableEntry next_page_table_entry0;
    TlbEntryFlags next_flags;
    _line_t next_line;

    PageTableEntry writePageTableEntry1;
    PageTableEntry writePageTableEntry0;
    paddr_t entryAddr1;
    paddr_t entryAddr0;

    // Wires
    always_comb begin
        writePageTableEntry1 = makeEntryForWrite(reg_page_table_entry1, reg_access_type);
        writePageTableEntry0 = makeEntryForWrite(reg_page_table_entry0, reg_access_type);
        entryAddr1 = {csrSatp.ppn, reg_virtual_page_number.vpn1, 2'b00};
        entryAddr0 = {reg_page_table_entry1.ppn1, reg_page_table_entry1.ppn0, reg_virtual_page_number.vpn0, 2'b00};
    end

    always_comb begin
        unique case(reg_state)
        State_Default: begin
            next_state = enable ? State_PageTableRead1 : State_Default;
        end
        State_PageTableRead1: begin
            next_state = memReadDone ? State_PageTableDecode1 : State_PageTableRead1;
        end
        State_PageTableDecode1: begin
            if (isLeafEntry(reg_page_table_entry1)) begin
                next_state = State_PageTableWrite1;
            end
            else begin
                next_state = isFault(reg_page_table_entry1) ? State_TlbWriteForFault : State_PageTableRead0;
            end
        end
        State_PageTableWrite1: begin
            next_state = memWriteDone ? State_TlbWrite : State_PageTableWrite1;
        end
        State_PageTableRead0: begin
            next_state = memReadDone ? State_PageTableDecode0 : State_PageTableRead0;
        end
        State_PageTableDecode0: begin
            if (isLeafEntry(reg_page_table_entry0)) begin
                next_state = State_PageTableWrite0;
            end
            else begin
                // Cannot find leaf page table entry
                next_state = State_TlbWriteForFault;
            end
        end
        State_PageTableWrite0: begin
            next_state = memWriteDone ? State_TlbWrite : State_PageTableWrite0;
        end
        default: begin
            // State_TlbWrite, State_TlbWriteForFault
            next_state = State_Default;
        end
        endcase

        next_access_type = missMemoryAccessType;

        next_virtual_page_number = (reg_state == State_Default && enable) ?
            missPage :
            reg_virtual_page_number;

        unique case (reg_state)
        State_PageTableDecode1: begin
            next_physical_page_number = {writePageTableEntry1.ppn1, reg_virtual_page_number[$bits(writePageTableEntry1.ppn0)-1:0]};
            next_flags.dirty = writePageTableEntry1.dirty;
            next_flags.user = writePageTableEntry1.user;
            next_flags.execute = writePageTableEntry1.execute;
            next_flags.write = writePageTableEntry1.write;
            next_flags.read = writePageTableEntry1.read;
        end
        State_PageTableDecode0: begin
            next_physical_page_number = {writePageTableEntry0.ppn1, writePageTableEntry0.ppn0};
            next_flags.dirty = writePageTableEntry0.dirty;
            next_flags.user = writePageTableEntry0.user;
            next_flags.execute = writePageTableEntry0.execute;
            next_flags.write = writePageTableEntry0.write;
            next_flags.read = writePageTableEntry0.read;
        end
        default: begin
            next_physical_page_number = reg_physical_page_number;
            next_flags = reg_flags;
        end
        endcase

        next_page_table_entry1 = (reg_state == State_PageTableRead1 && memReadDone) ?
            readEntry(memReadValue, getEntryIndex(entryAddr1)) :
            reg_page_table_entry1;

        next_page_table_entry0 = (reg_state == State_PageTableRead0 && memReadDone) ?
            readEntry(memReadValue, getEntryIndex(entryAddr0)) :
            reg_page_table_entry0;

        next_line = (reg_state == State_PageTableRead1 || reg_state == State_PageTableRead0) && memReadDone ?
            memReadValue :
            reg_line;
    end

    // TLB access
    always_comb begin
        tlbWriteEnable = (reg_state == State_TlbWrite || reg_state == State_TlbWriteForFault);
        tlbWriteKey = reg_virtual_page_number;

        if (reg_state == State_TlbWriteForFault) begin
            tlbWriteValue.valid = 1;
            tlbWriteValue.fault = 1;
            tlbWriteValue.pageNumber = '0;
            tlbWriteValue.flags = '0;
        end
        else begin
            tlbWriteValue.valid = 1;
            tlbWriteValue.fault = 0;
            tlbWriteValue.pageNumber = reg_physical_page_number;
            tlbWriteValue.flags = reg_flags;
        end
    end

    // Memory access
    always_comb begin
        memAddr = (reg_state == State_PageTableRead1 || reg_state == State_PageTableDecode1 || reg_state == State_PageTableWrite1) ?
            entryAddr1[PADDR_WIDTH - 1 : PADDR_WIDTH - MEM_ADDR_WIDTH] :
            entryAddr0[PADDR_WIDTH - 1 : PADDR_WIDTH - MEM_ADDR_WIDTH];

        memReadEnable = (reg_state == State_PageTableRead1 || reg_state == State_PageTableRead0);
        memWriteEnable = (reg_state == State_PageTableWrite1 || reg_state == State_PageTableWrite0);

        unique case (reg_state)
        State_PageTableWrite1: begin
            memWriteValue = writeEntry(reg_line, writePageTableEntry1, getEntryIndex(entryAddr1));
        end
        State_PageTableWrite0: begin
            memWriteValue = writeEntry(reg_line, writePageTableEntry0, getEntryIndex(entryAddr0));
        end
        default: begin
            memWriteValue = '0;
        end
        endcase
    end

    // Control
    always_comb begin
        done = (reg_state == State_TlbWrite || reg_state == State_TlbWriteForFault);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_Default;
            reg_access_type <= MemoryAccessType_Instruction;
            reg_virtual_page_number <= '0;
            reg_physical_page_number <= '0;
            reg_page_table_entry1 <= '0;
            reg_page_table_entry0 <= '0;
            reg_flags <= '0;
            reg_line <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_access_type <= next_access_type;
            reg_virtual_page_number <= next_virtual_page_number;
            reg_physical_page_number <= next_physical_page_number;
            reg_page_table_entry1 <= next_page_table_entry1;
            reg_page_table_entry0 <= next_page_table_entry0;
            reg_flags <= next_flags;
            reg_line <= next_line;
        end
    end
endmodule
