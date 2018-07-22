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

package TlbTypes;

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

// typedef
typedef struct packed
{
    logic dirty;    // D flag of page table entry
    logic user;     // U flag of page table entry
    logic execute;  // E flag of page table entry
    logic write;    // W flag of page table entry
    logic read;     // R flag of page table entry
} TlbEntryFlags;

typedef struct packed
{
    logic valid;    // TLB entry valid flag. (valid == 0) will cause tlb miss.
    logic fault;    // Fault flag written by TlbReplacer
    physical_page_number_t pageNumber;
    TlbEntryFlags flags;
} TlbEntry;

endpackage
