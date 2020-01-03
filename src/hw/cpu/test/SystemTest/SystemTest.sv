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
import MemoryTypes::*;
import TraceTypes::*;

timeunit 1ns;
timeprecision 100ps;

module SystemTest;
    // Command line arguments
    parameter INITIAL_MEMORY_PATH;
    parameter DUMP_PATH;
    parameter ENABLE_DUMP_CSR;
    parameter ENABLE_DUMP_MEMORY;
    parameter ENABLE_FINISH;

    // Constant parameter
    parameter BAUD_RATE = 115200 * 1000;
    parameter CLOCK_FREQUENCY = 1000 * 1000 * 1000;
    parameter UART_LOAD_SIZE = 0;

    parameter SIMULATION_CYCLE = 32000;
    parameter HALF_CYCLE_TIME = 5;
    parameter ONE_CYCLE_TIME = HALF_CYCLE_TIME * 2;

    //parameter SdramAddrWidth = 16; /* for rv32*-p-* */
    parameter SdramAddrWidth = 25; /* for DE0CV emulation */

    localparam SdramBankWidth = 3;
    localparam SdramDataWidth = 16;

    // Variables
    integer cycle = 0;
    integer dumpFileHandle;

    int32_t debugOut;
    int32_t hostIoValue;
    logic uartTx;

    logic sdramWriteReq;
    logic sdramWriteAck;
    logic sdramWriteDataEnable;
    logic [SdramAddrWidth-1:0] sdramWriteAddr;
    logic [SdramDataWidth-1:0] sdramWriteData;
    logic sdramReadReq;
    logic sdramReadAck;
    logic [SdramAddrWidth-1:0] sdramReadAddr;
    logic sdramReadDataEnable;
    logic [SdramDataWidth-1:0] sdramReadData;

    logic clk;
    logic rst;

    // Modules
    InternalSdram #(
        .AddrWidth(SdramAddrWidth),
        .DataWidth(SdramDataWidth)
    ) m_Sdram (
        .writeReq(sdramWriteReq),
        .writeAck(sdramWriteAck),
        .writeDataEnable(sdramWriteDataEnable),
        .writeAddr(sdramWriteAddr),
        .writeData(sdramWriteData),
        .readReq(sdramReadReq),
        .readAck(sdramReadAck),
        .readAddr(sdramReadAddr),
        .readDataEnable(sdramReadDataEnable),
        .readData(sdramReadData),
        .clk,
        .rst
    );

    System #(
        .SdramAddrWidth(SdramAddrWidth),
        .SdramBankWidth(SdramBankWidth),
        .SdramDataWidth(SdramDataWidth),
        .BaudRate(BAUD_RATE),
        .ClockFrequency(CLOCK_FREQUENCY)
    ) m_Top (
        // sdram
        .sdramWriteReq,
        .sdramWriteAck,
        .sdramWriteDataEnable,
        .sdramWriteAddr,
        .sdramWriteData,
        .sdramReadReq,
        .sdramReadAck,
        .sdramReadAddr,
        .sdramReadDataEnable,
        .sdramReadData,

        // debug
        .hostIoValue,
        .debugOut,
        .debugIn('0),

        // uart
        .uartLoadSize(UART_LOAD_SIZE),
        .uartRx(1'b0),
        .uartTx,

        // clk & rst
        .clk,
        .rst
    );

    // init Memory
    initial begin
        for (int i = 0; i < m_Sdram.BodyEntryCount; i++) begin
            m_Sdram.body[i] = '0;
        end
        $readmemh(INITIAL_MEMORY_PATH, m_Sdram.body);
    end

    // rst
    initial begin
        $display("Reset asserted.");
        rst = 1;
        #ONE_CYCLE_TIME;
        #HALF_CYCLE_TIME;
        $display("Reset deasserted.");
        rst = 0;
    end

    // clk
    initial begin
        dumpFileHandle = $fopen(DUMP_PATH, "wb");
        dumpTraceBinaryHeader();

        clk = 0;

        for (cycle = 0; cycle < SIMULATION_CYCLE; cycle++) begin
            clk = 1;
            #HALF_CYCLE_TIME;
            clk = 0;
            #HALF_CYCLE_TIME;
        end

        dumpLastNode();
        $fclose(dumpFileHandle);

        if (ENABLE_FINISH) begin
            $finish;
        end
        else begin
            $break;
        end
    end

    // dump
    int32_t opId = 0;
    logic finished = 0;

    logic retired;
    addr_t pc;

    always_ff @(posedge clk) begin
        retired <= m_Top.m_Core.m_RegWriteStage.valid;
        pc <= m_Top.m_Core.m_RegWriteStage.prevStage.pc;
    end

    always @(negedge clk) begin
        if (retired && !finished) begin
            dumpTrace();

            opId += 1;

            if (hostIoValue != 0) begin
                finished = 1;
            end
        end
    end

    task dumpTraceBinaryHeader();
        automatic TraceBinaryHeader header;

        header.signatureLow[0] = "R";
        header.signatureLow[1] = "V";
        header.signatureLow[2] = "T";
        header.signatureLow[3] = "R";
        header.signatureHigh[0] = "A";
        header.signatureHigh[1] = "C";
        header.signatureHigh[2] = "E";
        header.signatureHigh[3] = 0;
        header.headerSizeLow = $bits(header) / 8;
        header.headerSizeHigh = 0;

        $fwrite(dumpFileHandle, "%u", header);
    endtask

    task dumpTrace();
        automatic TraceHeader header;

        header.nodeSizeLow = ($bits(header) + $bits(BasicInfoNode) + $bits(Pc32Node) + $bits(IntReg32Node) + $bits(IoNode)) / 8;
        header.nodeSizeHigh = 0;

        if (ENABLE_DUMP_MEMORY) begin
            header.nodeSizeLow += ($bits(MemoryNodeHeader) + $bits(m_Sdram.body)) / 8;
        end

        $fwrite(dumpFileHandle, "%u", header);

        dumpBasicInfo();
        dumpPc32();
        dumpIntReg32();
        dumpIo();

        if (ENABLE_DUMP_MEMORY) begin
            dumpMemory();
        end
    endtask

    task dumpBasicInfo();
        automatic BasicInfoNode node;

        node.header.nodeSizeLow = $bits(node) / 8;
        node.header.nodeSizeHigh = 0;
        node.header.nodeType = NodeType_BasicInfo;
        node.header.reserved = 0;
        node.cycle = cycle;
        node.opId = opId;
        node.insn = 0;
        node.reserved = 0;

        $fwrite(dumpFileHandle, "%u", node);
    endtask

    task dumpPc32();
        automatic Pc32Node node;

        // Assertion is mandatory because "%u" cannot output 'x' and 'z'
        assert(!$isunknown(pc));

        node.header.nodeSizeLow = $bits(node) / 8;
        node.header.nodeSizeHigh = 0;
        node.header.nodeType = NodeType_Pc32;
        node.header.reserved = 0;
        node.virtualPc = pc;
        node.physicalPc = 0;

        // Binary output by "%u"
        $fwrite(dumpFileHandle, "%u", node);
    endtask

    task dumpIntReg32();
        automatic IntReg32Node node;

        assert(!$isunknown(m_Top.m_Core.m_RegFile.body));

        node.header.nodeSizeLow = $bits(node) / 8;
        node.header.nodeSizeHigh = 0;
        node.header.nodeType = NodeType_IntReg32;
        node.header.reserved = 0;

        for (int i = 0; i < 32; i++) begin
            node.regs[i] = m_Top.m_Core.m_RegFile.body[i];
        end

        $fwrite(dumpFileHandle, "%u", node);
    endtask

    task dumpIo();
        automatic IoNode node;

        assert(!$isunknown(hostIoValue));

        node.header.nodeSizeLow = $bits(node) / 8;
        node.header.nodeSizeHigh = 0;
        node.header.nodeType = NodeType_Io;
        node.header.reserved = 0;
        node.hostIoValue = hostIoValue;
        node.reserved = 0;

        $fwrite(dumpFileHandle, "%u", node);
    endtask

    task dump();
        automatic MemoryNodeHeader node;

        assert(!$isunknown(m_Sdram.body));

        node.header.nodeSizeLow = $bits(node) / 8;
        node.header.nodeSizeHigh = 0;
        node.header.nodeType = NodeType_Memory;
        node.header.reserved = 0;
        node.memorySizeLow = $bits(m_Sdram.body) / 8;
        node.memorySizeHigh = 0;

        $fwrite(dumpFileHandle, "%u", node);
        $fwrite(dumpFileHandle, "%u", m_Sdram.body);
    endtask

    task dumpCsr();
        // automatic CsrNodeHeader node;
        // automatic uint32_t [0:1023] body;

        // node.header.nodeSizeLow = ($bits(node) + $bits(body)) / 8;
        // node.header.nodeSizeHigh = 0;
        // node.header.nodeType = NodeType_Csr;
        // node.header.reserved = 0;

        // for (int i = 0; i < 1024; i++) begin
        //     body[i] = '0;
        // end

        // // TODO: impl
        // // csr の値を設定

        // assert(!$isunknown(body));

        // $fwrite(dumpFileHandle, "%u", node);
        // $fwrite(dumpFileHandle, "%u", body);
    endtask

    task dumpMemory();
        automatic MemoryNodeHeader node;

        assert(!$isunknown(m_Sdram.body));

        node.header.nodeSizeLow = $bits(node) / 8;
        node.header.nodeSizeHigh = 0;
        node.header.nodeType = NodeType_Memory;
        node.header.reserved = 0;
        node.memorySizeLow = $bits(m_Sdram.body) / 8;
        node.memorySizeHigh = 0;

        $fwrite(dumpFileHandle, "%u", node);
        $fwrite(dumpFileHandle, "%u", m_Sdram.body);
    endtask

    task dumpLastNode();
        automatic TraceChildHeader header = '0;

        $fwrite(dumpFileHandle, "%u", header);
    endtask
endmodule
