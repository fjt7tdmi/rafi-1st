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

#include <memory>
#include <string>
#include <fstream>

#include "Memory.h"

#pragma warning (disable: 4996)

using namespace rvtrace;

Memory::Memory()
{
    m_pBody = new char[Capacity];
    std::memset(m_pBody, 0, Capacity);
}

Memory::~Memory()
{
    delete[] m_pBody;
}

void Memory::LoadFile(const char* path)
{
    std::ifstream f;
    f.open(path, std::fstream::binary | std::fstream::in);
    if (!f.is_open())
    {
        printf("[Memory] Failed to load file to Memory (%s).\n", path);
        std::exit(1);
    }
    f.read(m_pBody, Capacity);
    f.close();
}

void Memory::UpdateCore(VCore* core)
{
    const int wordSize = sizeof(core->rdata);
    const int offset = core->addr % Capacity;

    if (core->enable && core->write)
    {
        // write
        core->ready = 1;
        std::memset(&core->rdata, 0, wordSize);

        assert(offset + wordSize <= Capacity);
        std::memcpy(&m_pBody[offset], &core->wdata, wordSize);

    }
    else if (core->enable && !core->write)
    {
        // read
        core->ready = 1;

        assert(offset + wordSize <= Capacity);
        std::memcpy(&core->rdata, &m_pBody[offset], wordSize);
    }
    else
    {
        // no op
        core->ready = 0;
        std::memset(&core->rdata, 0, wordSize);
    }
}
