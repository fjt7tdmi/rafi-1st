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

module Core #(
    parameter MemoryAddrWidth = 30,
    parameter MemoryLineWidth = 128
)(
    output  logic [31:0] hostIoValue,
    output  logic [MemoryAddrWidth-1:0] memoryAddr,
    output  logic memoryEnable,
    output  logic memoryIsWrite,
    output  logic [MemoryLineWidth-1:0] memoryWriteValue,
    input   logic [MemoryLineWidth-1:0] memoryReadValue,
    input   logic memoryDone,
    input   logic clk,
    input   logic rstIn
);
    logic rst;

    FetchStageIF m_FetchStageIF();
    DecodeStageIF m_DecodeStageIF();
    RegReadStageIF m_RegReadStageIF();
    ExecuteStageIF m_ExecuteStageIF();
    MemoryAccessStageIF m_MemoryAccessStageIF();
    PipelineControllerIF m_PipelineControllerIF();
    RegFileIF m_RegFileIF();
    BypassLogicIF m_BypassLogicIF();
    LoadStoreUnitIF m_LoadStoreUnitIF();
    ControlStatusRegisterIF m_ControlStatusRegisterIF();
    FetchUnitIF m_FetchUnitIF();
    // TODO: Remove parameter settings
    MemoryAccessArbiterIF #(
        .LineSize(DCacheLineSize),
        .AddrWidth(DCacheMemAddrWidth)
    ) m_MemoryAccessArbiterIF();

    ResetSequencer #(
        .ResetCycle(CacheResetCycle)
    ) m_ResetSequencer (
        .rstOut(rst),
        .rstIn(rstIn),
        .clk
    );

    FetchStage m_FetchStage(
        .nextStage(m_FetchStageIF.ThisStage),
        .fetchUnit(m_FetchUnitIF.FetchStage),
        .ctrl(m_PipelineControllerIF.FetchStage),
        .csr(m_ControlStatusRegisterIF.FetchStage),
        .clk,
        .rst
    );
    DecodeStage m_DecodeStage(
        .prevStage(m_FetchStageIF.NextStage),
        .nextStage(m_DecodeStageIF.ThisStage),
        .ctrl(m_PipelineControllerIF.DecodeStage),
        .clk,
        .rst
    );
    RegReadStage m_RegReadStage(
        .prevStage(m_DecodeStageIF.NextStage),
        .nextStage(m_RegReadStageIF.ThisStage),
        .ctrl(m_PipelineControllerIF.RegReadStage),
        .csr(m_ControlStatusRegisterIF.RegReadStage),
        .regFile(m_RegFileIF.RegReadStage),
        .clk,
        .rst
    );
    ExecuteStage m_ExecuteStage(
        .prevStage(m_RegReadStageIF.NextStage),
        .nextStage(m_ExecuteStageIF.ThisStage),
        .ctrl(m_PipelineControllerIF.ExecuteStage),
        .csr(m_ControlStatusRegisterIF.ExecuteStage),
        .bypass(m_BypassLogicIF.ExecuteStage),
        .clk,
        .rst
    );
    MemoryAccessStage m_MemoryAccessStage(
        .prevStage(m_ExecuteStageIF.NextStage),
        .nextStage(m_MemoryAccessStageIF.ThisStage),
        .loadStoreUnit(m_LoadStoreUnitIF.MemoryAccessStage),
        .fetchUnit(m_FetchUnitIF.MemoryAccessStage),
        .ctrl(m_PipelineControllerIF.MemoryAccessStage),
        .bypass(m_BypassLogicIF.MemoryAccessStage),
        .clk,
        .rst
    );
    RegWriteStage m_RegWriteStage(
        .prevStage(m_MemoryAccessStageIF.NextStage),
        .csr(m_ControlStatusRegisterIF.RegWriteStage),
        .regFile(m_RegFileIF.RegWriteStage),
        .clk,
        .rst
    );

    RegFile m_RegFile(
        .bus(m_RegFileIF.RegFile),
        .clk,
        .rst
    );
    BypassLogic m_BypassLogic(
        .bus(m_BypassLogicIF.BypassLogic),
        .ctrl(m_PipelineControllerIF.BypassLogic),
        .clk,
        .rst
    );
    ControlStatusRegister m_ControlStatusRegister(
        .bus(m_ControlStatusRegisterIF.ControlStatusRegister),
        .clk,
        .rst
    );
    PipelineController m_PipelineController(
        .bus(m_PipelineControllerIF.PipelineController),
        .clk,
        .rst
    );

    FetchUnit m_FetchUnit(
        .bus(m_FetchUnitIF.FetchUnit),
        .mem(m_MemoryAccessArbiterIF.FetchUnit),
        .ctrl(m_PipelineControllerIF.FetchUnit),
        .csr(m_ControlStatusRegisterIF.FetchUnit),
        .clk,
        .rst
    );
    LoadStoreUnit m_LoadStoreUnit(
        .bus(m_LoadStoreUnitIF.LoadStoreUnit),
        .mem(m_MemoryAccessArbiterIF.LoadStoreUnit),
        .csr(m_ControlStatusRegisterIF.LoadStoreUnit),
        .hostIoValue,
        .clk,
        .rst
    );
    MemoryAccessArbiter m_MemoryAccessArbiter(
        .bus(m_MemoryAccessArbiterIF.MemoryAccessArbiter),
        .clk,
        .rst
    );

    always_comb begin
        // Currently, MemoryAddrWidth must be equal with DCacheLineWidth and ICacheLineWidth
        memoryAddr[MemoryAddrWidth-1:0] = m_MemoryAccessArbiterIF.memAddr[MemoryAddrWidth-1:0];
        memoryEnable = m_MemoryAccessArbiterIF.memEnable;
        memoryIsWrite = m_MemoryAccessArbiterIF.memIsWrite;
        memoryWriteValue = m_MemoryAccessArbiterIF.memWriteValue;

        m_MemoryAccessArbiterIF.memDone = memoryDone;
        m_MemoryAccessArbiterIF.memReadValue = memoryReadValue;
    end
endmodule