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

module Tlb  #(
    parameter TlbIndexWidth
)(
    output  logic hit,
    output  logic fault,
    output  physical_page_number_t readValue,
    input   logic readEnable,
    input   virtual_page_number_t readKey,
    input   MemoryAccessType readAccessType,

    input   logic writeEnable,
    input   virtual_page_number_t writeKey,
    input   TlbEntry writeValue,

    // CSR
    input   csr_satp_t csrSatp,
    input   Privilege csrPrivilege,
    input   logic csrSum,
    input   logic csrMxr,

    // Control
    input   logic invalidate,

    // clk & rst
    input   logic clk,
    input   logic rst
);
    localparam EXT_WIDTH = PADDR_WIDTH - VADDR_WIDTH;

    typedef logic [TlbIndexWidth-1:0] _tlb_index_t;

    // Functions
    function automatic logic isValid(TlbEntry entry);
        return entry.valid;
    endfunction

    function automatic logic isFault(TlbEntry entry, MemoryAccessType accessType, Privilege privilege, logic sum, logic mxr);
        if (entry.fault) begin
            return 1;
        end

        if (privilege == Privilege_Supervisor && !sum && entry.flags.user) begin
            return 1;
        end
        if (privilege == Privilege_User && !entry.flags.user) begin
            return 1;
        end

        unique case(accessType)
        MemoryAccessType_Instruction:   return !entry.flags.execute;
        MemoryAccessType_Load:          return !entry.flags.read && !(mxr && entry.flags.execute);
        MemoryAccessType_Store:         return !entry.flags.write;
        default:                        return 0;
        endcase
    endfunction

    function automatic logic isUpdateNecessary(TlbEntry entry, MemoryAccessType accessType);
        if (accessType == MemoryAccessType_Store) begin
            return !entry.flags.dirty;
        end
        else begin
            return 0;
        end
    endfunction

    // Registers
    _tlb_index_t r_WriteIndex;

    // Wires
    _tlb_index_t nextWriteIndex;

    _tlb_index_t readIndex;

    logic readEntryValid;
    logic readEntryFault;
    logic readEntryNeedsUpdate;

    logic [EXT_WIDTH-1:0] ext;
    logic camHit;
    TlbEntry camReadValue;

    // Modules
    FlipFlopCam #(
        .KeyWidth(VIRTUAL_PAGE_NUMBER_WIDTH),
        .ValueWidth($bits(TlbEntry)),
        .IndexWidth(TlbIndexWidth)
    ) body (
        .hit(camHit),
        .readValue(camReadValue),
        .readKey,
        .readIndex,
        .writeEnable,
        .writeIndex(r_WriteIndex),
        .writeKey,
        .writeValue,
        .clear(invalidate),
        .clk,
        .rst
    );

    always_comb begin
        readEntryValid = isValid(camReadValue);
        readEntryFault = isFault(camReadValue, readAccessType, csrPrivilege, csrSum, csrMxr);
        readEntryNeedsUpdate = isUpdateNecessary(camReadValue, readAccessType);
        ext = '0;

        if (csrPrivilege == Privilege_Machine || csrSatp.mode == AddressTranslationMode_Bare) begin
            hit = readEnable;
            fault = 0;
            readValue = {ext, readKey};
        end
        else begin
            hit = readEnable && camHit && !(!readEntryFault && readEntryNeedsUpdate);
            fault = readEnable && camHit && readEntryFault;
            readValue = camReadValue.pageNumber;
        end

        // TODO: refactor
        if (readEnable && readEntryValid && readEntryNeedsUpdate) begin
            // Prepare to replace
            nextWriteIndex = readIndex;
        end
        else if (writeEnable) begin
            // increment for round-robin
            nextWriteIndex = r_WriteIndex + 1;
        end
        else begin
            nextWriteIndex = r_WriteIndex;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_WriteIndex <= '0;
        end
        else begin
            r_WriteIndex <= nextWriteIndex;
        end
    end

endmodule
