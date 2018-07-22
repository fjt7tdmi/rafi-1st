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
parameter DCacheLineSize = 16; // bytes
parameter DCacheLineWidth = DCacheLineSize * ByteWidth;

parameter DCacheMemAddrWidth = PhysicalAddrWidth - $clog2(DCacheLineSize);
parameter DCacheIndexWidth = 4;
parameter DCacheTagWidth = DCacheMemAddrWidth - DCacheIndexWidth;

// Direct Map I$ parameter
parameter ICacheLineSize = 16; // bytes
parameter ICacheLineWidth = DCacheLineSize * ByteWidth;

parameter ICacheMemAddrWidth = PhysicalAddrWidth - $clog2(ICacheLineSize);
parameter ICacheIndexWidth = 4;
parameter ICacheTagWidth = ICacheMemAddrWidth - ICacheIndexWidth;

// DTLB parameter
parameter DTlbIndexWidth = 3;

// ITLB parameter
parameter ITlbIndexWidth = 3;

// Reset cycle
parameter CacheResetCycle = (DCacheIndexWidth > ICacheIndexWidth) ?
    (1 << DCacheIndexWidth) :
    (1 << ICacheIndexWidth);

// ----------------------------------------------------------------------------
// typedef

typedef logic [DCacheLineWidth-1:0] dcache_line_t;
typedef logic [DCacheMemAddrWidth-1:0] dcache_mem_addr_t;
typedef logic [DCacheIndexWidth-1:0] dcache_index_t;
typedef logic [DCacheTagWidth-1:0] dcache_tag_t;

typedef logic [ICacheLineWidth-1:0] icache_line_t;
typedef logic [ICacheMemAddrWidth-1:0] icache_mem_addr_t;
typedef logic [ICacheIndexWidth-1:0] icache_index_t;
typedef logic [ICacheTagWidth-1:0] icache_tag_t;

typedef logic [DTlbIndexWidth-1:0] dtlb_index_t;

typedef logic [ITlbIndexWidth-1:0] itlb_index_t;

typedef enum logic [1:0]
{
    CacheCommand_None = 2'h0,
    CacheCommand_WriteThrough = 2'h1,
    CacheCommand_Replace = 2'h2,
    CacheCommand_Invalidate = 2'h3
} CacheCommand;

// ----------------------------------------------------------------------------

endpackage
