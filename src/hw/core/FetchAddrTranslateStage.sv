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
import RafiTypes::*;

module FetchAddrTranslateStage(
    FetchAddrGenerateStageIF.NextStage prevStage,
    FetchAddrTranslateStageIF.ThisStage nextStage,
    FetchPipeControllerIF.FetchAddrTranslateStage ctrl,
    CsrIF.FetchAddrTranslateStage csr,
    input   logic clk,
    input   logic rst
);
    // Dummy
    paddr_t memAddr;
    logic memReadEnable;
    logic memWriteEnable;
    uint32_t memWriteValue;
    logic memReadDone;
    logic memWriteDone;
    uint32_t memReadValue;

    // TLB
    logic done;
    logic fault;
    paddr_t pc_paddr;
    logic enable;
    TlbCommand command;

    Tlb tlb (
        .memAddr(memAddr),
        .memReadEnable(memReadEnable),
        .memWriteEnable(memWriteEnable),
        .memWriteValue(memWriteValue),
        .memReadDone(memReadDone),
        .memWriteDone(memWriteDone),
        .memReadValue(memReadValue),
        .done(done),
        .fault(fault),
        .paddr(pc_paddr),
        .enable(enable),
        .command(command),
        .vaddr(prevStage.pc_vaddr),
        .accessType(MemoryAccessType_Instruction),
        .satp(csr.satp),
        .status(csr.status),
        .priv(csr.priv),
        .clk,
        .rst
    );

    always_comb begin
        enable = prevStage.valid;
        command = TlbCommand_Translate; // TODO: impl invalidate
    end

    // FetchAddrTranslateStageIF
    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            nextStage.valid <= '0;
            nextStage.fault <= '0;
            nextStage.pc_vaddr <= '0;
            nextStage.pc_paddr <= '0;
        end
        else if (ctrl.stall) begin
            nextStage.valid <= nextStage.valid;
            nextStage.fault <= nextStage.fault;
            nextStage.pc_vaddr <= nextStage.pc_vaddr;
            nextStage.pc_paddr <= nextStage.pc_paddr;
        end
        else begin
            nextStage.valid <= prevStage.valid && done;
            nextStage.fault <= fault;
            nextStage.pc_vaddr <= prevStage.pc_vaddr;
            nextStage.pc_paddr <= pc_paddr;
        end
    end
endmodule