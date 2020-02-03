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

import ProcessorTypes::*;

// TODO: Implement Interrupt

// ----------------------------------------------------------------------------
// CSR addresses
//

// User Trap Setup
parameter CSR_ADDR_USTATUS  = 12'h000;
parameter CSR_ADDR_UIE      = 12'h004;
parameter CSR_ADDR_UTVEC    = 12'h005;

// User Floating-Point CSRs
parameter CSR_ADDR_FFLAGS   = 12'h001;
parameter CSR_ADDR_FRM      = 12'h002;
parameter CSR_ADDR_FCSR     = 12'h003;

// User Trap Handling
parameter CSR_ADDR_USCRATCH = 12'h040;
parameter CSR_ADDR_UEPC     = 12'h041;
parameter CSR_ADDR_UCAUSE   = 12'h042;
parameter CSR_ADDR_UTVAL    = 12'h043;
parameter CSR_ADDR_UIP      = 12'h044;

// Supervisor Trap Setup
parameter CSR_ADDR_SSTATUS      = 12'h100;
parameter CSR_ADDR_SEDELEG      = 12'h102;
parameter CSR_ADDR_SIDELEG      = 12'h103;
parameter CSR_ADDR_SIE          = 12'h104;
parameter CSR_ADDR_STVEC        = 12'h105;
parameter CSR_ADDR_SCOUNTEREN   = 12'h106; // hard-wired to 0

// User Trap Handling
parameter CSR_ADDR_SSCRATCH = 12'h140;
parameter CSR_ADDR_SEPC     = 12'h141;
parameter CSR_ADDR_SCAUSE   = 12'h142;
parameter CSR_ADDR_STVAL    = 12'h143;
parameter CSR_ADDR_SIP      = 12'h144;

// Supervisor Protection and Translation
parameter CSR_ADDR_SATP     = 12'h180;

// Machine Trap Setup
parameter CSR_ADDR_MSTATUS      = 12'h300;
parameter CSR_ADDR_MISA         = 12'h301;
parameter CSR_ADDR_MEDELEG      = 12'h302;
parameter CSR_ADDR_MIDELEG      = 12'h303;
parameter CSR_ADDR_MIE          = 12'h304;
parameter CSR_ADDR_MTVEC        = 12'h305;
parameter CSR_ADDR_MCOUNTEREN   = 12'h306; // hard-wired to 0

// Machine Trap handling
parameter CSR_ADDR_MSCRATCH = 12'h340;
parameter CSR_ADDR_MEPC     = 12'h341;
parameter CSR_ADDR_MCAUSE   = 12'h342;
parameter CSR_ADDR_MTVAL    = 12'h343;
parameter CSR_ADDR_MIP      = 12'h344;

// User Counter/Timers
parameter CSR_ADDR_CYCLE    = 12'hc00;
parameter CSR_ADDR_TIME     = 12'hc01;
parameter CSR_ADDR_INSTRET  = 12'hc02;

parameter CSR_ADDR_CYCLEH   = 12'hc80;
parameter CSR_ADDR_TIMEH    = 12'hc81;
parameter CSR_ADDR_INSTRETH = 12'hc82;

// Machine Information Registers
parameter CSR_ADDR_MVENDORID    = 12'hf11;
parameter CSR_ADDR_MARCHID      = 12'hf12;
parameter CSR_ADDR_MIMPID       = 12'hf13;
parameter CSR_ADDR_MHARTID      = 12'hf14;

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

function automatic Privilege calc_next_privilege(
    exception_code_t cause,
    word_t machineExceptionDelegate,
    word_t supervisorExceptionDelegate
);
    word_t decodedCause = 1 << cause;

    Privilege privilege = Privilege_Machine;
    if ((decodedCause & machineExceptionDelegate) != 0) begin
        privilege = Privilege_Supervisor;
        if ((decodedCause & supervisorExceptionDelegate) != 0) begin
            privilege = Privilege_User;
        end
    end

    return privilege;
endfunction

function automatic word_t read_xcause(exception_code_t trapValue);
    // bit 31 is 'interrupt' bit, but not implemented
    return {28'h000_0000, trapValue};
endfunction

function automatic csr_xstatus_t get_sstatus_mask();
    csr_xstatus_t mask = '0;

    mask.sd     = '1;
    mask.mxr    = '1;
    mask.sum_    = '1;
    mask.xs     = '1;
    mask.fs     = '1;
    mask.spp    = '1;
    mask.spie   = '1;
    mask.upie   = '1;
    mask.sie    = '1;
    mask.uie    = '1;

    return mask;
endfunction

function automatic csr_xstatus_t get_ustatus_mask();
    csr_xstatus_t mask = '0;

    mask.upie   = '1;
    mask.uie    = '1;

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

function automatic csr_xstatus_t update_xstatus_mpp(csr_xstatus_t current, Privilege mpp);
    csr_xstatus_t ret = current;
    ret.mpp = mpp;
    return ret;
endfunction

function automatic csr_xstatus_t update_xstatus_mpp_mie(csr_xstatus_t current, Privilege mpp, logic mie);
    csr_xstatus_t ret = current;
    ret.mpp = mpp;
    ret.mie = mie;
    return ret;
endfunction

function automatic csr_xstatus_t update_xstatus_spp(csr_xstatus_t current, Privilege spp);
    csr_xstatus_t ret = current;
    ret.spp = spp[0];
    return ret;
endfunction

function automatic csr_xstatus_t update_xstatus_spp_sie(csr_xstatus_t current, Privilege spp, logic sie);
    csr_xstatus_t ret = current;
    ret.spp = spp[0];
    ret.sie = sie;
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
    Privilege next_priv;
    csr_xstatus_t next_status;

    addr_t next_pc;

    word_t read_value;
    csr_xstatus_t write_value;

    // Registers (performance counters)
    uint64_t reg_cycle;

    // Registers (written by trap or trap-return)
    Privilege reg_priv;

    csr_xstatus_t reg_status;

    word_t reg_uepc;
    exception_code_t reg_ucause;
    word_t reg_utval;

    word_t reg_sepc;
    exception_code_t reg_scause;
    word_t reg_stval;

    word_t reg_mepc;
    exception_code_t reg_mcause;
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
    logic [4:0] reg_fflags;

    always_comb begin
        // read_value
        unique case (bus.readAddr)
        CSR_ADDR_USTATUS:   read_value = read_ustatus(reg_status);
        CSR_ADDR_FFLAGS:    read_value = {27'h0, reg_fflags};
        CSR_ADDR_FRM:       read_value = {29'h0, reg_frm};
        CSR_ADDR_FCSR:      read_value = {24'h0, reg_frm, reg_fflags};
        CSR_ADDR_UTVEC:     read_value = reg_utvec;
        CSR_ADDR_USCRATCH:  read_value = reg_uscratch;
        CSR_ADDR_UEPC:      read_value = reg_uepc;
        CSR_ADDR_UCAUSE:    read_value = read_xcause(reg_ucause);
        CSR_ADDR_UTVAL:     read_value = reg_utval;

        CSR_ADDR_SSTATUS:   read_value = read_sstatus(reg_status);
        CSR_ADDR_SEDELEG:   read_value = reg_sedeleg;
        CSR_ADDR_STVEC:     read_value = reg_stvec;
        CSR_ADDR_SSCRATCH:  read_value = reg_sscratch;
        CSR_ADDR_SEPC:      read_value = reg_sepc;
        CSR_ADDR_SCAUSE:    read_value = read_xcause(reg_scause);
        CSR_ADDR_STVAL:     read_value = reg_stval;
        CSR_ADDR_SATP:      read_value = reg_satp;

        CSR_ADDR_MSTATUS:   read_value = reg_status;
        CSR_ADDR_MISA:      read_value = read_misa();
        CSR_ADDR_MEDELEG:   read_value = reg_medeleg;
        CSR_ADDR_MTVEC:     read_value = reg_mtvec;
        CSR_ADDR_MSCRATCH:  read_value = reg_mscratch;
        CSR_ADDR_MEPC:      read_value = reg_mepc;
        CSR_ADDR_MCAUSE:    read_value = read_xcause(reg_mcause);
        CSR_ADDR_MTVAL:     read_value = reg_mtval;

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
            next_priv = calc_next_privilege(
                .cause(bus.trapInfo.cause),
                .machineExceptionDelegate(reg_medeleg),
                .supervisorExceptionDelegate(reg_sedeleg)
            );
        end
        else if (bus.trapReturn) begin
            if (bus.trapReturnPrivilege == Privilege_Machine) begin
                next_priv = Privilege'(reg_status.mpp);
            end
            else if (bus.trapReturnPrivilege == Privilege_Supervisor) begin
                next_priv = Privilege'(reg_status.spp);
            end
            else begin
                next_priv = Privilege_User;
            end
        end
        else begin
            next_priv = reg_priv;
        end

        // next_status
        if (bus.trapInfo.valid) begin
            if (next_priv == Privilege_Machine) begin
                next_status = update_xstatus_mpp(reg_status, reg_priv);
            end
            else if (next_priv == Privilege_Supervisor) begin
                next_status = update_xstatus_spp(reg_status, reg_priv);
            end
            else begin
                next_status = reg_status;
            end
        end
        else if (bus.trapReturn) begin
            if (bus.trapReturnPrivilege == Privilege_Machine) begin
                next_status = update_xstatus_mpp_mie(reg_status, Privilege_User, reg_status.mpie);
            end
            else if (next_priv == Privilege_Supervisor) begin
                next_status = update_xstatus_spp_sie(reg_status, Privilege_User, reg_status.spie);
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

        // next_pc
        if (bus.trapInfo.valid && next_priv == Privilege_Machine) begin
            next_pc = {reg_mtvec.base, 2'b00};
        end
        else if (bus.trapInfo.valid && next_priv == Privilege_Supervisor) begin
            next_pc = {reg_stvec.base, 2'b00};
        end
        else if (bus.trapInfo.valid && next_priv == Privilege_User) begin
            next_pc = {reg_utvec.base, 2'b00};
        end
        else if (bus.trapReturn && bus.trapReturnPrivilege == Privilege_Machine) begin
            next_pc = reg_mepc;
        end
        else if (bus.trapReturn && bus.trapReturnPrivilege == Privilege_Supervisor) begin
            next_pc = reg_sepc;
        end
        else if (bus.trapReturn && bus.trapReturnPrivilege == Privilege_User) begin
            next_pc = reg_uepc;
        end
        else begin
            next_pc = '0;
        end

        // bus output
        bus.nextPc = next_pc;
        bus.readValue = read_value;
        bus.readIllegal = 0; // TEMP: Disable illegal access exception for riscv-tests

        bus.satp = reg_satp;
        bus.mstatus = reg_status;
        bus.privilege = reg_priv;
        bus.trapSupervisorReturn = reg_status.tsr;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_cycle <= '0;

            reg_priv <= Privilege_Machine;
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
        end
        else begin
            // Performance Counters
            reg_cycle <= reg_cycle + 1;

            // Registers written by trap or trap-return
            reg_priv <= next_priv;
            reg_status <= next_status;

            if (bus.trapInfo.valid && next_priv == Privilege_User) begin
                reg_uepc <= bus.trapPc;
                reg_ucause <= bus.trapInfo.cause;
                reg_utval <= bus.trapInfo.value;
            end
            else begin
                reg_uepc <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_UEPC)
                    ? bus.writeValue
                    : reg_uepc;
                reg_ucause <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_UCAUSE)
                    ? bus.writeValue[3:0]
                    : reg_ucause;
                reg_utval <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_UTVAL)
                    ? bus.writeValue
                    : reg_utval;
            end

            if (bus.trapInfo.valid && next_priv == Privilege_Supervisor) begin
                reg_sepc <= bus.trapPc;
                reg_scause <= bus.trapInfo.cause;
                reg_stval <= bus.trapInfo.value;
            end
            else begin
                reg_sepc <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_SEPC)
                    ? bus.writeValue
                    : reg_sepc;
                reg_scause <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_SCAUSE)
                    ? bus.writeValue[3:0]
                    : reg_scause;
                reg_stval <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_STVAL)
                    ? bus.writeValue
                    : reg_stval;
            end

            if (bus.trapInfo.valid && next_priv == Privilege_Machine) begin
                reg_mepc <= bus.trapPc;
                reg_mcause <= bus.trapInfo.cause;
                reg_mtval <= bus.trapInfo.value;
            end
            else begin
                reg_mepc <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_MEPC)
                    ? bus.writeValue
                    : reg_mepc;
                reg_mcause <= (bus.writeEnable && bus.writeAddr == CSR_ADDR_MCAUSE)
                    ? bus.writeValue[3:0]
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
            else begin
                reg_fflags <= reg_fflags;
                reg_frm <= reg_frm;
            end
        end
    end
endmodule