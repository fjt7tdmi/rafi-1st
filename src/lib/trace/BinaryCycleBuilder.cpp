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

#include <cstring>

#include <rafi/trace.h>

namespace rafi { namespace trace {

namespace {
    size_t DefaultBufferSize = 4096;
}

class BinaryCycleBuilderImpl final
{
public:
    BinaryCycleBuilderImpl(uint32_t cycle, const XLEN& xlen, uint64_t pc)
    {
        m_pBuffer = malloc(DefaultBufferSize);
        m_BufferSize = DefaultBufferSize;

        NodeBasic node{ cycle, xlen, pc };
        Add(node);
    }

    ~BinaryCycleBuilderImpl()
    {
        free(m_pBuffer);
    }

    void Add(const NodeIntReg32& node)
    {
        AddData(NodeId_IN, &node, sizeof(node));
    }

    void Add(const NodeIntReg64& node)
    {
        AddData(NodeId_IN, &node, sizeof(node));
    }

    void Add(const NodeFpReg& node)
    {
        AddData(NodeId_FP, &node, sizeof(node));
    }

    void Add(const NodeIo& node)
    {
        AddData(NodeId_IO, &node, sizeof(node));
    }

    void Add(const OpEvent& node)
    {
        AddData(NodeId_OP, &node, sizeof(node));
    }

    void Add(const TrapEvent& node)
    {
        AddData(NodeId_TR, &node, sizeof(node));
    }

    void Add(const MemoryEvent& node)
    {
        AddData(NodeId_MA, &node, sizeof(node));
    }

    void Break()
    {
        AddData(NodeId_BR, nullptr, 0);
    }

    // Get pointer to raw data
    void* GetData()
    {
        return m_pBuffer;
    }

    // Get size of raw data
    size_t GetDataSize() const
    {
        return m_DataSize;
    }

private:
    void Add(const NodeBasic& node)
    {
        AddData(NodeId_BA, &node, sizeof(node));
    }

    void AddData(uint16_t nodeId, const void* pNode, size_t nodeSize)
    {
        if (m_DataSize + sizeof(NodeHeader) + nodeSize > m_BufferSize)
        {
            throw TraceException("Buffer overflow @ BinaryCycleBuilderImpl.\n");
        }

        if (nodeSize > UINT32_MAX)
        {
            throw TraceException("Node size is too large @ BinaryCycleBuilderImpl.\n");
        }

        NodeHeader header{ nodeId, 0, static_cast<uint32_t>(nodeSize) };

        std::memcpy(reinterpret_cast<uint8_t*>(m_pBuffer) + m_DataSize, &header, sizeof(header));
        m_DataSize += sizeof(header);

        if (pNode)
        {
            std::memcpy(reinterpret_cast<uint8_t*>(m_pBuffer) + m_DataSize, pNode, nodeSize);
            m_DataSize += nodeSize;
        }
    }

    void* m_pBuffer{ nullptr };
    size_t m_BufferSize{ 0 };
    size_t m_DataSize{ 0 };
};

BinaryCycleBuilder::BinaryCycleBuilder(uint32_t cycle, const XLEN& xlen, uint64_t pc)
{
    m_pImpl = new BinaryCycleBuilderImpl(cycle, xlen, pc);
}

BinaryCycleBuilder::~BinaryCycleBuilder()
{
    delete m_pImpl;
}

void BinaryCycleBuilder::Add(const NodeIntReg32& value)
{
    m_pImpl->Add(value);
}

void BinaryCycleBuilder::Add(const NodeIntReg64& value)
{
    m_pImpl->Add(value);
}

void BinaryCycleBuilder::Add(const NodeFpReg& value)
{
    m_pImpl->Add(value);
}

void BinaryCycleBuilder::Add(const NodeIo& value)
{
    m_pImpl->Add(value);
}

void BinaryCycleBuilder::Add(const OpEvent& value)
{
    m_pImpl->Add(value);
}

void BinaryCycleBuilder::Add(const TrapEvent& value)
{
    m_pImpl->Add(value);
}

void BinaryCycleBuilder::Add(const MemoryEvent& value)
{
    m_pImpl->Add(value);
}

void BinaryCycleBuilder::Break()
{
    m_pImpl->Break();
}

void* BinaryCycleBuilder::GetData()
{
    return m_pImpl->GetData();
}

size_t BinaryCycleBuilder::GetDataSize() const
{
    return m_pImpl->GetDataSize();
}

}}
