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
    csr_xtvec_t xtvec;
    always_comb begin
        unique case (csr.nextPriv)
        Privilege_Machine:      xtvec = csr.mtvec;
        Privilege_Supervisor:   xtvec = csr.stvec;
        Privilege_User:         xtvec = csr.utvec;
        default:                xtvec = '0;
        endcase
    end

    addr_t trap_vector;
    always_comb begin
        if (xtvec.mode == 2'b01 && bus.trapCause.isInterrupt) begin
            /* verilator lint_off WIDTH */
            trap_vector = {xtvec.base + bus.trapCause.code, 2'b00};
        end
        else begin
            trap_vector = {xtvec.base, 2'b00};
        end
    end

    addr_t trap_return_pc;
    always_comb begin
        unique case (bus.trapReturnPriv)
        Privilege_Machine:      trap_return_pc = csr.mepc;
        Privilege_Supervisor:   trap_return_pc = csr.sepc;
        Privilege_User:         trap_return_pc = csr.uepc;
        default:                trap_return_pc = '0;
        endcase
    end

    always_comb begin
        if (bus.trapValid) begin
            bus.nextPc = trap_vector;
        end
        else if (bus.trapReturnValid) begin
            bus.nextPc = trap_return_pc;
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