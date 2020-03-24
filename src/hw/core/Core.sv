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
import RafiTypes::*;

module Core (
    // APB like bus
    output  logic [31:0] addr,
    output  logic select,
    output  logic enable,
    output  logic write,
    output  logic [31:0] wdata,
    input   logic [31:0] rdata,
    input   logic ready,
    input   logic irq,
    input   logic irqTimer,
    input   logic clk,
    input   logic rst
);
    logic rst_internal;

    FetchAddrGenerateStageIF fetchAddrGenerateStageIF();
    FetchAddrTranslateStageIF fetchAddrTranslateStageIF();
    ICacheReadStageIF iCacheReadStageIF();
    InsnBufferIF insnBufferIF();
    DecodeStageIF decodeStageIF();
    RegReadStageIF regReadStageIF();
    ExecuteStageIF executeStageIF();
    FetchPipeControllerIF fetchPipeControllerIF();
    MainPipeControllerIF mainPipeControllerIF();
    InterruptControllerIF interruptControllerIF();
    IntRegFileIF intRegFileIF();
    FpRegFileIF fpRegFileIF();
    IntBypassLogicIF intBypassLogicIF();
    FpBypassLogicIF fpBypassLogicIF();
    LoadStoreUnitIF loadStoreUnitIF();
    CsrIF csrIF();
    FetchUnitIF fetchUnitIF();
    BusAccessUnitIF busAccessUnitIF();

    ResetSequencer #(
        .RESET_CYCLE(CACHE_RESET_CYCLE)
    ) resetSequencer (
        .rstOut(rst_internal),
        .rstIn(rst),
        .clk
    );

    // FetchPipe
    FetchAddrGenerateStage fetchAddrGenerateStage(
        .nextStage(fetchAddrGenerateStageIF.ThisStage),
        .ctrl(fetchPipeControllerIF.FetchAddrGenerateStage),
        .clk,
        .rst(rst_internal)
    );
    FetchAddrTranslateStage fetchAddrTranslateStage(
        .prevStage(fetchAddrGenerateStageIF.NextStage),
        .nextStage(fetchAddrTranslateStageIF.ThisStage),
        .ctrl(fetchPipeControllerIF.FetchAddrTranslateStage),
        .clk,
        .rst(rst_internal)
    );
    ICacheReadStage iCacheReadStage(
        .prevStage(fetchAddrTranslateStageIF.NextStage),
        .nextStage(iCacheReadStageIF.ThisStage),
        .ctrl(fetchPipeControllerIF.ICacheReadStage),
        .clk,
        .rst(rst_internal)
    );
    InsnTraverseStage insnTraverseStage(
        .prevStage(iCacheReadStageIF.NextStage),
        .insnBuffer(insnBufferIF.FetchStage),
        .ctrl(fetchPipeControllerIF.InsnTraverseStage),
        .interrupt(interruptControllerIF.FetchStage),
        .clk,
        .rst(rst_internal)
    );
    FetchStage fetchStage(
        .insnBuffer(insnBufferIF.FetchStage),
        .fetchUnit(fetchUnitIF.FetchStage),
        .ctrl(mainPipeControllerIF.FetchStage),
        .interrupt(interruptControllerIF.FetchStage),
        .clk,
        .rst(rst_internal)
    );
    FetchUnit fetchUnit(
        .bus(fetchUnitIF.FetchUnit),
        .mem(busAccessUnitIF.FetchUnit),
        .csr(csrIF.FetchUnit),
        .clk,
        .rst(rst_internal)
    );
    FetchPipeController fetchPipeController(
        .bus(fetchPipeControllerIF.FetchPipeController),
        .clk,
        .rst(rst_internal)
    );

    // InsnBuffer
    InsnBuffer insnBuffer(
        .bus(insnBufferIF.InsnBuffer),
        .ctrl(mainPipeControllerIF.InsnBuffer),
        .clk,
        .rst(rst_internal)
    );

    // MainPipe
    DecodeStage decodeStage(
        .insnBuffer(insnBufferIF.InsnBuffer),
        .nextStage(decodeStageIF.ThisStage),
        .ctrl(mainPipeControllerIF.DecodeStage),
        .clk,
        .rst(rst_internal)
    );
    RegReadStage regReadStage(
        .prevStage(decodeStageIF.NextStage),
        .nextStage(regReadStageIF.ThisStage),
        .ctrl(mainPipeControllerIF.RegReadStage),
        .intRegFile(intRegFileIF.RegReadStage),
        .fpRegFile(fpRegFileIF.RegReadStage),
        .clk,
        .rst(rst_internal)
    );
    ExecuteStage executeStage(
        .prevStage(regReadStageIF.NextStage),
        .nextStage(executeStageIF.ThisStage),
        .ctrl(mainPipeControllerIF.ExecuteStage),
        .csr(csrIF.ExecuteStage),
        .fetchUnit(fetchUnitIF.ExecuteStage),
        .loadStoreUnit(loadStoreUnitIF.ExecuteStage),
        .intBypass(intBypassLogicIF.ExecuteStage),
        .fpBypass(fpBypassLogicIF.ExecuteStage),
        .clk,
        .rst(rst_internal)
    );
    RegWriteStage regWriteStage(
        .prevStage(executeStageIF.NextStage),
        .ctrl(mainPipeControllerIF.RegWriteStage),
        .csr(csrIF.RegWriteStage),
        .intRegFile(intRegFileIF.RegWriteStage),
        .fpRegFile(fpRegFileIF.RegWriteStage),
        .clk,
        .rst(rst_internal)
    );
    IntRegFile intRegFile(
        .bus(intRegFileIF.RegFile),
        .clk,
        .rst(rst_internal)
    );
    FpRegFile fpRegFile(
        .bus(fpRegFileIF.RegFile),
        .clk,
        .rst(rst_internal)
    );
    IntBypassLogic intBypassLogic(
        .bus(intBypassLogicIF.BypassLogic),
        .ctrl(mainPipeControllerIF.BypassLogic),
        .clk,
        .rst(rst_internal)
    );
    FpBypassLogic fpBypassLogic(
        .bus(fpBypassLogicIF.BypassLogic),
        .ctrl(mainPipeControllerIF.BypassLogic),
        .clk,
        .rst(rst_internal)
    );
    Csr csr(
        .bus(csrIF.Csr),
        .clk,
        .rst(rst_internal)
    );
    LoadStoreUnit loadStoreUnit(
        .bus(loadStoreUnitIF.LoadStoreUnit),
        .mem(busAccessUnitIF.LoadStoreUnit),
        .csr(csrIF.LoadStoreUnit),
        .clk,
        .rst(rst_internal)
    );
    MainPipeController mainPipeController(
        .bus(mainPipeControllerIF.MainPipeController),
        .csr(csrIF.MainPipeController),
        .clk,
        .rst(rst_internal)
    );

    // Bus Access
    InterruptController interruptController(
        .bus(interruptControllerIF.InterruptController),
        .csr(csrIF.InterruptController),
        .clk,
        .rst(rst_internal)
    );
    BusAccessUnit busAccessUnit(
        .core(busAccessUnitIF.BusAccessUnit),
        .addr,
        .select,
        .enable,
        .write,
        .wdata,
        .rdata,
        .ready,
        .irq,
        .irqTimer,
        .clk,
        .rst(rst_internal)
    );
endmodule