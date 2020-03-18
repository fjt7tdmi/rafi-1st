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

interface CsrIF;
    // Read IF for EX stage
    word_t readValue;
    csr_addr_t readAddr;
    logic readEnable;

    // Write IF for EX stage
    word_t writeValue;
    csr_addr_t writeAddr;
    logic writeEnable;

    // Write IF for FP unit
    logic write_fflags;
    fflags_t write_fflags_value;

    // Trap
    TrapInfo trapInfo;
    vaddr_t trapPc;
    logic trapReturn;
    Priv trapReturnPriv;
    Priv nextPriv;

    // CSR values
    Priv priv;
    csr_satp_t satp;
    csr_xstatus_t status;
    csr_xip_t ip;
    csr_xie_t ie;
    logic [2:0] frm;
    csr_xtvec_t mtvec;
    csr_xtvec_t stvec;
    csr_xtvec_t utvec;
    word_t mepc;
    word_t sepc;
    word_t uepc;

    modport Csr(
    output
        readValue,
        priv,
        satp,
        status,
        ip,
        ie,
        frm,
        mtvec,
        stvec,
        utvec,
        mepc,
        sepc,
        uepc,
        nextPriv,
    input
        readAddr,
        readEnable,
        writeValue,
        writeAddr,
        writeEnable,
        write_fflags,
        write_fflags_value,
        trapInfo,
        trapPc,
        trapReturn,
        trapReturnPriv
    );

    modport ExecuteStage(
    output
        readAddr,
        readEnable,
        writeValue,
        writeAddr,
        writeEnable,
        write_fflags,
        write_fflags_value,
    input
        priv,
        status,
        frm,
        readValue
    );

    modport RegWriteStage(
    output
        trapInfo,
        trapPc,
        trapReturn,
        trapReturnPriv
    );

    modport FetchUnit(
    input
        satp,
        status,
        priv
    );

    modport LoadStoreUnit(
    input
        satp,
        status,
        priv
    );

    modport PipelineController(
    input
        mtvec,
        stvec,
        utvec,
        mepc,
        sepc,
        uepc,
        nextPriv
    );

    modport InterruptController(
    input
        priv,
        status,
        ip,
        ie
    );
endinterface
