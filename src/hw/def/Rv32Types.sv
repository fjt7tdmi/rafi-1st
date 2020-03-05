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

/*
 * RV32 specific types
 */

package Rv32Types;

import BasicTypes::*;

// ----------------------------------------------------------------------------
// parameter

parameter XLEN = 32;
parameter XLEN_LOG2 = 5;

parameter WORD_WIDTH = XLEN;
parameter WORD_SIZE = WORD_WIDTH / BYTE_WIDTH;

// Address
parameter VADDR_WIDTH = 32;
parameter PADDR_WIDTH = 34;

parameter PAGE_OFFSET_WIDTH = 12;

parameter VIRTUAL_PAGE_NUMBER_WIDTH = VADDR_WIDTH - PAGE_OFFSET_WIDTH;
parameter PHYSICAL_PAGE_NUMBER_WIDTH = PADDR_WIDTH - PAGE_OFFSET_WIDTH;

parameter PAGE_TABLE_ENTRY_SIZE = 4;
parameter PAGE_TABLE_ENTRY_WIDTH = PAGE_TABLE_ENTRY_SIZE * BYTE_WIDTH;

// ----------------------------------------------------------------------------
// typedef

typedef logic signed    [XLEN-1:0] word_t;
typedef logic [VADDR_WIDTH-1:0] vaddr_t;
typedef logic [PADDR_WIDTH-1:0] paddr_t;

typedef struct packed
{
    logic [ 9:0] VPN1;
    logic [ 9:0] VPN0;
} virtual_page_number_t;

typedef struct packed
{
    logic [11:0] PPN1;
    logic [ 9:0] PPN0;
} physical_page_number_t;

typedef struct packed
{
    logic [11:0] PPN1;
    logic [ 9:0] PPN0;
    logic [ 1:0] RESERVED;
    logic D; // Dirty
    logic A; // Accessed
    logic G; // Global
    logic U; // User
    logic X; // Execute
    logic W; // Write
    logic R; // Read
    logic V; // Valid
} PageTableEntry;

// satp address translation mode
typedef enum logic
{
    AddressTranslationMode_Bare = 1'h0,
    AddressTranslationMode_Sv32 = 1'h1
} AddressTranslationMode;

// xtvec trap vector mode
typedef enum logic [1:0]
{
    TrapVectorMode_Direct   = 2'b00,
    TrapVectorMode_Vectored = 2'b01
} TrapVectorMode;

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
// CSR typedef
//

// mstatus, sstatus, ustatus
typedef struct packed {
    logic SD;
    logic [7:0] RESERVED1;
    logic TSR;
    logic TW;
    logic TVM;
    logic MXR;
    logic SUM;
    logic MPRV;
    logic [1:0] XS;
    logic [1:0] FS;
    logic [1:0] MPP;
    logic [1:0] RESERVED2;
    logic SPP;
    logic MPIE;
    logic RESERVED3;
    logic SPIE;
    logic UPIE;
    logic MIE;
    logic RESERVED4;
    logic SIE;
    logic UIE;
} csr_xstatus_t;

// mtvec, stvec, utvec
typedef struct packed {
    logic [XLEN-1:2] BASE;
    TrapVectorMode MODE;
} csr_xtvec_t;

// XIP
typedef struct packed {
    logic MEIP;
    logic RESERVED0;
    logic SEIP;
    logic UEIP;
    logic MTIP;
    logic RESERVED1;
    logic STIP;
    logic UTIP;
    logic MSIP;
    logic RESERVED2;
    logic SSIP;
    logic USIP;
} csr_xip_t;

// XIE
typedef struct packed {
    logic MEIE;
    logic RESERVED0;
    logic SEIE;
    logic UEIE;
    logic MTIE;
    logic RESERVED1;
    logic STIE;
    logic UTIE;
    logic MSIE;
    logic RESERVED2;
    logic SSIE;
    logic USIE;
} csr_xie_t;

// satp
typedef struct packed {
    AddressTranslationMode MODE;
    logic [8:0] ASID;
    logic [21:0] PPN;
} csr_satp_t;

// ----------------------------------------------------------------------------

endpackage
