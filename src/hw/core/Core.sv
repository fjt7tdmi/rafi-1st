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

    InsnBufferIF m_InsnBufferIF();
    DecodeStageIF m_DecodeStageIF();
    RegReadStageIF m_RegReadStageIF();
    ExecuteStageIF m_ExecuteStageIF();
    PipelineControllerIF m_PipelineControllerIF();
    InterruptControllerIF m_InterruptControllerIF();
    IntRegFileIF m_IntRegFileIF();
    FpRegFileIF m_FpRegFileIF();
    IntBypassLogicIF m_IntBypassLogicIF();
    FpBypassLogicIF m_FpBypassLogicIF();
    LoadStoreUnitIF m_LoadStoreUnitIF();
    CsrIF m_CsrIF();
    FetchUnitIF m_FetchUnitIF();
    BusAccessUnitIF m_BusAccessUnitIF();

    ResetSequencer #(
        .RESET_CYCLE(CACHE_RESET_CYCLE)
    ) m_ResetSequencer (
        .rstOut(rstInternal),
        .rstIn(rst),
        .clk
    );

    FetchStage m_FetchStage(
        .insnBuffer(m_InsnBufferIF.FetchStage),
        .fetchUnit(m_FetchUnitIF.FetchStage),
        .ctrl(m_PipelineControllerIF.FetchStage),
        .interrupt(m_InterruptControllerIF.FetchStage),
        .clk,
        .rst(rstInternal)
    );
    InsnBuffer m_InsnBuffer(
        .bus(m_InsnBufferIF.InsnBuffer),
        .ctrl(m_PipelineControllerIF.InsnBuffer),
        .clk,
        .rst(rstInternal)
    );
    DecodeStage m_DecodeStage(
        .insnBuffer(m_InsnBufferIF.InsnBuffer),
        .nextStage(m_DecodeStageIF.ThisStage),
        .ctrl(m_PipelineControllerIF.DecodeStage),
        .clk,
        .rst(rstInternal)
    );
    RegReadStage m_RegReadStage(
        .prevStage(m_DecodeStageIF.NextStage),
        .nextStage(m_RegReadStageIF.ThisStage),
        .ctrl(m_PipelineControllerIF.RegReadStage),
        .intRegFile(m_IntRegFileIF.RegReadStage),
        .fpRegFile(m_FpRegFileIF.RegReadStage),
        .clk,
        .rst(rstInternal)
    );
    ExecuteStage m_ExecuteStage(
        .prevStage(m_RegReadStageIF.NextStage),
        .nextStage(m_ExecuteStageIF.ThisStage),
        .ctrl(m_PipelineControllerIF.ExecuteStage),
        .csr(m_CsrIF.ExecuteStage),
        .fetchUnit(m_FetchUnitIF.ExecuteStage),
        .loadStoreUnit(m_LoadStoreUnitIF.ExecuteStage),
        .intBypass(m_IntBypassLogicIF.ExecuteStage),
        .fpBypass(m_FpBypassLogicIF.ExecuteStage),
        .clk,
        .rst(rstInternal)
    );
    RegWriteStage m_RegWriteStage(
        .prevStage(m_ExecuteStageIF.NextStage),
        .ctrl(m_PipelineControllerIF.RegWriteStage),
        .csr(m_CsrIF.RegWriteStage),
        .intRegFile(m_IntRegFileIF.RegWriteStage),
        .fpRegFile(m_FpRegFileIF.RegWriteStage),
        .clk,
        .rst(rstInternal)
    );

    IntRegFile m_IntRegFile(
        .bus(m_IntRegFileIF.RegFile),
        .clk,
        .rst(rstInternal)
    );
    FpRegFile m_FpRegFile(
        .bus(m_FpRegFileIF.RegFile),
        .clk,
        .rst(rstInternal)
    );
    IntBypassLogic m_IntBypassLogic(
        .bus(m_IntBypassLogicIF.BypassLogic),
        .ctrl(m_PipelineControllerIF.BypassLogic),
        .clk,
        .rst(rstInternal)
    );
    FpBypassLogic m_FpBypassLogic(
        .bus(m_FpBypassLogicIF.BypassLogic),
        .ctrl(m_PipelineControllerIF.BypassLogic),
        .clk,
        .rst(rstInternal)
    );
    Csr m_Csr(
        .bus(m_CsrIF.Csr),
        .clk,
        .rst(rstInternal)
    );
    PipelineController m_PipelineController(
        .bus(m_PipelineControllerIF.PipelineController),
        .csr(m_CsrIF.PipelineController),
        .clk,
        .rst(rstInternal)
    );
    InterruptController m_InterruptController(
        .bus(m_InterruptControllerIF.InterruptController),
        .csr(m_CsrIF.InterruptController),
        .clk,
        .rst(rstInternal)
    );

    FetchUnit m_FetchUnit(
        .bus(m_FetchUnitIF.FetchUnit),
        .mem(m_BusAccessUnitIF.FetchUnit),
        .csr(m_CsrIF.FetchUnit),
        .clk,
        .rst(rstInternal)
    );
    LoadStoreUnit m_LoadStoreUnit(
        .bus(m_LoadStoreUnitIF.LoadStoreUnit),
        .mem(m_BusAccessUnitIF.LoadStoreUnit),
        .csr(m_CsrIF.LoadStoreUnit),
        .clk,
        .rst(rstInternal)
    );
    BusAccessUnit m_BusAccessUnit(
        .core(m_BusAccessUnitIF.BusAccessUnit),
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