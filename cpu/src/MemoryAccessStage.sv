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

import OpTypes::*;
import ProcessorTypes::*;
import LoadStoreUnitTypes::*;

module MemoryAccessStage(
    ExecuteStageIF.NextStage prevStage,
    MemoryAccessStageIF.ThisStage nextStage,
    LoadStoreUnitIF.MemoryAccessStage loadStoreUnit,
    FetchUnitIF.MemoryAccessStage fetchUnit,
    PipelineControllerIF.MemoryAccessStage ctrl,
    BypassLogicIF.MemoryAccessStage bypass,
    input logic clk,
    input logic rst
);
    // Registers
    uint64_t r_OpCommitCount;

    // Wires
    uint64_t nextOpCommitCount;
    logic valid;
    Op op;
    word_t dstRegValue;
    TrapInfo trapInfo;

    always_comb begin
        valid = prevStage.valid;
        op = prevStage.op;
    end

    always_comb begin
        dstRegValue = (op.regWriteSrcType == RegWriteSrcType_Memory) ?
            loadStoreUnit.result :
            prevStage.dstRegValue;
        nextOpCommitCount = valid ? r_OpCommitCount + 1 : r_OpCommitCount;
    end

    // trapInfo
    always_comb begin
        if (valid && !prevStage.trapInfo.valid && loadStoreUnit.fault) begin
            trapInfo.valid = '1;
            trapInfo.cause = op.isStore ? ExceptionCode_StorePageFault : ExceptionCode_LoadPageFault;
            trapInfo.value = prevStage.memAddr;
        end
        else begin
            trapInfo = prevStage.trapInfo;
        end
    end

    always_comb begin
        loadStoreUnit.addr = prevStage.memAddr;
        loadStoreUnit.enable = valid && (op.isLoad || op.isStore || op.isFence || op.isAtomic) && !prevStage.trapInfo.valid;
        loadStoreUnit.invalidateTlb = valid && op.isFence && op.fenceType == FenceType_Vma;
        loadStoreUnit.loadStoreType = op.loadStoreType;
        loadStoreUnit.atomicType = op.atomicType;
        loadStoreUnit.storeRegValue = prevStage.storeRegValue;

        if (op.isLoad) begin
            loadStoreUnit.command = LoadStoreUnitCommand_Load;
        end
        else if (op.isStore) begin
            loadStoreUnit.command = LoadStoreUnitCommand_Store;
        end
        else if (op.isFence && (op.fenceType == FenceType_I || op.fenceType == FenceType_Vma)) begin
            loadStoreUnit.command = LoadStoreUnitCommand_Invalidate;
        end
        else if (op.isAtomic && op.atomicType == AtomicType_LoadReserved) begin
            loadStoreUnit.command = LoadStoreUnitCommand_LoadReserved;
        end
        else if (op.isAtomic && op.atomicType == AtomicType_StoreConditional) begin
            loadStoreUnit.command = LoadStoreUnitCommand_StoreConditional;
        end
        else if (op.isAtomic) begin
            loadStoreUnit.command = LoadStoreUnitCommand_AtomicMemOp;
        end
        else begin
            loadStoreUnit.command = LoadStoreUnitCommand_None;
        end
    end

    always_comb begin
        fetchUnit.invalidateICache = valid && op.isFence &&
            (op.fenceType == FenceType_I || op.fenceType == FenceType_Vma);
        fetchUnit.invalidateTlb = valid && op.isFence && op.fenceType == FenceType_Vma;
    end

    always_comb begin
        ctrl.opCommitCount = r_OpCommitCount;
        ctrl.maStallReq = loadStoreUnit.enable && !loadStoreUnit.done;
        // TODO: implement for VM (page fault exception, etc.)
        ctrl.flushReq = valid && !ctrl.maStallReq && (
            (op.isBranch && prevStage.branchTaken) ||
            op.csrWriteEnable ||
            fetchUnit.invalidateICache ||
            fetchUnit.invalidateTlb ||
            trapInfo.valid ||
            prevStage.trapReturn);

        if (op.isBranch && prevStage.branchTaken) begin
            ctrl.nextPc = prevStage.branchTarget;
        end
        else begin
            ctrl.nextPc = prevStage.pc + InsnSize;
        end
    end

    always_comb begin
        bypass.loadWriteAddr = prevStage.dstRegAddr;
        bypass.loadWriteValue = dstRegValue;
        bypass.loadWriteEnable = valid && op.regWriteEnable && (op.isLoad || op.isAtomic) && !ctrl.maStallReq;
    end

    always_ff @(posedge clk) begin
        if (rst || ctrl.maStallReq) begin
            nextStage.valid <= '0;
            nextStage.op <= '0;
            nextStage.pc <= '0;
            nextStage.csrAddr <= '0;
            nextStage.dstCsrValue <= '0;
            nextStage.dstRegAddr <= '0;
            nextStage.dstRegValue <= '0;
            nextStage.branchTaken <= '0;
            nextStage.branchTarget <= '0;
            nextStage.trapInfo <= '0;
            nextStage.trapReturn <= '0;
            nextStage.debugInsn <= '0;
        end
        else begin
            nextStage.valid <= prevStage.valid;
            nextStage.op <= prevStage.op;
            nextStage.pc <= prevStage.pc;
            nextStage.csrAddr <= prevStage.csrAddr;
            nextStage.dstCsrValue <= prevStage.dstCsrValue;
            nextStage.dstRegAddr <= prevStage.dstRegAddr;
            nextStage.dstRegValue <= dstRegValue;
            nextStage.branchTaken <= prevStage.branchTaken;
            nextStage.branchTarget <= prevStage.branchTarget;
            nextStage.trapInfo <= trapInfo;
            nextStage.trapReturn <= prevStage.trapReturn;
            nextStage.debugInsn <= prevStage.debugInsn;
        end

        if (rst) begin
            r_OpCommitCount <= '0;
        end
        else if (ctrl.maStallReq) begin
            r_OpCommitCount <= r_OpCommitCount;
        end
        else begin
            r_OpCommitCount <= nextOpCommitCount;
        end
    end
endmodule
