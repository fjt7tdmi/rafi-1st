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
import RafiTypes::*;

module RegWriteStage(
    ExecuteStageIF.NextStage prevStage,
    PipelineControllerIF.RegWriteStage ctrl,
    CsrIF.RegWriteStage csr,
    IntRegFileIF.RegWriteStage intRegFile,
    FpRegFileIF.RegWriteStage fpRegFile,
    input   logic clk,
    input   logic rst
);
    // Wires
    logic valid /* verilator public */;
    logic commit;
    Op op;
    vaddr_t pc /* verilator public */;
    insn_t insn /* verilator public */;

    always_comb begin
        valid = prevStage.valid;
        commit = valid && !prevStage.trapInfo.valid;
        op = prevStage.op;
        pc = prevStage.pc;
        insn = prevStage.insn;
    end

    always_comb begin
        ctrl.trapValid = valid && prevStage.trapInfo.valid;
        ctrl.trapCause = prevStage.trapInfo.cause;
        ctrl.trapReturnValid = commit && prevStage.trapReturn;
        ctrl.trapReturnPriv = op.trapReturnPrivilege;

        csr.trapInfo.valid = valid && prevStage.trapInfo.valid;
        csr.trapInfo.cause = prevStage.trapInfo.cause;
        csr.trapInfo.value = prevStage.trapInfo.value;
        csr.trapPc = prevStage.pc;
        csr.trapReturn = commit && prevStage.trapReturn;
        csr.trapReturnPrivilege = op.trapReturnPrivilege;

        intRegFile.writeEnable = commit && op.intRegWriteEnable;
        intRegFile.writeAddr = op.rd;
        intRegFile.writeValue = prevStage.dstIntRegValue;

        fpRegFile.writeEnable = commit && op.fpRegWriteEnable;
        fpRegFile.writeAddr = op.rd;
        fpRegFile.writeValue = prevStage.dstFpRegValue;
    end
endmodule
