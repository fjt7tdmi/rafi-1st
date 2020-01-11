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

// Control Status Register
parameter CsrAddrWidth = 12;

// ----------------------------------------------------------------------------
// typedef

// Memory access type
typedef enum logic [1:0]
{
    MemoryAccessType_Instruction  = 2'h0,
    MemoryAccessType_Load         = 2'h2,
    MemoryAccessType_Store        = 2'h3
} MemoryAccessType;

// Exception Code
typedef enum logic unsigned [3:0]
{
    ExceptionCode_InsnAddrMisaligned    = 4'h0,
    ExceptionCode_InsnAccessFault       = 4'h1,
    ExceptionCode_IllegalInsn           = 4'h2,
    ExceptionCode_Breakpoint            = 4'h3,
    ExceptionCode_LoadAddrMisaligned    = 4'h4,
    ExceptionCode_LoadAccessFault       = 4'h5,
    ExceptionCode_StoreAddrMisaligned   = 4'h6,
    ExceptionCode_StoreAccessFault      = 4'h7,
    ExceptionCode_EcallFromUser         = 4'h8,
    ExceptionCode_EcallFromSupervisor   = 4'h9,
    ExceptionCode_EcallFromMachine      = 4'hb,
    ExceptionCode_InsnPageFault         = 4'hc,
    ExceptionCode_LoadPageFault         = 4'hd,
    ExceptionCode_StorePageFault        = 4'hf
} ExceptionCode;

// Interrupt Code
typedef enum logic [3:0]
{
    InterruptCode_UserSoftware          = 4'h0,
    InterruptCode_SupervisorSoftware    = 4'h1,
    InterruptCode_MachineSoftware       = 4'h3,
    InterruptCode_UserTimer             = 4'h4,
    InterruptCode_SupervisorTimer       = 4'h5,
    InterruptCode_MachineTimer          = 4'h7,
    InterruptCode_UserExternal          = 4'h8,
    InterruptCode_SupervisorExternal    = 4'h9,
    InterruptCode_MachineExternal       = 4'hb
} InterruptCode;

typedef logic unsigned  [CsrAddrWidth-1:0] csr_addr_t;

typedef logic unsigned  [3:0] exception_code_t;

typedef enum logic [1:0]
{
    Privilege_User         = 2'b00,
    Privilege_Supervisor   = 2'b01,
    Privilege_Machine      = 2'b11
} Privilege;

// ----------------------------------------------------------------------------

endpackage