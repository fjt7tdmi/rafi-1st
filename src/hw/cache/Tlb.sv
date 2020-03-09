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

// 1-entry TLB and MMU
module Tlb (
    // for Memory
    output paddr_t memAddr,
    output logic memReadEnable,
    output logic memWriteEnable,
    output uint32_t memWriteValue,
    input logic memReadDone,
    input logic memWriteDone,
    input uint32_t memReadValue,

    // for Core
    output logic done,
    output logic fault,
    output paddr_t paddr,
    input logic enable,
    input TlbCommand command,
    input vaddr_t vaddr,
    input MemoryAccessType accessType,

    // CSR
    input csr_satp_t satp,
    input csr_xstatus_t status,
    input Privilege priv,

    // clk & rst
    input logic clk,
    input logic rst
);
    typedef enum logic [2:0]
    {
        State_Default           = 3'h0,
        State_Invalidate        = 3'h1,
        State_PageTableRead1    = 3'h2,
        State_PageTableDecode1  = 3'h3,
        State_PageTableRead0    = 3'h4,
        State_PageTableDecode0  = 3'h5,
        State_Done              = 3'h6
    } State;

    function automatic logic IsLeafEntry(PageTableEntry entry);
        return entry.R || entry.X;
    endfunction

    function automatic logic IsValidEntry(PageTableEntry entry);
        return entry.V;
    endfunction

    function automatic logic IsFault(PageTableEntry entry, MemoryAccessType accessType, Privilege priv, csr_xstatus_t status);
        if (!IsValidEntry(entry) || !IsLeafEntry(entry)) begin
            return 1;
        end
        if (priv == Privilege_Supervisor && !status.SUM && entry.U) begin
            return 1;
        end
        if (priv == Privilege_User && !entry.U) begin
            return 1;
        end

        unique case(accessType)
        MemoryAccessType_Instruction:   return !entry.X;
        MemoryAccessType_Load:          return !entry.R && !(status.MXR && entry.X);
        MemoryAccessType_Store:         return !entry.W;
        default:                        return 0;
        endcase
    endfunction

    function automatic PageTableEntry UpdatePageTableEntry(PageTableEntry entry, logic dirty);
        PageTableEntry ret = entry;

        ret.A = 1;
        ret.D = dirty;
        return ret;
    endfunction

    // Registers
    State reg_state;
    logic reg_valid;
    logic reg_dirty;
    vaddr_sv32_t reg_entry_vaddr;
    paddr_t reg_entry_paddr;
    PageTableEntry reg_page_table_entry;

    State next_state;
    logic next_valid;
    logic next_dirty;
    vaddr_sv32_t next_entry_vaddr;
    paddr_t next_entry_paddr;
    PageTableEntry next_page_table_entry;

    vaddr_sv32_t vaddr_sv32;
    logic hit;
    logic enable_translation;
    always_comb begin
        vaddr_sv32 = vaddr;
        hit = reg_valid && reg_entry_vaddr.VPN1 == vaddr_sv32.VPN1 && reg_entry_vaddr.VPN0 == vaddr_sv32.VPN0;
        enable_translation = (priv != Privilege_Machine && satp.MODE != AddressTranslationMode_Bare);
    end    

    // next_state
    always_comb begin
        unique case(reg_state)
        State_Default: begin
            if (enable && command == TlbCommand_Invalidate) begin
                next_state = reg_valid ? State_Invalidate : reg_state;
            end
            else if (enable && command == TlbCommand_Translate && enable_translation && !hit) begin
                next_state = reg_valid ? State_Invalidate : State_PageTableRead1;
            end
            else begin
                next_state = reg_state;
            end
        end
        State_Invalidate: begin
            if (command == TlbCommand_Invalidate) begin
                next_state = memWriteDone ? State_Done : reg_state;
            end
            else begin
                next_state = memWriteDone ? State_PageTableRead1 : reg_state;
            end
        end
        State_PageTableRead1: begin
            next_state = memReadDone ? State_PageTableDecode1 : reg_state;
        end
        State_PageTableDecode1: begin
            if (IsLeafEntry(reg_page_table_entry) || !IsValidEntry(reg_page_table_entry)) begin
                next_state = State_Done;
            end
            else begin
                next_state = State_PageTableRead0;
            end
        end
        State_PageTableRead0: begin
            next_state = memReadDone ? State_PageTableDecode0 : State_PageTableRead0;
        end
        State_PageTableDecode0: begin
            next_state = State_Done;
        end
        default: begin
            next_state = State_Default;
        end
        endcase
    end

    // next_valid
    always_comb begin
        unique case(reg_state)
        State_Done:       next_valid = 1;
        State_Invalidate: next_valid = 0;
        default:          next_valid = reg_valid;
        endcase
    end

    // next_dirty
    always_comb begin
        if (enable && command == TlbCommand_MarkDirty && reg_valid) begin
            next_dirty = 1;
        end
        else if (reg_state == State_Done) begin
            next_dirty = 0;
        end
        else begin
            next_dirty = reg_dirty;
        end
    end

    // next_entry_vaddr
    always_comb begin
        unique case(next_state)
        State_Done:       next_entry_vaddr = {vaddr_sv32.VPN1, vaddr_sv32.VPN0, 12'h0};
        State_Invalidate: next_entry_vaddr = '0;
        default:          next_entry_vaddr = reg_entry_vaddr;
        endcase
    end

    // next_entry_paddr
    always_comb begin
        unique case(next_state)
        State_PageTableRead1: next_entry_paddr = {satp.PPN, vaddr_sv32.VPN1, 2'b00};
        State_PageTableRead0: next_entry_paddr = {reg_page_table_entry.PPN1, reg_page_table_entry.PPN0, vaddr_sv32.VPN0, 2'b00};
        default:              next_entry_paddr = reg_entry_paddr;
        endcase
    end

    // next_page_table_entry
    always_comb begin
        if (memReadDone && reg_state inside {State_PageTableRead1, State_PageTableRead0}) begin
            next_page_table_entry = memReadValue;
        end
        else begin
            next_page_table_entry = reg_page_table_entry;
        end
    end

    // Module IF
    always_comb begin
        memAddr = reg_entry_paddr;
        memReadEnable = (reg_state == State_PageTableRead1 || reg_state == State_PageTableRead0);
        memWriteEnable = (reg_state == State_Invalidate);
        memWriteValue = UpdatePageTableEntry(reg_page_table_entry, reg_dirty);

        if (enable_translation) begin
            if (enable && command == TlbCommand_MarkDirty) begin
                done = 1;
            end
            else if (enable && command == TlbCommand_Invalidate) begin
                done = (reg_state == State_Done) || (reg_state == State_Default && !reg_valid);
            end
            else if (enable && command == TlbCommand_Translate) begin
                done = (reg_state == State_Done) || (reg_state == State_Default && hit);
            end
            else begin
                done = 0;
            end

            fault = IsFault(reg_page_table_entry, accessType, priv, status);
            paddr = {reg_page_table_entry.PPN1, reg_page_table_entry.PPN0, vaddr_sv32.OFFSET};
        end
        else begin
            done = 1;
            fault = 0;
            paddr = {2'b00, vaddr};
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_Default;
            reg_valid <= '0;
            reg_dirty <= '0;
            reg_entry_vaddr <= '0;
            reg_entry_paddr <= '0;
            reg_page_table_entry <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_valid <= next_valid;
            reg_dirty <= next_dirty;
            reg_entry_paddr <= next_entry_paddr;
            reg_entry_vaddr <= next_entry_vaddr;
            reg_page_table_entry <= next_page_table_entry;
        end
    end
endmodule
