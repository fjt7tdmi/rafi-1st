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

package CacheTypes;

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

// ----------------------------------------------------------------------------
// parameter

// Direct Map D$ parameter
parameter DCACHE_LINE_SIZE = 16; // bytes
parameter DCACHE_LINE_WIDTH = DCACHE_LINE_SIZE * BYTE_WIDTH;

parameter DCACHE_MEM_ADDR_WIDTH = PADDR_WIDTH - $clog2(DCACHE_LINE_SIZE);
parameter DCACHE_INDEX_WIDTH = 4;
parameter DCACHE_TAG_WIDTH = DCACHE_MEM_ADDR_WIDTH - DCACHE_INDEX_WIDTH;

// Direct Map I$ parameter
parameter ICACHE_LINE_SIZE = 16; // bytes
parameter ICACHE_LINE_WIDTH = DCACHE_LINE_SIZE * BYTE_WIDTH;

parameter ICACHE_MEM_ADDR_WIDTH = PADDR_WIDTH - $clog2(ICACHE_LINE_SIZE);
parameter ICACHE_INDEX_WIDTH = 4;
parameter ICACHE_TAG_WIDTH = ICACHE_MEM_ADDR_WIDTH - ICACHE_INDEX_WIDTH;

// DTLB parameter
parameter DTLB_INDEX_WIDTH = 3;

// ITLB parameter
parameter ITLB_INDEX_WIDTH = 3;

// Reset cycle
parameter CACHE_RESET_CYCLE = (DCACHE_INDEX_WIDTH > ICACHE_INDEX_WIDTH) ?
    (1 << DCACHE_INDEX_WIDTH) :
    (1 << ICACHE_INDEX_WIDTH);

// ----------------------------------------------------------------------------
// typedef

typedef logic [DCACHE_LINE_WIDTH-1:0] dcache_line_t;
typedef logic [DCACHE_MEM_ADDR_WIDTH-1:0] dcache_mem_addr_t;
typedef logic [DCACHE_INDEX_WIDTH-1:0] dcache_index_t;
typedef logic [DCACHE_TAG_WIDTH-1:0] dcache_tag_t;

typedef logic [ICACHE_LINE_WIDTH-1:0] icache_line_t;
typedef logic [ICACHE_MEM_ADDR_WIDTH-1:0] icache_mem_addr_t;
typedef logic [ICACHE_INDEX_WIDTH-1:0] icache_index_t;
typedef logic [ICACHE_TAG_WIDTH-1:0] icache_tag_t;

typedef logic [DTLB_INDEX_WIDTH-1:0] dtlb_index_t;

typedef logic [ITLB_INDEX_WIDTH-1:0] itlb_index_t;

typedef enum logic [1:0]
{
    ReplaceLogicCommand_None = 2'h0,
    ReplaceLogicCommand_WriteThrough = 2'h1,
    ReplaceLogicCommand_Replace = 2'h2,
    ReplaceLogicCommand_Invalidate = 2'h3
} ReplaceLogicCommand;

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

// ----------------------------------------------------------------------------

endpackage
