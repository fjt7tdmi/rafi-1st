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

#include <cstdint>
#include <cstdlib>
#include <cstring>

#include <rafi/trace.h>

namespace rafi { namespace trace {

class TraceBinaryMemoryWriterImpl final
{
public:
    TraceBinaryMemoryWriterImpl(void* buffer, int64_t bufferSize)
        : m_pBuffer(buffer)
        , m_BufferSize(bufferSize)
    {
    }

    ~TraceBinaryMemoryWriterImpl()
    {        
    }

    void Write(void* buffer, int64_t size)
    {
        if (m_CurrentOffset + size > m_BufferSize)
        {
            throw TraceException("detect buffer overflow.");
        }

        if (!(0 <= size && size < SIZE_MAX))
        {
            throw TraceException("argument 'size' is out-of-range.");
        }

        auto destination = reinterpret_cast<uint8_t*>(m_pBuffer) + m_CurrentOffset;

        std::memcpy(destination, buffer, static_cast<size_t>(size));

        m_CurrentOffset += size;
    }

private:
    void* m_pBuffer;
    int64_t m_BufferSize;

    int64_t m_CurrentOffset {0};
};

TraceBinaryMemoryWriter::TraceBinaryMemoryWriter(void* buffer, int64_t bufferSize)
{
    m_pImpl = new TraceBinaryMemoryWriterImpl(buffer, bufferSize);
}

TraceBinaryMemoryWriter::~TraceBinaryMemoryWriter()
{
    delete m_pImpl;
}

void TraceBinaryMemoryWriter::Write(void* buffer, int64_t size)
{
    m_pImpl->Write(buffer, size);
}

}}
