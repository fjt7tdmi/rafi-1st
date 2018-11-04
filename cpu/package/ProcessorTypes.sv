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
parameter InitialProgramCounter = 32'h00001000;

// Insn
parameter InsnWidth = 32;
parameter InsnSize = 4;

// Register File
parameter RegAddrWidth = 5;
parameter RegFileSize = 32; // Number of registers in register files

// Bypass Logic
parameter BypassDepth = 3;
parameter BypassReadPortCount = 2;

// ----------------------------------------------------------------------------
// typedef

typedef logic unsigned  [InsnWidth-1:0] insn_t;
typedef logic unsigned  [RegAddrWidth-1:0] reg_addr_t;

// Privilege
typedef struct packed
{
    logic valid;
    ExceptionCode cause;
    word_t value;
} TrapInfo;

// ----------------------------------------------------------------------------

endpackage
