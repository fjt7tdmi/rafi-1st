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
import OpTypes::*;
import ProcessorTypes::*;
import LoadStoreUnitTypes::*;

timeunit 1ns;
timeprecision 100ps;

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

module LoadStoreUnitTest;
    // Command line arguments
    parameter INITIAL_MEMORY_PATH;

    // Constant parameter
    parameter MAX_CYCLE = 300;
    parameter HALF_CYCLE_TIME = 5;
    parameter ONE_CYCLE_TIME = HALF_CYCLE_TIME * 2;
    parameter RESET_TIME = ONE_CYCLE_TIME * (1 << ICacheIndexWidth);

    parameter MemoryCapacity = 128;

    typedef logic [DCacheLineWidth-1:0] _line_t;

    logic clk;
    logic rst;

    LoadStoreUnitIF m_LoadStoreUnitIF();
    MemoryAccessArbiterIF #(
        .LineSize(ICacheLineSize),
        .AddrWidth(ICacheMemAddrWidth)
    ) m_MemoryAccessArbiterIF();
    ControlStatusRegisterIF m_ControlStatusRegisterIF();

    MemoryAccessArbiter m_MemoryAccessArbiter (
        .bus(m_MemoryAccessArbiterIF.MemoryAccessArbiter),
        .clk,
        .rst
    );

    LoadStoreUnit m_LoadStoreUnit (
        .bus(m_LoadStoreUnitIF.LoadStoreUnit),
        .mem(m_MemoryAccessArbiterIF.LoadStoreUnit),
        .csr(m_ControlStatusRegisterIF.LoadStoreUnit),
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
        assert(0);
    end

    // init memory & interface
    initial begin
        $readmemh(INITIAL_MEMORY_PATH, m_Memory.body);
        m_LoadStoreUnitIF.addr = '0;
        m_LoadStoreUnitIF.enable = '0;
        m_LoadStoreUnitIF.command = LoadStoreUnitCommand_None;
        m_LoadStoreUnitIF.loadStoreType = LoadStoreType_Word;
        m_LoadStoreUnitIF.writeValue = '0;
        m_MemoryAccessArbiterIF.icAddr = '0;
        m_MemoryAccessArbiterIF.icReadReq = '0;
        m_MemoryAccessArbiterIF.icWriteReq = '0;
        m_MemoryAccessArbiterIF.icWriteValue = '0;
        m_ControlStatusRegisterIF.nextPc = '0;
        m_ControlStatusRegisterIF.satp = '0;
        m_ControlStatusRegisterIF.mstatus = '0;
        m_ControlStatusRegisterIF.privilege = Privilege_Machine;
        m_ControlStatusRegisterIF.trapInfo = '0;
    end

    // Wait cache Hit
    task WaitHit();
        while (!m_LoadStoreUnitIF.done) begin
            @(posedge clk); #1;
        end
    endtask

    // Read cache and assert
    task Read(addr_t addr, _line_t expectValue);
        m_LoadStoreUnitIF.addr = addr;
        m_LoadStoreUnitIF.enable = 1;
        m_LoadStoreUnitIF.command = LoadStoreUnitCommand_Load;
        m_LoadStoreUnitIF.loadStoreType = LoadStoreType_Word;
        m_LoadStoreUnitIF.writeValue = '0;
        #1;
        WaitHit();
        #1;
        assert(m_LoadStoreUnitIF.readValue == expectValue);
        @(posedge clk); #1;
    endtask

    // Write cache
    task Write(addr_t addr, _line_t writeValue);
        m_LoadStoreUnitIF.addr = addr;
        m_LoadStoreUnitIF.enable = 1;
        m_LoadStoreUnitIF.command = LoadStoreUnitCommand_Store;
        m_LoadStoreUnitIF.loadStoreType = LoadStoreType_Word;
        m_LoadStoreUnitIF.writeValue = writeValue;
        #1;
        WaitHit();
        @(posedge clk); #1;
    endtask

    // test
    initial begin
        while (rst) @(posedge clk);

        // Sequential read
        Read(32'h80000000, 32'h00000000);
        Read(32'h80000004, 32'h01010101);
        Read(32'h80000008, 32'h02020202);

        // Write data
        Write(32'h80000000, 32'hffffffff);

        // Read data just written data
        Read(32'h80000000, 32'hffffffff);

        // Write data
        Write(32'h80000000, 32'h12345678);

        // Read data just written data
        Read(32'h80000000, 32'h12345678);

        // Read data and write-back written line
        Read(32'h80000020, 32'h08080808);
        Read(32'h80000040, 32'h10101010);
        Read(32'h80000060, 32'h18181818);

        // Read written-back line
        Write(32'h80000000, 32'h12345678);

        // Read other data
        Read(32'h80000004, 32'h01010101);
        Read(32'h80000008, 32'h02020202);
        Read(32'h8000000c, 32'h03030303);
        Read(32'h80000010, 32'h04040404);
        Read(32'h80000014, 32'h05050505);
        Read(32'h80000018, 32'h06060606);
        Read(32'h8000001c, 32'h07070707);
        Read(32'h80000020, 32'h08080808);
        Read(32'h80000024, 32'h09090909);
        Read(32'h80000028, 32'h0a0a0a0a);
        Read(32'h8000002c, 32'h0b0b0b0b);
        Read(32'h80000030, 32'h0c0c0c0c);
        Read(32'h80000034, 32'h0d0d0d0d);
        Read(32'h80000038, 32'h0e0e0e0e);
        Read(32'h8000003c, 32'h0f0f0f0f);

        $finish;
    end
endmodule