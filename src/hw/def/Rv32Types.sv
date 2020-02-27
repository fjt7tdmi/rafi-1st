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
typedef logic signed    [VADDR_WIDTH-1:0] addr_t;
typedef logic signed    [PADDR_WIDTH-1:0] paddr_t;

typedef struct packed
{
    logic [ 9:0] vpn1;
    logic [ 9:0] vpn0;
} virtual_page_number_t;

typedef struct packed
{
    logic [11:0] ppn1;
    logic [ 9:0] ppn0;
} physical_page_number_t;

typedef struct packed
{
    logic [11:0] ppn1;
    logic [ 9:0] ppn0;
    logic [ 1:0] reserved;
    logic dirty;
    logic accessed;
    logic global_;
    logic user;
    logic execute;
    logic write;
    logic read;
    logic valid;
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
// Control status register definitions
//

// mstatus, sstatus, ustatus
typedef struct packed {
    logic sd;
    logic [7:0] reserved1;
    logic tsr;
    logic tw;
    logic tvm;
    logic mxr;
    logic sum_;
    logic mprv;
    logic [1:0] xs;
    logic [1:0] fs;
    logic [1:0] mpp;
    logic [1:0] reserved2;
    logic spp;
    logic mpie;
    logic reserved3;
    logic spie;
    logic upie;
    logic mie;
    logic reserved4;
    logic sie;
    logic uie;
} csr_xstatus_t;

// mtvec, stvec, utvec
typedef struct packed {
    logic [XLEN-1:2] base;
    TrapVectorMode mode;
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
    AddressTranslationMode mode;
    logic [8:0] asid;
    logic [21:0] ppn;
} csr_satp_t;

// ----------------------------------------------------------------------------

endpackage
