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

package RvTypes;

/*
 * RISC-V specific types
 */

// ----------------------------------------------------------------------------
// parameter

// Register File
parameter REG_ADDR_WIDTH = 5;

// CSR
parameter CSR_ADDR_WIDTH = 12;

// FP rouning mode
parameter FRM_RNE = 3'b000; // Round to Nearest, ties to Even
parameter FRM_RTZ = 3'b001; // Round towards Zero
parameter FRM_RDN = 3'b010; // Round Down
parameter FRM_RUP = 3'b011; // Round Up
parameter FRM_RMM = 3'b100; // Round to Nearest, ties to Max Magnitude
parameter FRM_DYN = 3'b111; // In instruction's rm field, selects dynamic rounding mode; In Rounding Mode register, Invalid.

// Exception Code
parameter EXCEPTION_CODE_INSN_ADDR_MISALIGNED  = 4'h0;
parameter EXCEPTION_CODE_INSN_ACCESS_FAULT     = 4'h1;
parameter EXCEPTION_CODE_ILLEGAL_INSN          = 4'h2;
parameter EXCEPTION_CODE_BREAKPOINT            = 4'h3;
parameter EXCEPTION_CODE_LOAD_ADDR_MISALIGNED  = 4'h4;
parameter EXCEPTION_CODE_LOAD_ACCESS_FAULT     = 4'h5;
parameter EXCEPTION_CODE_STORE_ADDR_MISALIGNED = 4'h6;
parameter EXCEPTION_CODE_STORE_ACCESS_FAULT    = 4'h7;
parameter EXCEPTION_CODE_ECALL_FROM_U          = 4'h8;
parameter EXCEPTION_CODE_ECALL_FROM_S          = 4'h9;
parameter EXCEPTION_CODE_ECALL_FROM_M          = 4'hb;
parameter EXCEPTION_CODE_INSN_PAGE_FAULT       = 4'hc;
parameter EXCEPTION_CODE_LOAD_PAGE_FAULT       = 4'hd;
parameter EXCEPTION_CODE_STORE_PAGE_FAULT      = 4'hf;

// Interrupt Code
parameter INTERRUPT_CODE_U_SOFTWARE = 4'h0;
parameter INTERRUPT_CODE_S_SOFTWARE = 4'h1;
parameter INTERRUPT_CODE_M_SOFTWARE = 4'h3;
parameter INTERRUPT_CODE_U_TIMER    = 4'h4;
parameter INTERRUPT_CODE_S_TIMER    = 4'h5;
parameter INTERRUPT_CODE_M_TIMER    = 4'h7;
parameter INTERRUPT_CODE_U_EXTERNAL = 4'h8;
parameter INTERRUPT_CODE_S_EXTERNAL = 4'h9;
parameter INTERRUPT_CODE_M_EXTERNAL = 4'hb;

// ----------------------------------------------------------------------------
// typedef

// Memory access type
typedef enum logic [1:0]
{
    MemoryAccessType_Instruction  = 2'h0,
    MemoryAccessType_Load         = 2'h2,
    MemoryAccessType_Store        = 2'h3
} MemoryAccessType;

typedef enum logic [1:0]
{
    Privilege_User         = 2'b00,
    Privilege_Supervisor   = 2'b01,
    Privilege_Machine      = 2'b11
} Privilege;

typedef logic [REG_ADDR_WIDTH-1:0] reg_addr_t;

typedef logic [CSR_ADDR_WIDTH-1:0] csr_addr_t;

typedef struct packed {
    logic NV;   // Invalid Operation
    logic DZ;   // Divide by Zero
    logic OF;   // Overflow
    logic UF;   // Underflow
    logic NX;   // Inexact
} fflags_t;

// ----------------------------------------------------------------------------

endpackage
