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
    parameter LineWidth,
    parameter MemAddrWidth
)(
    // TLB access
    output logic tlbWriteEnable,
    output virtual_page_number_t tlbWriteKey,
    output TlbEntry tlbWriteValue,

    // Memory access
    output logic [MemAddrWidth-1:0] memAddr,
    output logic memReadEnable,
    output logic memWriteEnable,
    output logic [LineWidth-1:0] memWriteValue,
    input logic memReadDone,
    input logic memWriteDone,
    input logic [LineWidth-1:0] memReadValue,

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
    localparam EntryCountInLine = LineWidth / PageTableEntryWidth;
    localparam EntryIndexInLineWidth = $clog2(EntryCountInLine);

    typedef logic [LineWidth-1:0] _line_t;
    typedef logic [EntryIndexInLineWidth-1:0] _entry_index_t;

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
        return entryAddr[$clog2(PageTableEntrySize) + EntryIndexInLineWidth - 1 : $clog2(PageTableEntrySize)];
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
    State r_State;
    MemoryAccessType r_AccessType;
    virtual_page_number_t r_VirtualPageNumber;
    physical_page_number_t r_PhysicalPageNumber;
    PageTableEntry r_PageTableEntry1;
    PageTableEntry r_PageTableEntry0;
    TlbEntryFlags r_Flags;
    _line_t r_Line;

    // Wires
    State nextState;
    MemoryAccessType nextAccessType;
    virtual_page_number_t nextVirtualPageNumber;
    physical_page_number_t nextPhysicalPageNumber;
    PageTableEntry nextPageTableEntry1;
    PageTableEntry nextPageTableEntry0;
    TlbEntryFlags nextFlags;
    _line_t nextLine;

    PageTableEntry writePageTableEntry1;
    PageTableEntry writePageTableEntry0;
    paddr_t entryAddr1;
    paddr_t entryAddr0;

    // Wires
    always_comb begin
        writePageTableEntry1 = makeEntryForWrite(r_PageTableEntry1, r_AccessType);
        writePageTableEntry0 = makeEntryForWrite(r_PageTableEntry0, r_AccessType);
        entryAddr1 = {csrSatp.ppn, r_VirtualPageNumber.vpn1, 2'b00};
        entryAddr0 = {r_PageTableEntry1.ppn1, r_PageTableEntry1.ppn0, r_VirtualPageNumber.vpn0, 2'b00};
    end

    always_comb begin
        unique case(r_State)
        State_Default: begin
            nextState = enable ? State_PageTableRead1 : State_Default;
        end
        State_PageTableRead1: begin
            nextState = memReadDone ? State_PageTableDecode1 : State_PageTableRead1;
        end
        State_PageTableDecode1: begin
            if (isLeafEntry(r_PageTableEntry1)) begin
                nextState = State_PageTableWrite1;
            end
            else begin
                nextState = isFault(r_PageTableEntry1) ? State_TlbWriteForFault : State_PageTableRead0;
            end
        end
        State_PageTableWrite1: begin
            nextState = memWriteDone ? State_TlbWrite : State_PageTableWrite1;
        end
        State_PageTableRead0: begin
            nextState = memReadDone ? State_PageTableDecode0 : State_PageTableRead0;
        end
        State_PageTableDecode0: begin
            if (isLeafEntry(r_PageTableEntry0)) begin
                nextState = State_PageTableWrite0;
            end
            else begin
                // Cannot find leaf page table entry
                nextState = State_TlbWriteForFault;
            end
        end
        State_PageTableWrite0: begin
            nextState = memWriteDone ? State_TlbWrite : State_PageTableWrite0;
        end
        default: begin
            // State_TlbWrite, State_TlbWriteForFault
            nextState = State_Default;
        end
        endcase

        nextAccessType = missMemoryAccessType;

        nextVirtualPageNumber = (r_State == State_Default && enable) ?
            missPage :
            r_VirtualPageNumber;

        unique case (r_State)
        State_PageTableDecode1: begin
            nextPhysicalPageNumber = {writePageTableEntry1.ppn1, r_VirtualPageNumber[$bits(writePageTableEntry1.ppn0)-1:0]};
            nextFlags.dirty = writePageTableEntry1.dirty;
            nextFlags.user = writePageTableEntry1.user;
            nextFlags.execute = writePageTableEntry1.execute;
            nextFlags.write = writePageTableEntry1.write;
            nextFlags.read = writePageTableEntry1.read;
        end
        State_PageTableDecode0: begin
            nextPhysicalPageNumber = {writePageTableEntry0.ppn1, writePageTableEntry0.ppn0};
            nextFlags.dirty = writePageTableEntry0.dirty;
            nextFlags.user = writePageTableEntry0.user;
            nextFlags.execute = writePageTableEntry0.execute;
            nextFlags.write = writePageTableEntry0.write;
            nextFlags.read = writePageTableEntry0.read;
        end
        default: begin
            nextPhysicalPageNumber = r_PhysicalPageNumber;
            nextFlags = r_Flags;
        end
        endcase

        nextPageTableEntry1 = (r_State == State_PageTableRead1 && memReadDone) ?
            readEntry(memReadValue, getEntryIndex(entryAddr1)) :
            r_PageTableEntry1;

        nextPageTableEntry0 = (r_State == State_PageTableRead0 && memReadDone) ?
            readEntry(memReadValue, getEntryIndex(entryAddr0)) :
            r_PageTableEntry0;

        nextLine = (r_State == State_PageTableRead1 || r_State == State_PageTableRead0) && memReadDone ?
            memReadValue :
            r_Line;
    end

    // TLB access
    always_comb begin
        tlbWriteEnable = (r_State == State_TlbWrite || r_State == State_TlbWriteForFault);
        tlbWriteKey = r_VirtualPageNumber;

        if (r_State == State_TlbWriteForFault) begin
            tlbWriteValue.valid = 1;
            tlbWriteValue.fault = 1;
            tlbWriteValue.pageNumber = '0;
            tlbWriteValue.flags = '0;
        end
        else begin
            tlbWriteValue.valid = 1;
            tlbWriteValue.fault = 0;
            tlbWriteValue.pageNumber = r_PhysicalPageNumber;
            tlbWriteValue.flags = r_Flags;
        end
    end

    // Memory access
    always_comb begin
        memAddr = (r_State == State_PageTableRead1 || r_State == State_PageTableDecode1 || r_State == State_PageTableWrite1) ?
            entryAddr1[PhysicalAddrWidth - 1 : PhysicalAddrWidth - MemAddrWidth] :
            entryAddr0[PhysicalAddrWidth - 1 : PhysicalAddrWidth - MemAddrWidth];

        memReadEnable = (r_State == State_PageTableRead1 || r_State == State_PageTableRead0);
        memWriteEnable = (r_State == State_PageTableWrite1 || r_State == State_PageTableWrite0);

        unique case (r_State)
        State_PageTableWrite1: begin
            memWriteValue = writeEntry(r_Line, writePageTableEntry1, getEntryIndex(entryAddr1));
        end
        State_PageTableWrite0: begin
            memWriteValue = writeEntry(r_Line, writePageTableEntry0, getEntryIndex(entryAddr0));
        end
        default: begin
            memWriteValue = '0;
        end
        endcase
    end

    // Control
    always_comb begin
        done = (r_State == State_TlbWrite || r_State == State_TlbWriteForFault);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_State <= State_Default;
            r_AccessType <= MemoryAccessType_Instruction;
            r_VirtualPageNumber <= '0;
            r_PhysicalPageNumber <= '0;
            r_PageTableEntry1 <= '0;
            r_PageTableEntry0 <= '0;
            r_Flags <= '0;
            r_Line <= '0;
        end
        else begin
            r_State <= nextState;
            r_AccessType <= nextAccessType;
            r_VirtualPageNumber <= nextVirtualPageNumber;
            r_PhysicalPageNumber <= nextPhysicalPageNumber;
            r_PageTableEntry1 <= nextPageTableEntry1;
            r_PageTableEntry0 <= nextPageTableEntry0;
            r_Flags <= nextFlags;
            r_Line <= nextLine;
        end
    end
endmodule
