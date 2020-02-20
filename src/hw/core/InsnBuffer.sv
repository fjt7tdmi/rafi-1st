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

import ProcessorTypes::*;

typedef logic [$clog2(INSN_BUFFER_ENTRY_COUNT)-1:0] insn_buffer_index_t;

module InsnBuffer(
    InsnBufferIF.InsnBuffer bus,
    PipelineControllerIF.InsnBuffer ctrl,
    input logic clk,
    input logic rst
);
    typedef enum logic [1:0]
    {
        SrcType_Keep = 2'h1,
        SrcType_Low  = 2'h2,
        SrcType_High = 2'h3
    } SrcType;

    InsnBufferEntry [INSN_BUFFER_ENTRY_COUNT-1:0] reg_entries;
    InsnBufferEntry [INSN_BUFFER_ENTRY_COUNT-1:0] next_entries;

    insn_buffer_index_t reg_head;
    insn_buffer_index_t reg_tail;
    insn_buffer_index_t next_head;
    insn_buffer_index_t next_tail;

    insn_buffer_entry_count_t reg_readable_entry_count;
    insn_buffer_entry_count_t reg_writable_entry_count;
    insn_buffer_entry_count_t next_readable_entry_count;
    insn_buffer_entry_count_t next_writable_entry_count;

    insn_buffer_entry_count_t read_entry_count;
    insn_buffer_entry_count_t write_entry_count;
    always_comb begin
        read_entry_count = (bus.readLow ? 1 : 0) + (bus.readHigh ? 1 : 0);
        write_entry_count = (bus.writeLow ? 1 : 0) + (bus.writeHigh ? 1 : 0);
    end

    SrcType [INSN_BUFFER_ENTRY_COUNT-1:0] src_types;
    always_comb begin
        for (int i = 0; i < INSN_BUFFER_ENTRY_COUNT; i++) begin
            insn_buffer_index_t index = i[$clog2(INSN_BUFFER_ENTRY_COUNT)-1:0];

            if (bus.writeLow && index == reg_tail) begin
                src_types[i] = SrcType_Low;
            end
            else if (bus.writeHigh && ((!bus.writeLow && index == reg_tail) || (bus.writeLow && index == reg_tail + 1))) begin
                src_types[i] = SrcType_High;
            end
            else begin
                src_types[i] = SrcType_Keep;
            end
        end
    end

    always_comb begin
        for (int i = 0; i < INSN_BUFFER_ENTRY_COUNT; i++) begin
            unique case (src_types[i])
            SrcType_Keep:   next_entries[i] = reg_entries[i];
            SrcType_Low:    next_entries[i] = bus.writeEntryLow;
            SrcType_High:   next_entries[i] = bus.writeEntryHigh;
            default:        next_entries[i] = '0;
            endcase
        end
    end

    always_comb begin
        /* verilator lint_off WIDTH */
        next_head = reg_head + read_entry_count;
        next_tail = reg_tail + write_entry_count;
        next_readable_entry_count = reg_readable_entry_count - read_entry_count + write_entry_count;
        next_writable_entry_count = reg_writable_entry_count + read_entry_count - write_entry_count;
    end

    always_comb begin
        /* verilator lint_off WIDTH */
        bus.readableEntryCount = reg_readable_entry_count;
        bus.writableEntryCount = reg_writable_entry_count;
        bus.readEntryLow = reg_entries[reg_head];
        bus.readEntryHigh = reg_entries[reg_head + 1];
    end

    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            reg_entries <= '0;
            reg_head <= '0;
            reg_tail <= '0;
            reg_readable_entry_count <= '0;
            reg_writable_entry_count <= INSN_BUFFER_ENTRY_COUNT;
        end
        else begin
            reg_entries <= next_entries;
            reg_head <= next_head;
            reg_tail <= next_tail;
            reg_readable_entry_count <= next_readable_entry_count;
            reg_writable_entry_count <= next_writable_entry_count;
        end
    end
endmodule
