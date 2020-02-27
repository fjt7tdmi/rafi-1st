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

import RafiTypes::*;

module PipelineController(
    PipelineControllerIF.PipelineController bus,
    CsrIF.PipelineController csr,
    input logic clk,
    input logic rst
);
    always_comb begin
        if (bus.trapValid && csr.nextPriv == Privilege_Machine) begin
            bus.nextPc = {csr.mtvec.base, 2'b00};
        end
        else if (bus.trapValid && csr.nextPriv == Privilege_Supervisor) begin
            bus.nextPc = {csr.stvec.base, 2'b00};
        end
        else if (bus.trapValid && csr.nextPriv == Privilege_User) begin
            bus.nextPc = {csr.utvec.base, 2'b00};
        end
        else if (bus.trapReturnValid && bus.trapReturnPriv == Privilege_Machine) begin
            bus.nextPc = csr.mepc;
        end
        else if (bus.trapReturnValid && bus.trapReturnPriv == Privilege_Supervisor) begin
            bus.nextPc = csr.sepc;
        end
        else if (bus.trapReturnValid && bus.trapReturnPriv == Privilege_User) begin
            bus.nextPc = csr.uepc;
        end
        else begin
            bus.nextPc = bus.flushTarget;
        end

        bus.flush = bus.flushReq || bus.trapValid || bus.trapReturnValid;
        bus.ifStall = bus.exStallReq;
        bus.idStall = bus.exStallReq;
        bus.rrStall = bus.exStallReq;
        bus.bypassStall = bus.exStallReq;
    end
endmodule