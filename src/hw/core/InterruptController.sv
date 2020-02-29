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

module InterruptController(
    InterruptControllerIF.InterruptController bus,
    CsrIF.InterruptController csr,
    input logic clk,
    input logic rst
);
    function automatic logic [3:0] GetInterruptCode(csr_xip_t irq);
        if (irq.MEIP) return INTERRUPT_CODE_M_EXTERNAL;
        if (irq.MTIP) return INTERRUPT_CODE_M_TIMER;
        if (irq.MSIP) return INTERRUPT_CODE_M_SOFTWARE;
        if (irq.SEIP) return INTERRUPT_CODE_S_EXTERNAL;
        if (irq.STIP) return INTERRUPT_CODE_S_TIMER;
        if (irq.SSIP) return INTERRUPT_CODE_S_SOFTWARE;
        if (irq.UEIP) return INTERRUPT_CODE_U_EXTERNAL;
        if (irq.UTIP) return INTERRUPT_CODE_U_TIMER;
        if (irq.USIP) return INTERRUPT_CODE_U_SOFTWARE;
        
        return '0;
    endfunction

    logic enabled;
    always_comb begin
        unique case (csr.privilege)
        Privilege_User:       enabled = csr.status.UIE;
        Privilege_Supervisor: enabled = csr.status.SIE;
        Privilege_Machine:    enabled = csr.status.MIE;
        default:              enabled = '0;
        endcase
    end

    csr_xip_t irq;
    always_comb begin
        irq = csr.ip & csr.ie;
    end

    always_comb begin
        bus.valid = enabled && (|irq);
        bus.code = GetInterruptCode(irq);
    end
endmodule
