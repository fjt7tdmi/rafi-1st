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

parameter XLen = 32;
parameter XLenLog2 = 5;

parameter WordWidth = XLen;
parameter WordSize = WordWidth / ByteWidth;

// Address
parameter VirtualAddrWidth = 32;
parameter PhysicalAddrWidth = 34;

parameter PageOffsetWidth = 12;

parameter VirtualPageNumberWidth = VirtualAddrWidth - PageOffsetWidth;
parameter PhysicalPageNumberWidth = PhysicalAddrWidth - PageOffsetWidth;

parameter PageTableEntrySize = 4;
parameter PageTableEntryWidth = PageTableEntrySize * ByteWidth;

// ----------------------------------------------------------------------------
// typedef

typedef logic signed    [XLen-1:0] word_t;
typedef logic signed    [VirtualAddrWidth-1:0] addr_t;
typedef logic signed    [PhysicalAddrWidth-1:0] paddr_t;

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
    logic [XLen-1:2] base;
    TrapVectorMode mode;
} csr_xtvec_t;

// satp
typedef struct packed {
    AddressTranslationMode mode;
    logic [8:0] asid;
    logic [21:0] ppn;
} csr_satp_t;

// ----------------------------------------------------------------------------

endpackage