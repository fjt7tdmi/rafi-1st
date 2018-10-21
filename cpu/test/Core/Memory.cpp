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
        printf("Failed to load file to Memory (failed to open file).");
        std::abort();
    }
    f.read(m_pBody, Capacity);
    f.close();
}

void Memory::UpdateCore(VCore* core)
{
    const int lineSize = sizeof(core->memoryReadValue);
    const int wordSize = sizeof(core->memoryReadValue[0]);
    const int offset = (core->memoryAddr * lineSize) % Capacity;

    if (core->memoryEnable && core->memoryIsWrite)
    {
        // write
        core->memoryDone = 1;
        std::memset(core->memoryReadValue, 0, lineSize);

        assert(offset + lineSize < Capacity);
        std::memcpy(&m_pBody[offset], core->memoryWriteValue, lineSize);

    }
    else if (core->memoryEnable && !core->memoryIsWrite)
    {
        // read
        core->memoryDone = 1;

        assert(offset + lineSize < Capacity);
        std::memcpy(core->memoryReadValue, &m_pBody[offset], lineSize);
    }
    else
    {
        // no op
        core->memoryDone = 0;
        std::memset(core->memoryReadValue, 0, lineSize);
    }
}
