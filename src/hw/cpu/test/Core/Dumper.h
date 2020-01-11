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

#pragma once

#include <cstdio>

#include <rvtrace/writer.h>

#include "../../../rafi-emu/src/rafi-emu/mem/Ram.h"
#include "../../../work/verilator/test_Core/VCore.h"

#include "System.h"

namespace rafi { namespace v1 {

class Dumper final
{
public:
    Dumper(const char* path, VCore* pCore, System* pSystem);
    ~Dumper();

    void EnableDumpMemory();

    void DumpCycle(int cycle);

private:
    void Dump(int cycle);

    rvtrace::FileTraceWriter m_FileTraceWriter;
    VCore* m_pCore;
    System* m_pSystem;

    bool m_MemoryDumpEnabled {false};

    // op info
    int32_t m_Pc {0};
    int32_t m_Insn {0};
    int32_t m_OpId {0};
    bool m_Valid {false};
};

}}