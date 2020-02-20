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
 * Processor specific configurations
 */

package ProcessorTypes;

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
parameter REG_ADDR_WIDTH = 5;
parameter REG_FILE_SIZE = 32; // Number of registers in register files

// Bypass Logic
parameter BYPASS_DEPTH = 2;
parameter BYPASS_READ_PORT_COUNT = 2;

// ----------------------------------------------------------------------------
// typedef

typedef logic [INSN_WIDTH-1:0] insn_t;
typedef logic [$clog2(INSN_BUFFER_ENTRY_COUNT):0] insn_buffer_entry_count_t;
typedef logic [REG_ADDR_WIDTH-1:0] reg_addr_t;

// ----------------------------------------------------------------------------
// struct

typedef struct packed
{
    addr_t pc;
    logic fault;
    logic[15:0] insn;
} InsnBufferEntry;

typedef struct packed
{
    logic valid;
    ExceptionCode cause;
    word_t value;
} TrapInfo;

// ----------------------------------------------------------------------------

endpackage
