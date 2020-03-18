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

// ----------------------------------------------------------------------------
// CSR masks
//
parameter CSR_MASK_MIP = 12'b1111_1111_1111;
parameter CSR_MASK_MIE = 12'b1111_1111_1111;

parameter CSR_MASK_SIP = 12'b0011_0011_0011;
parameter CSR_MASK_SIE = 12'b0011_0011_0011;

parameter CSR_MASK_UIP = 12'b0001_0001_0001;
parameter CSR_MASK_UIE = 12'b0001_0001_0001;

// ----------------------------------------------------------------------------
// Constants
//
parameter VENDOR_ID = 0; // non commercial
parameter ARCHITECTURE_ID = 0; // not implemented
parameter IMPLEMENTATION_ID = 0; // not implemented
parameter HARDWARE_THREAD_ID = 0;

// ----------------------------------------------------------------------------
// Functions
//

function automatic Priv calc_next_priv(
    TrapCause cause,
    word_t machineExceptionDelegate,
    word_t supervisorExceptionDelegate
);
    word_t decodedCause = 1 << cause.code;

    Priv priv = Priv_Machine;
    if ((decodedCause & machineExceptionDelegate) != 0) begin
        priv = Priv_Supervisor;
        if ((decodedCause & supervisorExceptionDelegate) != 0) begin
            priv = Priv_User;
        end
    end

    return priv;
endfunction

function automatic word_t read_xcause(TrapCause cause);
    return {cause.isInterrupt, 27'h000_0000, cause.code};
endfunction

function automatic csr_xstatus_t get_sstatus_mask();
    csr_xstatus_t mask = '0;

    mask.SD     = '1;
    mask.MXR    = '1;
    mask.SUM    = '1;
    mask.XS     = '1;
    mask.FS     = '1;
    mask.SPP    = '1;
    mask.SPIE   = '1;
    mask.UPIE   = '1;
    mask.SIE    = '1;
    mask.UIE    = '1;

    return mask;
endfunction

function automatic csr_xstatus_t get_ustatus_mask();
    csr_xstatus_t mask = '0;

    mask.UPIE   = '1;
    mask.UIE    = '1;

    return mask;
endfunction

function automatic csr_xstatus_t read_sstatus(csr_xstatus_t currentValue);
    return currentValue & get_sstatus_mask();
endfunction

function automatic csr_xstatus_t read_ustatus(csr_xstatus_t currentValue);
    return currentValue & get_ustatus_mask();
endfunction

function automatic csr_xstatus_t write_sstatus(csr_xstatus_t currentValue, csr_xstatus_t write_value);
    csr_xstatus_t mask = get_sstatus_mask();
    return (currentValue & (~mask)) | (write_value & mask);
endfunction

function automatic csr_xstatus_t write_ustatus(csr_xstatus_t currentValue, csr_xstatus_t write_value);
    csr_xstatus_t mask = get_ustatus_mask();
    return (currentValue & (~mask)) | (write_value & mask);
endfunction

function automatic csr_xstatus_t UpdateStatusForTrapM(csr_xstatus_t current, Priv prev_priv);
    csr_xstatus_t ret = current;
    ret.MPIE = current.MIE;
    ret.MIE = 0;
    ret.MPP = prev_priv;
    return ret;
endfunction

function automatic csr_xstatus_t UpdateStatusForTrapS(csr_xstatus_t current, Priv prev_priv);
    csr_xstatus_t ret = current;
    ret.SPIE = current.SIE;
    ret.SIE = 0;
    ret.SPP = prev_priv[0];
    return ret;
endfunction

function automatic csr_xstatus_t UpdateStatusForTrapU(csr_xstatus_t current);
    csr_xstatus_t ret = current;
    ret.UPIE = current.UIE;
    ret.UIE = 0;
    return ret;
endfunction

function automatic csr_xstatus_t UpdateStatusForTrapReturnM(csr_xstatus_t current, Priv mpp, logic mie);
    csr_xstatus_t ret = current;
    ret.MPP = mpp;
    ret.MIE = mie;
    return ret;
endfunction

function automatic csr_xstatus_t UpdateStatusForTrapReturnS(csr_xstatus_t current, Priv spp, logic sie);
    csr_xstatus_t ret = current;
    ret.SPP = spp[0];
    ret.SIE = sie;
    return ret;
endfunction

function automatic word_t read_misa();
    // RV32I
    return 32'b0100_0000_0000_0000_0000_0001_0000_0000;
endfunction

// ----------------------------------------------------------------------------
// Module definition
//
module Csr(
    CsrIF.Csr bus,
    input logic clk,
    input logic rst
);
    // Wires
    Priv next_priv;
    csr_xstatus_t next_status;

    vaddr_t next_pc;

    word_t read_value;
    csr_xstatus_t write_value;

    // Registers (performance counters)
    uint64_t reg_cycle;

    // Registers (written by trap or trap-return)
    Priv reg_priv;

    csr_xstatus_t reg_status;

    word_t reg_uepc;
    TrapCause reg_ucause;
    word_t reg_utval;

    word_t reg_sepc;
    TrapCause reg_scause;
    word_t reg_stval;

    word_t reg_mepc;
    TrapCause reg_mcause;
    word_t reg_mtval;

    // Registers (written by csr insructions)
    csr_xtvec_t reg_utvec;
    word_t reg_uscratch;

    csr_xtvec_t reg_stvec;
    word_t reg_sscratch;
    word_t reg_sedeleg;
    csr_satp_t reg_satp;

    csr_xtvec_t reg_mtvec;
    word_t reg_mscratch;
    word_t reg_medeleg;

    logic [2:0] reg_frm;
    fflags_t reg_fflags;
    csr_xip_t reg_xip;
    csr_xie_t reg_xie;

    always_comb begin
        // read_value
        unique case (bus.readAddr)
        CSR_ADDR_USTATUS:   read_value = read_ustatus(reg_status);
        CSR_ADDR_FFLAGS:    read_value = {27'h0, reg_fflags};
        CSR_ADDR_FRM:       read_value = {29'h0, reg_frm};
        CSR_ADDR_FCSR:      read_value = {24'h0, reg_frm, reg_fflags};
        CSR_ADDR_UIE:       read_value = {20'h0, reg_xie & CSR_MASK_UIE};
        CSR_ADDR_UTVEC:     read_value = reg_utvec;
        CSR_ADDR_USCRATCH:  read_value = reg_uscratch;
        CSR_ADDR_UEPC:      read_value = reg_uepc;
        CSR_ADDR_UCAUSE:    read_value = read_xcause(reg_ucause);
        CSR_ADDR_UTVAL:     read_value = reg_utval;
        CSR_ADDR_UIP:       read_value = {20'h0, reg_xip & CSR_MASK_UIP};

        CSR_ADDR_SSTATUS:   read_value = read_sstatus(reg_status);
        CSR_ADDR_SEDELEG:   read_value = reg_sedeleg;
        CSR_ADDR_SIE:       read_value = {20'h0, reg_xie & CSR_MASK_SIE};
        CSR_ADDR_STVEC:     read_value = reg_stvec;
        CSR_ADDR_SSCRATCH:  read_value = reg_sscratch;
        CSR_ADDR_SEPC:      read_value = reg_sepc;
        CSR_ADDR_SCAUSE:    read_value = read_xcause(reg_scause);
        CSR_ADDR_STVAL:     read_value = reg_stval;
        CSR_ADDR_SIP:       read_value = {20'h0, reg_xip & CSR_MASK_SIP};
        CSR_ADDR_SATP:      read_value = reg_satp;

        CSR_ADDR_MSTATUS:   read_value = reg_status;
        CSR_ADDR_MISA:      read_value = read_misa();
        CSR_ADDR_MEDELEG:   read_value = reg_medeleg;
        CSR_ADDR_MIE:       read_value = {20'h0, reg_xie & CSR_MASK_MIE};
        CSR_ADDR_MTVEC:     read_value = reg_mtvec;
        CSR_ADDR_MSCRATCH:  read_value = reg_mscratch;
        CSR_ADDR_MEPC:      read_value = reg_mepc;
        CSR_ADDR_MCAUSE:    read_value = read_xcause(reg_mcause);
        CSR_ADDR_MTVAL:     read_value = reg_mtval;
        CSR_ADDR_MIP:       read_value = {20'h0, reg_xip & CSR_MASK_MIP};

        CSR_ADDR_CYCLE:     read_value = reg_cycle[31:0];
        CSR_ADDR_TIME:      read_value = reg_cycle[31:0];
        CSR_ADDR_INSTRET:   read_value = '0; // TODO: impl
        CSR_ADDR_CYCLEH:    read_value = reg_cycle[63:32];
        CSR_ADDR_TIMEH:     read_value = reg_cycle[63:32];
        CSR_ADDR_INSTRETH:  read_value = '0; // TODO: impl

        CSR_ADDR_MVENDORID: read_value = VENDOR_ID;
        CSR_ADDR_MARCHID:   read_value = ARCHITECTURE_ID;
        CSR_ADDR_MIMPID:    read_value = IMPLEMENTATION_ID;
        CSR_ADDR_MHARTID:   read_value = HARDWARE_THREAD_ID;
        default:            read_value = '0;
        endcase

        // write_value
        write_value = bus.writeValue;

        // next_priv
        if (bus.trapInfo.valid) begin
            next_priv = calc_next_priv(
                .cause(bus.trapInfo.cause),
                .machineExceptionDelegate(reg_medeleg),
                .supervisorExceptionDelegate(reg_sedeleg)
            );
        end
        else if (bus.trapReturn) begin
            if (bus.trapReturnPriv == Priv_Machine) begin
                next_priv = Priv'(reg_status.MPP);
            end
            else if (bus.trapReturnPriv == Priv_Supervisor) begin
                next_priv = Priv'(reg_status.SPP);
            end
            else begin
                next_priv = Priv_User;
            end
        end
        else begin
            next_priv = reg_priv;
        end

        // next_status
        if (bus.trapInfo.valid) begin
            if (next_priv == Priv_Machine) begin
                next_status = UpdateStatusForTrapM(reg_status, reg_priv);
            end
            else if (next_priv == Priv_Supervisor) begin
                next_status = UpdateStatusForTrapS(reg_status, reg_priv);
            end
            else begin
                next_status = UpdateStatusForTrapU(reg_status);
            end
        end
        else if (bus.trapReturn) begin
            if (bus.trapReturnPriv == Priv_Machine) begin
                next_status = UpdateStatusForTrapReturnM(reg_status, Priv_User, reg_status.MPIE);
            end
            else if (next_priv == Priv_Supervisor) begin
                next_status = UpdateStatusForTrapReturnS(reg_status, Priv_User, reg_status.SPIE);
            end
            else begin
                next_status = reg_status;
            end
        end
        else if (bus.writeEnable && bus.writeAddr == CSR_ADDR_MSTATUS) begin
            next_status = write_value;
        end
        else if (bus.writeEnable && bus.writeAddr == CSR_ADDR_SSTATUS) begin
            next_status = write_sstatus(reg_status, write_value);
        end
        else if (bus.writeEnable && bus.writeAddr == CSR_ADDR_USTATUS) begin
            next_status = write_ustatus(reg_status, write_value);
        end
        else begin
            next_status = reg_status;
        end

        // bus output
        bus.readValue = read_value;
        bus.priv = reg_priv;
        bus.satp = reg_satp;
        bus.status = reg_status;
        bus.ip = reg_xip;
        bus.ie = reg_xie;
        bus.frm = reg_frm;
        bus.mtvec = reg_mtvec;
        bus.stvec = reg_stvec;
        bus.utvec = reg_utvec;
        bus.mepc = reg_mepc;
        bus.sepc = reg_sepc;
        bus.uepc = reg_uepc;
        bus.nextPriv = next_priv;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_cycle <= '0;

            reg_priv <= Priv_Machine;
            reg_status <= '0;

            reg_uepc <= '0;
            reg_ucause <= '0;
            reg_utval <= '0;

            reg_sepc <= '0;
            reg_scause <= '0;
            reg_stval <= '0;

            reg_mepc <= '0;
            reg_mcause <= '0;
            reg_mtval <= '0;

            reg_utvec <= '0;
            reg_uscratch <= '0;

            reg_stvec <= '0;
            reg_sscratch <= '0;
            reg_sedeleg <= '0;
            reg_satp <= '0;

            reg_mtvec <= '0;
            reg_medeleg <= '0;
            reg_mscratch <= '0;

            reg_fflags <= '0;
            reg_frm <= '0;
            reg_xip <= '0;
            reg_xie <= '0;
        end
        else begin
            // Performance Counters
            reg_cycle <= reg_cycle + 1;

            // Registers written by trap or trap-return
            reg_priv <= next_priv;
            reg_status <= next_status;

            if (bus.trapInfo.valid && next_priv == Priv_User) begin
                reg_uepc <= bus.trapPc;
                reg_ucause <= bus.trapInfo.cause;
                reg_utval <= bus.trapInfo.value;
            end
            else begin
                reg_uepc <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_UEPC)
                    ? bus.writeValue
                    : reg_uepc;
                reg_ucause <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_UCAUSE)
                    ? {bus.writeValue[31], bus.writeValue[3:0]}
                    : reg_ucause;
                reg_utval <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_UTVAL)
                    ? bus.writeValue
                    : reg_utval;
            end

            if (bus.trapInfo.valid && next_priv == Priv_Supervisor) begin
                reg_sepc <= bus.trapPc;
                reg_scause <= bus.trapInfo.cause;
                reg_stval <= bus.trapInfo.value;
            end
            else begin
                reg_sepc <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_SEPC)
                    ? bus.writeValue
                    : reg_sepc;
                reg_scause <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_SCAUSE)
                    ? {bus.writeValue[31], bus.writeValue[3:0]}
                    : reg_scause;
                reg_stval <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_STVAL)
                    ? bus.writeValue
                    : reg_stval;
            end

            if (bus.trapInfo.valid && next_priv == Priv_Machine) begin
                reg_mepc <= bus.trapPc;
                reg_mcause <= bus.trapInfo.cause;
                reg_mtval <= bus.trapInfo.value;
            end
            else begin
                reg_mepc <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_MEPC)
                    ? bus.writeValue
                    : reg_mepc;
                reg_mcause <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_MCAUSE)
                    ? {bus.writeValue[31], bus.writeValue[3:0]}
                    : reg_mcause;
                reg_mtval <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_MTVAL)
                    ? bus.writeValue
                    : reg_mtval;
            end

            // Registers written by csr insructions
            reg_utvec <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_UTVEC)
                ? bus.writeValue
                : reg_utvec;

            reg_uscratch <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_USCRATCH)
                ? bus.writeValue
                : reg_uscratch;

            reg_stvec <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_STVEC)
                ? bus.writeValue
                : reg_stvec;

            reg_sscratch <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_SSCRATCH)
                ? bus.writeValue
                : reg_sscratch;

            reg_sedeleg <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_SEDELEG)
                ? bus.writeValue
                : reg_sedeleg;

            reg_satp <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_SATP)
                ? bus.writeValue
                : reg_satp;

            reg_mtvec <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_MTVEC)
                ? bus.writeValue
                : reg_mtvec;

            reg_mscratch <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_MSCRATCH)
                ? bus.writeValue
                : reg_mscratch;

            reg_medeleg <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_MEDELEG)
                ? bus.writeValue
                : reg_medeleg;

            if (bus.writeEnable && bus.writeAddr == CSR_ADDR_FFLAGS) begin
                reg_fflags <= bus.writeValue[4:0];
                reg_frm <= reg_frm;
            end
            else if (bus.writeEnable && bus.writeAddr == CSR_ADDR_FRM) begin
                reg_fflags <= reg_fflags;
                reg_frm <= bus.writeValue[2:0];
            end
            else if (bus.writeEnable && bus.writeAddr == CSR_ADDR_FCSR) begin
                reg_fflags <= bus.writeValue[4:0];
                reg_frm <= bus.writeValue[7:5];
            end
            else if (bus.write_fflags) begin
                reg_fflags <= bus.write_fflags_value;
                reg_frm <= reg_frm;
            end
            else begin
                reg_fflags <= reg_fflags;
                reg_frm <= reg_frm;
            end

            if (bus.writeEnable && bus.writeAddr == CSR_ADDR_MIP) begin
                reg_xip <= bus.writeValue[11:0] & CSR_MASK_MIP;
            end
            else if (bus.writeEnable && bus.writeAddr == CSR_ADDR_SIP) begin
                reg_xip <= bus.writeValue[11:0] & CSR_MASK_SIP;
            end
            else if (bus.writeEnable && bus.writeAddr == CSR_ADDR_SIP) begin
                reg_xip <= bus.writeValue[11:0] & CSR_MASK_UIP;
            end
            else begin
                reg_xip <= reg_xip;
            end

            if (bus.writeEnable && bus.writeAddr == CSR_ADDR_MIE) begin
                reg_xie <= bus.writeValue[11:0] & CSR_MASK_MIE;
            end
            else if (bus.writeEnable && bus.writeAddr == CSR_ADDR_SIE) begin
                reg_xie <= bus.writeValue[11:0] & CSR_MASK_SIE;
            end
            else if (bus.writeEnable && bus.writeAddr == CSR_ADDR_SIE) begin
                reg_xie <= bus.writeValue[11:0] & CSR_MASK_UIE;
            end
            else begin
                reg_xie <= reg_xie;
            end
        end
    end
endmodule
