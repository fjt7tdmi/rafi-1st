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
 * RAFI-1st specific configurations
 */

package RafiTypes;

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

// ----------------------------------------------------------------------------
// parameter

// Program Counter
parameter INITIAL_PC = 32'h80000000;

// Insn
parameter INSN_WIDTH = 32;
parameter INSN_SIZE = 4;

// Insn Buffer
parameter INSN_BUFFER_ENTRY_COUNT = 4;

// Register File
parameter REG_FILE_SIZE = 32; // Number of registers in register files

// Bypass Logic
parameter BYPASS_DEPTH = 2;
parameter BYPASS_READ_PORT_COUNT = 2;

// Host IO
parameter HOST_IO_ADDR    = 34'h080001000;

// ----------------------------------------------------------------------------
// typedef

typedef logic [INSN_WIDTH-1:0] insn_t;
typedef logic [$clog2(INSN_BUFFER_ENTRY_COUNT):0] insn_buffer_entry_count_t;

// ----------------------------------------------------------------------------
// enum

typedef enum logic [2:0]
{
    FlushReason_Branch          = 3'h1,
    FlushReason_Trap            = 3'h2,
    FlushReason_Invalidate      = 3'h3,
    FlushReason_ITlbMiss        = 3'h4,
    FlushReason_ICacheMiss      = 3'h5,
    FlushReason_InsnBufferFull  = 3'h6
} FlushReason;

// ----------------------------------------------------------------------------
// struct

typedef struct packed
{
    vaddr_t pc;
    logic [15:0] insn;
    logic fault;
    logic interruptValid;
    logic [3:0] interruptCode;
} InsnBufferEntry;

typedef struct packed
{
    logic isInterrupt; // 1: interrupt, 0: exception
    logic [3:0] code;  // interrupt code or exception code
} TrapCause;

typedef struct packed
{
    logic valid;
    TrapCause cause;
    word_t value;
} TrapInfo;

// ----------------------------------------------------------------------------

endpackage
