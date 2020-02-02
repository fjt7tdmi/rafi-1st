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
parameter csr_addr_ustatus  = 12'h000;
parameter csr_addr_uie      = 12'h004;
parameter csr_addr_utvec    = 12'h005;

// User Floating-Point CSRs
parameter csr_addr_fflags   = 12'h001;
parameter csr_addr_frm      = 12'h002;
parameter csr_addr_fcsr     = 12'h003;

// User Trap Handling
parameter csr_addr_uscratch = 12'h040;
parameter csr_addr_uepc     = 12'h041;
parameter csr_addr_ucause   = 12'h042;
parameter csr_addr_utval    = 12'h043;
parameter csr_addr_uip      = 12'h044;

// Supervisor Trap Setup
parameter csr_addr_sstatus      = 12'h100;
parameter csr_addr_sedeleg      = 12'h102;
parameter csr_addr_sideleg      = 12'h103;
parameter csr_addr_sie          = 12'h104;
parameter csr_addr_stvec        = 12'h105;
parameter csr_addr_scounteren   = 12'h106; // hard-wired to 0

// User Trap Handling
parameter csr_addr_sscratch = 12'h140;
parameter csr_addr_sepc     = 12'h141;
parameter csr_addr_scause   = 12'h142;
parameter csr_addr_stval    = 12'h143;
parameter csr_addr_sip      = 12'h144;

// Supervisor Protection and Translation
parameter csr_addr_satp     = 12'h180;

// Machine Trap Setup
parameter csr_addr_mstatus      = 12'h300;
parameter csr_addr_misa         = 12'h301;
parameter csr_addr_medeleg      = 12'h302;
parameter csr_addr_mideleg      = 12'h303;
parameter csr_addr_mie          = 12'h304;
parameter csr_addr_mtvec        = 12'h305;
parameter csr_addr_mcounteren   = 12'h306; // hard-wired to 0

// Machine Trap handling
parameter csr_addr_mscratch = 12'h340;
parameter csr_addr_mepc     = 12'h341;
parameter csr_addr_mcause   = 12'h342;
parameter csr_addr_mtval    = 12'h343;
parameter csr_addr_mip      = 12'h344;

// User Counter/Timers
parameter csr_addr_cycle    = 12'hc00;
parameter csr_addr_time     = 12'hc01;
parameter csr_addr_instret  = 12'hc02;

parameter csr_addr_cycleh   = 12'hc80;
parameter csr_addr_timeh    = 12'hc81;
parameter csr_addr_instreth = 12'hc82;

// Machine Information Registers
parameter csr_addr_mvendorid    = 12'hf11;
parameter csr_addr_marchid      = 12'hf12;
parameter csr_addr_mimpid       = 12'hf13;
parameter csr_addr_mhartid      = 12'hf14;

// ----------------------------------------------------------------------------
// Constants
//
parameter VendorId = 0; // non commercial
parameter ArchitectureId = 0; // not implemented
parameter ImplementationId = 0; // not implemented
parameter HardwareThreadId = 0;

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

function automatic csr_xstatus_t write_sstatus(csr_xstatus_t currentValue, csr_xstatus_t writeValue);
    csr_xstatus_t mask = get_sstatus_mask();
    return (currentValue & (~mask)) | (writeValue & mask);
endfunction

function automatic csr_xstatus_t write_ustatus(csr_xstatus_t currentValue, csr_xstatus_t writeValue);
    csr_xstatus_t mask = get_ustatus_mask();
    return (currentValue & (~mask)) | (writeValue & mask);
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
module ControlStatusRegister(
    ControlStatusRegisterIF.ControlStatusRegister bus,
    input logic clk,
    input logic rst
);
    // Wires
    Privilege nextPrivilege;
    csr_xstatus_t nextStatus;

    addr_t nextPc;

    word_t readValue;
    csr_xstatus_t writeValue;

    // Registers (performance counters)
    uint64_t r_Cycle;

    // Registers (written by trap or trap-return)
    Privilege r_Privilege;

    csr_xstatus_t r_Status;

    word_t r_UserExceptionProgramCounter;
    exception_code_t r_UserCause;
    word_t r_UserTrapValue;

    word_t r_SupervisorExceptionProgramCounter;
    exception_code_t r_SupervisorCause;
    word_t r_SupervisorTrapValue;

    word_t r_MachineExceptionProgramCounter;
    exception_code_t r_MachineCause;
    word_t r_MachineTrapValue;

    // Registers (written by csr insructions)
    csr_xtvec_t r_UserTrapVector;
    word_t r_UserScratch;

    csr_xtvec_t r_SupervisorTrapVector;
    word_t r_SupervisorScratch;
    word_t r_SupervisorExceptionDelegate;
    csr_satp_t r_SupervisorAddressTranslationProtection;

    csr_xtvec_t r_MachineTrapVector;
    word_t r_MachineScratch;
    word_t r_MachineExceptionDelegate;

    logic [2:0] reg_frm;
    logic [4:0] reg_fflags;

    always_comb begin
        // readValue
        unique case (bus.readAddr)
        csr_addr_ustatus:   readValue = read_ustatus(r_Status);
        csr_addr_fflags:    readValue = {27'h0, reg_fflags};
        csr_addr_frm:       readValue = {29'h0, reg_frm};
        csr_addr_fcsr:      readValue = {24'h0, reg_frm, reg_fflags};
        csr_addr_utvec:     readValue = r_UserTrapVector;
        csr_addr_uscratch:  readValue = r_UserScratch;
        csr_addr_uepc:      readValue = r_UserExceptionProgramCounter;
        csr_addr_ucause:    readValue = read_xcause(r_UserCause);
        csr_addr_utval:     readValue = r_UserTrapValue;

        csr_addr_sstatus:   readValue = read_sstatus(r_Status);
        csr_addr_sedeleg:   readValue = r_SupervisorExceptionDelegate;
        csr_addr_stvec:     readValue = r_SupervisorTrapVector;
        csr_addr_sscratch:  readValue = r_SupervisorScratch;
        csr_addr_sepc:      readValue = r_SupervisorExceptionProgramCounter;
        csr_addr_scause:    readValue = read_xcause(r_SupervisorCause);
        csr_addr_stval:     readValue = r_SupervisorTrapValue;
        csr_addr_satp:      readValue = r_SupervisorAddressTranslationProtection;

        csr_addr_mstatus:   readValue = r_Status;
        csr_addr_misa:      readValue = read_misa();
        csr_addr_medeleg:   readValue = r_MachineExceptionDelegate;
        csr_addr_mtvec:     readValue = r_MachineTrapVector;
        csr_addr_mscratch:  readValue = r_MachineScratch;
        csr_addr_mepc:      readValue = r_MachineExceptionProgramCounter;
        csr_addr_mcause:    readValue = read_xcause(r_MachineCause);
        csr_addr_mtval:     readValue = r_MachineTrapValue;

        csr_addr_cycle:     readValue = r_Cycle[31:0];
        csr_addr_time:      readValue = r_Cycle[31:0];
        csr_addr_instret:   readValue = bus.readOpId[31:0];
        csr_addr_cycleh:    readValue = r_Cycle[63:32];
        csr_addr_timeh:     readValue = r_Cycle[63:32];
        csr_addr_instreth:  readValue = bus.readOpId[63:32];

        csr_addr_mvendorid: readValue = VendorId;
        csr_addr_marchid:   readValue = ArchitectureId;
        csr_addr_mimpid:    readValue = ImplementationId;
        csr_addr_mhartid:   readValue = HardwareThreadId;
        default:            readValue = '0;
        endcase

        // writeValue
        writeValue = bus.writeValue;

        // nextPrivilege
        if (bus.trapInfo.valid) begin
            nextPrivilege = calc_next_privilege(
                .cause(bus.trapInfo.cause),
                .machineExceptionDelegate(r_MachineExceptionDelegate),
                .supervisorExceptionDelegate(r_SupervisorExceptionDelegate)
            );
        end
        else if (bus.trapReturn) begin
            if (bus.trapReturnPrivilege == Privilege_Machine) begin
                nextPrivilege = Privilege'(r_Status.mpp);
            end
            else if (bus.trapReturnPrivilege == Privilege_Supervisor) begin
                nextPrivilege = Privilege'(r_Status.spp);
            end
            else begin
                nextPrivilege = Privilege_User;
            end
        end
        else begin
            nextPrivilege = r_Privilege;
        end

        // nextStatus
        if (bus.trapInfo.valid) begin
            if (nextPrivilege == Privilege_Machine) begin
                nextStatus = update_xstatus_mpp(r_Status, r_Privilege);
            end
            else if (nextPrivilege == Privilege_Supervisor) begin
                nextStatus = update_xstatus_spp(r_Status, r_Privilege);
            end
            else begin
                nextStatus = r_Status;
            end
        end
        else if (bus.trapReturn) begin
            if (bus.trapReturnPrivilege == Privilege_Machine) begin
                nextStatus = update_xstatus_mpp_mie(r_Status, Privilege_User, r_Status.mpie);
            end
            else if (nextPrivilege == Privilege_Supervisor) begin
                nextStatus = update_xstatus_spp_sie(r_Status, Privilege_User, r_Status.spie);
            end
            else begin
                nextStatus = r_Status;
            end
        end
        else if (bus.writeEnable && bus.writeAddr == csr_addr_mstatus) begin
            nextStatus = writeValue;
        end
        else if (bus.writeEnable && bus.writeAddr == csr_addr_sstatus) begin
            nextStatus = write_sstatus(r_Status, writeValue);
        end
        else if (bus.writeEnable && bus.writeAddr == csr_addr_ustatus) begin
            nextStatus = write_ustatus(r_Status, writeValue);
        end
        else begin
            nextStatus = r_Status;
        end

        // nextPc
        if (bus.trapInfo.valid && nextPrivilege == Privilege_Machine) begin
            nextPc = {r_MachineTrapVector.base, 2'b00};
        end
        else if (bus.trapInfo.valid && nextPrivilege == Privilege_Supervisor) begin
            nextPc = {r_SupervisorTrapVector.base, 2'b00};
        end
        else if (bus.trapInfo.valid && nextPrivilege == Privilege_User) begin
            nextPc = {r_UserTrapVector.base, 2'b00};
        end
        else if (bus.trapReturn && bus.trapReturnPrivilege == Privilege_Machine) begin
            nextPc = r_MachineExceptionProgramCounter;
        end
        else if (bus.trapReturn && bus.trapReturnPrivilege == Privilege_Supervisor) begin
            nextPc = r_SupervisorExceptionProgramCounter;
        end
        else if (bus.trapReturn && bus.trapReturnPrivilege == Privilege_User) begin
            nextPc = r_UserExceptionProgramCounter;
        end
        else begin
            nextPc = '0;
        end

        // bus output
        bus.nextPc = nextPc;
        bus.readValue = readValue;
        bus.readIllegal = 0; // TEMP: Disable illegal access exception for riscv-tests

        bus.satp = r_SupervisorAddressTranslationProtection;
        bus.mstatus = r_Status;
        bus.privilege = r_Privilege;
        bus.trapSupervisorReturn = r_Status.tsr;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_Cycle <= '0;

            r_Privilege <= Privilege_Machine;
            r_Status <= '0;

            r_UserExceptionProgramCounter <= '0;
            r_UserCause <= '0;
            r_UserTrapValue <= '0;

            r_SupervisorExceptionProgramCounter <= '0;
            r_SupervisorCause <= '0;
            r_SupervisorTrapValue <= '0;

            r_MachineExceptionProgramCounter <= '0;
            r_MachineCause <= '0;
            r_MachineTrapValue <= '0;

            r_UserTrapVector <= '0;
            r_UserScratch <= '0;

            r_SupervisorTrapVector <= '0;
            r_SupervisorScratch <= '0;
            r_SupervisorExceptionDelegate <= '0;
            r_SupervisorAddressTranslationProtection <= '0;

            r_MachineTrapVector <= '0;
            r_MachineExceptionDelegate <= '0;
            r_MachineScratch <= '0;

            reg_fflags <= '0;
            reg_frm <= '0;
        end
        else begin
            // Performance Counters
            r_Cycle <= r_Cycle + 1;

            // Registers written by trap or trap-return
            r_Privilege <= nextPrivilege;
            r_Status <= nextStatus;

            if (bus.trapInfo.valid && nextPrivilege == Privilege_User) begin
                r_UserExceptionProgramCounter <= bus.trapPc;
                r_UserCause <= bus.trapInfo.cause;
                r_UserTrapValue <= bus.trapInfo.value;
            end
            else begin
                r_UserExceptionProgramCounter <= (bus.writeEnable && bus.writeAddr == csr_addr_uepc)
                    ? bus.writeValue
                    : r_UserExceptionProgramCounter;
                r_UserCause <= (bus.writeEnable && bus.writeAddr == csr_addr_ucause)
                    ? bus.writeValue[3:0]
                    : r_UserCause;
                r_UserTrapValue <= (bus.writeEnable && bus.writeAddr == csr_addr_utval)
                    ? bus.writeValue
                    : r_UserTrapValue;
            end

            if (bus.trapInfo.valid && nextPrivilege == Privilege_Supervisor) begin
                r_SupervisorExceptionProgramCounter <= bus.trapPc;
                r_SupervisorCause <= bus.trapInfo.cause;
                r_SupervisorTrapValue <= bus.trapInfo.value;
            end
            else begin
                r_SupervisorExceptionProgramCounter <= (bus.writeEnable && bus.writeAddr == csr_addr_sepc)
                    ? bus.writeValue
                    : r_SupervisorExceptionProgramCounter;
                r_SupervisorCause <= (bus.writeEnable && bus.writeAddr == csr_addr_scause)
                    ? bus.writeValue[3:0]
                    : r_SupervisorCause;
                r_SupervisorTrapValue <= (bus.writeEnable && bus.writeAddr == csr_addr_stval)
                    ? bus.writeValue
                    : r_SupervisorTrapValue;
            end

            if (bus.trapInfo.valid && nextPrivilege == Privilege_Machine) begin
                r_MachineExceptionProgramCounter <= bus.trapPc;
                r_MachineCause <= bus.trapInfo.cause;
                r_MachineTrapValue <= bus.trapInfo.value;
            end
            else begin
                r_MachineExceptionProgramCounter <= (bus.writeEnable && bus.writeAddr == csr_addr_mepc)
                    ? bus.writeValue
                    : r_MachineExceptionProgramCounter;
                r_MachineCause <= (bus.writeEnable && bus.writeAddr == csr_addr_mcause)
                    ? bus.writeValue[3:0]
                    : r_MachineCause;
                r_MachineTrapValue <= (bus.writeEnable && bus.writeAddr == csr_addr_mtval)
                    ? bus.writeValue
                    : r_MachineTrapValue;
            end

            // Registers written by csr insructions
            r_UserTrapVector <= (bus.writeEnable && bus.writeAddr == csr_addr_utvec)
                ? bus.writeValue
                : r_UserTrapVector;

            r_UserScratch <= (bus.writeEnable && bus.writeAddr == csr_addr_uscratch)
                ? bus.writeValue
                : r_UserScratch;

            r_SupervisorTrapVector <= (bus.writeEnable && bus.writeAddr == csr_addr_stvec)
                ? bus.writeValue
                : r_SupervisorTrapVector;

            r_SupervisorScratch <= (bus.writeEnable && bus.writeAddr == csr_addr_sscratch)
                ? bus.writeValue
                : r_SupervisorScratch;

            r_SupervisorExceptionDelegate <= (bus.writeEnable && bus.writeAddr == csr_addr_sedeleg)
                ? bus.writeValue
                : r_SupervisorExceptionDelegate;

            r_SupervisorAddressTranslationProtection <= (bus.writeEnable && bus.writeAddr == csr_addr_satp)
                ? bus.writeValue
                : r_SupervisorAddressTranslationProtection;

            r_MachineTrapVector <= (bus.writeEnable && bus.writeAddr == csr_addr_mtvec)
                ? bus.writeValue
                : r_MachineTrapVector;

            r_MachineScratch <= (bus.writeEnable && bus.writeAddr == csr_addr_mscratch)
                ? bus.writeValue
                : r_MachineScratch;

            r_MachineExceptionDelegate <= (bus.writeEnable && bus.writeAddr == csr_addr_medeleg)
                ? bus.writeValue
                : r_MachineExceptionDelegate;

            if (bus.writeEnable && bus.writeAddr == csr_addr_fflags) begin
                reg_fflags <= bus.writeValue[4:0];
                reg_frm <= reg_frm;
            end
            else if (bus.writeEnable && bus.writeAddr == csr_addr_frm) begin
                reg_fflags <= reg_fflags;
                reg_frm <= bus.writeValue[2:0];
            end
            else if (bus.writeEnable && bus.writeAddr == csr_addr_fcsr) begin
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