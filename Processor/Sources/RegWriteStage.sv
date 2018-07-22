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
    MemoryAccessStageIF.NextStage prevStage,
    ControlStatusRegisterIF.RegWriteStage csr,
    RegFileIF.RegWriteStage regFile,
    input   logic clk,
    input   logic rst
);
    // Wires
    logic valid;
    logic commit;
    Op op;
   
    always_comb begin
        valid = prevStage.valid;
        commit = valid && !prevStage.trapInfo.valid;
        op = prevStage.op;

        csr.writeEnable = commit && op.csrWriteEnable;
        csr.writeAddr = prevStage.csrAddr;
        csr.writeValue = prevStage.dstCsrValue;
        csr.trapInfo.valid = valid && prevStage.trapInfo.valid;
        csr.trapInfo.cause = prevStage.trapInfo.cause;
        csr.trapInfo.value = prevStage.trapInfo.value;
        csr.trapPc = prevStage.pc;
        csr.trapReturn = commit && prevStage.trapReturn;
        csr.trapReturnPrivilege = op.trapReturnPrivilege;

        regFile.writeEnable = commit && op.regWriteEnable;
        regFile.writeAddr = prevStage.dstRegAddr;
        regFile.writeValue = prevStage.dstRegValue;
    end
endmodule
