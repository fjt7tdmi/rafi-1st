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

#include <fstream>
#include <vector>

#include <rafi/trace.h>

#include "BinaryCycle.h"

namespace rafi { namespace trace {

class TraceIndexReaderImpl final
{
public:
    TraceIndexReaderImpl(const char* path)
    {
        ParseIndexFile(path);
        UpdateTraceBinary();
    }

    ~TraceIndexReaderImpl()
    {
        if (m_pTraceBinary != nullptr)
        {
            delete m_pTraceBinary;
            m_pTraceBinary = nullptr;
        }
    }

    const ICycle* GetCycle() const
    {
        return m_pTraceBinary->GetCycle();
    }

    bool IsEnd() const
    {
        return m_EntryIndex == m_Entries.size();
    }

    void Next()
    {
        m_pTraceBinary->Next();
        m_Cycle++;

        if (!m_pTraceBinary->IsEnd())
        {
            return;
        }

        m_EntryIndex++;
        if (m_EntryIndex == m_Entries.size())
        {
            return;
        }

        UpdateTraceBinary();
    }

    void Next(uint32_t cycle)
    {
        const auto dstCycle = m_Cycle + cycle;

        int entryIndex = -1;

        uint32_t skippedCycle = 0;
        for (int i = 0; i < m_Entries.size(); i++)
        {
            if (skippedCycle + m_Entries[i].cycle > dstCycle)
            {
                entryIndex = i;
                break;
            }

            skippedCycle += m_Entries[i].cycle;
        }

        if (entryIndex < 0)
        {
            throw TraceException("Failed to skip specified cycles in TraceIndexReaderImpl::Next()");
        }

        m_EntryIndex = entryIndex;
        m_Cycle = skippedCycle;
        UpdateTraceBinary();

        for (uint32_t i = skippedCycle; i < dstCycle; i++)
        {
            Next();
        }
    }

private:
    void ParseIndexFile(const char* path)
    {
        auto f = std::ifstream(path);

        if (f.fail())
        {
            throw FileOpenFailureException(path);
        }

        while (!f.eof())
        {
            Entry entry;

            f >> entry.path;
            if (entry.path.empty())
            {
                break;
            }

            if (!f.eof())
            {
                f >> entry.cycle;
            }
            else
            {
                entry.cycle = 0;
            }

            m_Entries.push_back(entry);
        }
    }

    void UpdateTraceBinary()
    {
        if (m_pTraceBinary != nullptr)
        {
            delete m_pTraceBinary;
            m_pTraceBinary = nullptr;
        }

        if (0 <= m_EntryIndex && m_EntryIndex < m_Entries.size())
        {
            const auto path = m_Entries[m_EntryIndex].path;

            m_pTraceBinary = new TraceBinaryReader(path.c_str());
        }
    }

    struct Entry
    {
        std::string path;
        uint32_t cycle;
    };

    std::vector<Entry> m_Entries;

    int m_EntryIndex{ 0 }; // current index of m_Entries
    uint32_t m_Cycle{ 0 };

    TraceBinaryReader* m_pTraceBinary{ nullptr };
};

TraceIndexReader::TraceIndexReader(const char* path)
{
    m_pImpl = new TraceIndexReaderImpl(path);
}

TraceIndexReader::~TraceIndexReader()
{
    delete m_pImpl;
}

const ICycle* TraceIndexReader::GetCycle() const
{
    return m_pImpl->GetCycle();
}

bool TraceIndexReader::IsEnd() const
{
    return m_pImpl->IsEnd();
}

void TraceIndexReader::Next()
{
    m_pImpl->Next();
}

void TraceIndexReader::Next(uint32_t cycle)
{
    m_pImpl->Next(cycle);
}

}}
