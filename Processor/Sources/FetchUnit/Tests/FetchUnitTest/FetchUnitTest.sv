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

timeunit 1ns;
timeprecision 100ps;

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

import CacheTypes::*;

module TestMemory #(
    // Bit width of cache line
    // e.g. if cache line size is 64 byte, LineSize = 64
    parameter LineSize,

    // Address to specify cacheline
    // e.g. if virtual address is 32 bit and cache line size is 64 (2^6) byte, AddrWidth = (32-6) = 26
    parameter AddrWidth,

    // Memory capacity (byte)
    parameter Capacity
)(
    MemoryAccessArbiterIF.Memory bus,
    input logic clk,
    input logic rst
);
    parameter LineWidth = LineSize * ByteWidth;
    parameter EntryCount = Capacity / LineSize;
    parameter EntryIndexWidth = $clog2(EntryCount);

    // Register
    logic [LineWidth-1:0] body[EntryCount];

    // Wires
    logic [EntryIndexWidth-1:0] entryIndex;

    always_comb begin
        entryIndex = bus.addr[EntryIndexWidth-1:0];
        bus.readValue = body[entryIndex];
    end

    always_ff @(posedge clk) begin
        if (bus.writeEnable) begin
            body[entryIndex] <= bus.writeValue;
        end
    end
endmodule

module FetchUnitTest;
    // Command line arguments
    parameter INITIAL_MEMORY_PATH;

    // Constant parameter
    parameter MemoryCapacity = 128;

    parameter MAX_CYCLE = 300;
    parameter HALF_CYCLE_TIME = 5;
    parameter ONE_CYCLE_TIME = HALF_CYCLE_TIME * 2;
    parameter RESET_TIME = ONE_CYCLE_TIME * (1 << ICacheIndexWidth);

    logic clk;
    logic rst;

    FetchUnitIF m_FetchUnitIF();
    MemoryAccessArbiterIF #(
        .LineSize(ICacheLineSize),
        .AddrWidth(ICacheMemAddrWidth)
    ) m_MemoryAccessArbiterIF();
    PipelineControllerIF m_PipelineControllerIF();
    ControlStatusRegisterIF m_ControlStatusRegisterIF();

    MemoryAccessArbiter m_MemoryAccessArbiter (
        .bus(m_MemoryAccessArbiterIF.MemoryAccessArbiter),
        .clk,
        .rst
    );

    FetchUnit m_FetchUnit (
        .bus(m_FetchUnitIF.FetchUnit),
        .mem(m_MemoryAccessArbiterIF.FetchUnit),
        .ctrl(m_PipelineControllerIF.FetchUnit),
        .csr(m_ControlStatusRegisterIF.FetchUnit),
        .clk,
        .rst
    );

    TestMemory #(
        .LineSize(ICacheLineSize),
        .AddrWidth(ICacheMemAddrWidth),
        .Capacity(MemoryCapacity)
    ) m_Memory (
        .bus(m_MemoryAccessArbiterIF.Memory),
        .clk,
        .rst
    );

    // rst
    initial begin
        $display("Reset asserted.");
        rst = 1;
        #RESET_TIME;
        #HALF_CYCLE_TIME;
        $display("Reset deasserted.");
        rst = 0;
    end

    // clk
    initial begin
        clk = 0;

        for (int i = 0; i < MAX_CYCLE; i++) begin
            clk = 1;
            #HALF_CYCLE_TIME;
            clk = 0;
            #HALF_CYCLE_TIME;
        end

        // Test not finished.
        $display("Test not finished. You should increase test cycle count.");
        assert(0);
    end

    // init memory & interface
    initial begin
        $readmemh(INITIAL_MEMORY_PATH, m_Memory.body);
        m_FetchUnitIF.invalidateICache = '0;
        m_FetchUnitIF.invalidateTlb = '0;
        m_MemoryAccessArbiterIF.dcAddr = '0;
        m_MemoryAccessArbiterIF.dcReadReq = '0;
        m_MemoryAccessArbiterIF.dcWriteReq = '0;
        m_MemoryAccessArbiterIF.dcWriteValue = '0;
        m_PipelineControllerIF.nextPc = '0;
        m_PipelineControllerIF.flush = '0;
        m_PipelineControllerIF.stall = '0;
        m_ControlStatusRegisterIF.nextPc = '0;
        m_ControlStatusRegisterIF.satp = '0;
        m_ControlStatusRegisterIF.mstatus = '0;
        m_ControlStatusRegisterIF.privilege = Privilege_Machine;
        m_ControlStatusRegisterIF.trapInfo = '0;
    end

    // Wait ICache Hit
    task WaitHit();
        while (!m_FetchUnitIF.valid) begin
            @(posedge clk); #1;
        end
    endtask

    // Read ICache and assert
    task Read(addr_t pc, icache_line_t expectValue);
        WaitHit();
        assert(m_FetchUnitIF.iCacheLine == expectValue);
        @(posedge clk); #1;
    endtask

    // test
    initial begin
        while (rst) @(posedge clk);

        // Sequential access
        Read(32'h80000000, 64'h0101010100000000);
        Read(32'h80000004, 64'h0101010100000000);
        Read(32'h80000008, 64'h0303030302020202);
        Read(32'h8000000c, 64'h0303030302020202);
        Read(32'h80000010, 64'h0505050504040404);
        Read(32'h80000014, 64'h0505050504040404);
        Read(32'h80000018, 64'h0707070706060606);
        Read(32'h8000001c, 64'h0707070706060606);
        Read(32'h80000020, 64'h0909090908080808);
        Read(32'h80000024, 64'h0909090908080808);
        Read(32'h80000028, 64'h0b0b0b0b0a0a0a0a);
        Read(32'h8000002c, 64'h0b0b0b0b0a0a0a0a);
        Read(32'h80000030, 64'h0d0d0d0d0c0c0c0c);
        Read(32'h80000034, 64'h0d0d0d0d0c0c0c0c);
        Read(32'h80000038, 64'h0f0f0f0f0e0e0e0e);
        Read(32'h8000003c, 64'h0f0f0f0f0e0e0e0e);

        $finish;
    end
endmodule