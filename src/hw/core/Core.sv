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

module Core (
    // Debug signals
    output  logic [31:0] hostIoValue,

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

    FetchStageIF m_FetchStageIF();
    DecodeStageIF m_DecodeStageIF();
    RegReadStageIF m_RegReadStageIF();
    ExecuteStageIF m_ExecuteStageIF();
    MemoryAccessStageIF m_MemoryAccessStageIF();
    PipelineControllerIF m_PipelineControllerIF();
    IntRegFileIF m_IntRegFileIF();
    FpRegFileIF m_FpRegFileIF();
    IntBypassLogicIF m_IntBypassLogicIF();
    FpBypassLogicIF m_FpBypassLogicIF();
    LoadStoreUnitIF m_LoadStoreUnitIF();
    ControlStatusRegisterIF m_ControlStatusRegisterIF();
    FetchUnitIF m_FetchUnitIF();
    BusAccessUnitIF m_BusAccessUnitIF();

    ResetSequencer #(
        .ResetCycle(CacheResetCycle)
    ) m_ResetSequencer (
        .rstOut(rstInternal),
        .rstIn(rst),
        .clk
    );

    FetchStage m_FetchStage(
        .nextStage(m_FetchStageIF.ThisStage),
        .fetchUnit(m_FetchUnitIF.FetchStage),
        .ctrl(m_PipelineControllerIF.FetchStage),
        .csr(m_ControlStatusRegisterIF.FetchStage),
        .clk,
        .rst(rstInternal)
    );
    DecodeStage m_DecodeStage(
        .prevStage(m_FetchStageIF.NextStage),
        .nextStage(m_DecodeStageIF.ThisStage),
        .ctrl(m_PipelineControllerIF.DecodeStage),
        .clk,
        .rst(rstInternal)
    );
    RegReadStage m_RegReadStage(
        .prevStage(m_DecodeStageIF.NextStage),
        .nextStage(m_RegReadStageIF.ThisStage),
        .ctrl(m_PipelineControllerIF.RegReadStage),
        .csr(m_ControlStatusRegisterIF.RegReadStage),
        .intRegFile(m_IntRegFileIF.RegReadStage),
        .fpRegFile(m_FpRegFileIF.RegReadStage),
        .clk,
        .rst(rstInternal)
    );
    ExecuteStage m_ExecuteStage(
        .prevStage(m_RegReadStageIF.NextStage),
        .nextStage(m_ExecuteStageIF.ThisStage),
        .ctrl(m_PipelineControllerIF.ExecuteStage),
        .csr(m_ControlStatusRegisterIF.ExecuteStage),
        .intBypass(m_IntBypassLogicIF.ExecuteStage),
        .fpBypass(m_FpBypassLogicIF.ExecuteStage),
        .clk,
        .rst(rstInternal)
    );
    MemoryAccessStage m_MemoryAccessStage(
        .prevStage(m_ExecuteStageIF.NextStage),
        .nextStage(m_MemoryAccessStageIF.ThisStage),
        .loadStoreUnit(m_LoadStoreUnitIF.MemoryAccessStage),
        .fetchUnit(m_FetchUnitIF.MemoryAccessStage),
        .ctrl(m_PipelineControllerIF.MemoryAccessStage),
        .intBypass(m_IntBypassLogicIF.MemoryAccessStage),
        .fpBypass(m_FpBypassLogicIF.MemoryAccessStage),
        .clk,
        .rst(rstInternal)
    );
    RegWriteStage m_RegWriteStage(
        .prevStage(m_MemoryAccessStageIF.NextStage),
        .csr(m_ControlStatusRegisterIF.RegWriteStage),
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
    ControlStatusRegister m_ControlStatusRegister(
        .bus(m_ControlStatusRegisterIF.ControlStatusRegister),
        .clk,
        .rst(rstInternal)
    );
    PipelineController m_PipelineController(
        .bus(m_PipelineControllerIF.PipelineController),
        .clk,
        .rst(rstInternal)
    );

    FetchUnit m_FetchUnit(
        .bus(m_FetchUnitIF.FetchUnit),
        .mem(m_BusAccessUnitIF.FetchUnit),
        .ctrl(m_PipelineControllerIF.FetchUnit),
        .csr(m_ControlStatusRegisterIF.FetchUnit),
        .clk,
        .rst(rstInternal)
    );
    LoadStoreUnit m_LoadStoreUnit(
        .bus(m_LoadStoreUnitIF.LoadStoreUnit),
        .mem(m_BusAccessUnitIF.LoadStoreUnit),
        .csr(m_ControlStatusRegisterIF.LoadStoreUnit),
        .hostIoValue,
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