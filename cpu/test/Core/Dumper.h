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

#include "../../../work/verilator/test_Core/VCore.h"

class Dumper final
{
public:
    Dumper(const char* path, VCore* pCore);

    ~Dumper();

    void DumpCycle(int cycle);

private:
    void Dump(int cycle);

    bool m_Valid {false};
    int32_t m_Pc {0};
    int32_t m_OpId {0};

    rvtrace::FileTraceWriter m_FileTraceWriter;
    VCore* m_pCore;
};
