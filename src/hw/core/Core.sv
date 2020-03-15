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
    logic rstInternal;

    InsnBufferIF insnBufferIF();
    DecodeStageIF decodeStageIF();
    RegReadStageIF regReadStageIF();
    ExecuteStageIF executeStageIF();
    PipelineControllerIF pipelineControllerIF();
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
        .rstOut(rstInternal),
        .rstIn(rst),
        .clk
    );

    FetchStage fetchStage(
        .insnBuffer(insnBufferIF.FetchStage),
        .fetchUnit(fetchUnitIF.FetchStage),
        .ctrl(pipelineControllerIF.FetchStage),
        .interrupt(interruptControllerIF.FetchStage),
        .clk,
        .rst(rstInternal)
    );
    InsnBuffer insnBuffer(
        .bus(insnBufferIF.InsnBuffer),
        .ctrl(pipelineControllerIF.InsnBuffer),
        .clk,
        .rst(rstInternal)
    );
    DecodeStage decodeStage(
        .insnBuffer(insnBufferIF.InsnBuffer),
        .nextStage(decodeStageIF.ThisStage),
        .ctrl(pipelineControllerIF.DecodeStage),
        .clk,
        .rst(rstInternal)
    );
    RegReadStage regReadStage(
        .prevStage(decodeStageIF.NextStage),
        .nextStage(regReadStageIF.ThisStage),
        .ctrl(pipelineControllerIF.RegReadStage),
        .intRegFile(intRegFileIF.RegReadStage),
        .fpRegFile(fpRegFileIF.RegReadStage),
        .clk,
        .rst(rstInternal)
    );
    ExecuteStage executeStage(
        .prevStage(regReadStageIF.NextStage),
        .nextStage(executeStageIF.ThisStage),
        .ctrl(pipelineControllerIF.ExecuteStage),
        .csr(csrIF.ExecuteStage),
        .fetchUnit(fetchUnitIF.ExecuteStage),
        .loadStoreUnit(loadStoreUnitIF.ExecuteStage),
        .intBypass(intBypassLogicIF.ExecuteStage),
        .fpBypass(fpBypassLogicIF.ExecuteStage),
        .clk,
        .rst(rstInternal)
    );
    RegWriteStage regWriteStage(
        .prevStage(executeStageIF.NextStage),
        .ctrl(pipelineControllerIF.RegWriteStage),
        .csr(csrIF.RegWriteStage),
        .intRegFile(intRegFileIF.RegWriteStage),
        .fpRegFile(fpRegFileIF.RegWriteStage),
        .clk,
        .rst(rstInternal)
    );

    IntRegFile intRegFile(
        .bus(intRegFileIF.RegFile),
        .clk,
        .rst(rstInternal)
    );
    FpRegFile fpRegFile(
        .bus(fpRegFileIF.RegFile),
        .clk,
        .rst(rstInternal)
    );
    IntBypassLogic intBypassLogic(
        .bus(intBypassLogicIF.BypassLogic),
        .ctrl(pipelineControllerIF.BypassLogic),
        .clk,
        .rst(rstInternal)
    );
    FpBypassLogic fpBypassLogic(
        .bus(fpBypassLogicIF.BypassLogic),
        .ctrl(pipelineControllerIF.BypassLogic),
        .clk,
        .rst(rstInternal)
    );
    Csr csr(
        .bus(csrIF.Csr),
        .clk,
        .rst(rstInternal)
    );
    PipelineController pipelineController(
        .bus(pipelineControllerIF.PipelineController),
        .csr(csrIF.PipelineController),
        .clk,
        .rst(rstInternal)
    );
    InterruptController interruptController(
        .bus(interruptControllerIF.InterruptController),
        .csr(csrIF.InterruptController),
        .clk,
        .rst(rstInternal)
    );

    FetchUnit fetchUnit(
        .bus(fetchUnitIF.FetchUnit),
        .mem(busAccessUnitIF.FetchUnit),
        .csr(csrIF.FetchUnit),
        .clk,
        .rst(rstInternal)
    );
    LoadStoreUnit loadStoreUnit(
        .bus(loadStoreUnitIF.LoadStoreUnit),
        .mem(busAccessUnitIF.LoadStoreUnit),
        .csr(csrIF.LoadStoreUnit),
        .clk,
        .rst(rstInternal)
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
        .rst(rstInternal)
    );
endmodule