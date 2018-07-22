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

package TraceTypes;

import BasicTypes::*;

// ----------------------------------------------------------------------------
// typedef

typedef enum logic [31:0]
{
    NodeType_BasicInfo = 32'd1,
    NodeType_Pc32 = 32'd2,
    NodeType_Pc64 = 32'd3,
    NodeType_IntReg32 = 32'd4,
    NodeType_IntReg64 = 32'd5,
    NodeType_Csr32 = 32'd6,
    NodeType_Csr64 = 32'd7,
    NodeType_Trap32 = 32'd8,
    NodeType_Trap64 = 32'd9,
    NodeType_MemoryAccess32 = 32'd10,
    NodeType_MemoryAccess64 = 32'd11,
    NodeType_Io = 32'd12,
    NodeType_Memory = 32'd13
} NodeType;

typedef struct packed
{
    int8_t [3:0] signatureLow;
    int8_t [3:0] signatureHigh;
    int32_t headerSizeLow;
    int32_t headerSizeHigh;
} TraceBinaryHeader;

typedef struct packed
{
    int32_t nodeSizeLow; // including TraceHeader itself
    int32_t nodeSizeHigh;
} TraceHeader;

typedef struct packed
{
    int32_t nodeSizeLow; // including TraceChildHeader itself
    int32_t nodeSizeHigh;
    NodeType nodeType;
    int32_t reserved;
} TraceChildHeader;

typedef struct packed
{
    TraceChildHeader header;
    int32_t cycle;
    int32_t opId;
    int32_t insn;
    int32_t reserved;
} BasicInfoNode;

typedef struct packed
{
    TraceChildHeader header;
    int32_t virtualPc;
    int32_t physicalPc;
} Pc32Node;

typedef struct packed
{
    TraceChildHeader header;
    int32_t [0:31] regs;
} IntReg32Node;

typedef struct packed
{
    TraceChildHeader header;
    int32_t hostIoValue;
    int32_t reserved;
} IoNode;

typedef struct packed
{
    TraceChildHeader header;
    int32_t memorySizeLow;
    int32_t memorySizeHigh;
} MemoryNodeHeader;

endpackage
