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

#include <cstdio>
#include <memory>
#include <string>
#include <sstream>

#include "Dumper.h"

#include "../../../work/verilator/test_Core/VCore_Core.h"
#include "../../../work/verilator/test_Core/VCore_RegFile.h"
#include "../../../work/verilator/test_Core/VCore_RegWriteStage.h"

using namespace rvtrace;

namespace rafi { namespace v1 {

Dumper::Dumper(const char* path, VCore* pCore, System* pSystem)
    : m_FileTraceWriter(path)
    , m_pCore(pCore)
    , m_pSystem(pSystem)
{
}

Dumper::~Dumper()
{
}

void Dumper::EnableDumpMemory()
{
    m_MemoryDumpEnabled = true;
}

void Dumper::DumpCycle(int cycle)
{
    if (m_Valid)
    {
        Dump(cycle);
    }

    // Save PC
    m_Valid = m_pCore->Core->m_RegWriteStage->valid;
    m_Pc = m_pCore->Core->m_RegWriteStage->debugPc;
    m_Insn = m_pCore->Core->m_RegWriteStage->debugInsn;
}

void Dumper::Dump(int cycle)
{
    // TraceHeader
    int32_t flags = NodeFlag_BasicInfo | NodeFlag_Pc32 | NodeFlag_IntReg32 | NodeFlag_Io;

    if (m_MemoryDumpEnabled)
    {
        flags |= NodeFlag_Memory;
    }

    const int ramSize = m_pSystem->GetRamSize();

    TraceCycleBuilder builder(flags, 0, ramSize);

    // BasicInfoNode
    BasicInfoNode basicInfoNode
    {
        cycle,
        m_OpId,
        m_Insn,
        PrivilegeLevel::Reserved, // Not implemented
    };
    builder.SetNode(basicInfoNode);

    // Pc32Node
    Pc32Node pc32Node
    {
        m_Pc,
        0x00000000, // Not implemented
    };
    builder.SetNode(pc32Node);

    // IntReg32Node
    IntReg32Node intRegNode;

    for (int i = 0; i < 32; i++)
    {
        intRegNode.regs[i] = m_pCore->Core->m_RegFile->body[i];
    }
    builder.SetNode(intRegNode);

    // Memory
    if (m_MemoryDumpEnabled)
    {
        const auto size = static_cast<size_t>(builder.GetNodeSize(NodeType::Memory));
        auto buffer = builder.GetPointerToNode(NodeType::Memory);

        m_pSystem->CopyRam(buffer, size);
    }

    // IoNode
    IoNode ioNode
    {
        static_cast<int32_t>(m_pCore->hostIoValue),
        0,
    };
    builder.SetNode(ioNode);

    m_FileTraceWriter.Write(builder.GetData(), builder.GetDataSize());
}

}}
