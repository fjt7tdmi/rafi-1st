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

module RegWriteStage(
    ExecuteStageIF.NextStage prevStage,
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
    addr_t debugPc /* verilator public */;
    insn_t debugInsn /* verilator public */;

    always_comb begin
        valid = prevStage.valid;
        commit = valid && !prevStage.trapInfo.valid;
        op = prevStage.op;
        debugPc = prevStage.pc;
        debugInsn = prevStage.debugInsn;
    end

    always_comb begin
        csr.trapInfo.valid = valid && prevStage.trapInfo.valid;
        csr.trapInfo.cause = prevStage.trapInfo.cause;
        csr.trapInfo.value = prevStage.trapInfo.value;
        csr.trapPc = prevStage.pc;
        csr.trapReturn = commit && prevStage.trapReturn;
        csr.trapReturnPrivilege = op.trapReturnPrivilege;

        intRegFile.writeEnable = commit && op.intRegWriteEnable;
        intRegFile.writeAddr = prevStage.dstRegAddr;
        intRegFile.writeValue = prevStage.dstIntRegValue;

        fpRegFile.writeEnable = commit && op.fpRegWriteEnable;
        fpRegFile.writeAddr = prevStage.dstRegAddr;
        fpRegFile.writeValue = prevStage.dstFpRegValue;
    end
endmodule
