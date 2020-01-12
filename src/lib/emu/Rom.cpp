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

#include <cassert>
#include <cstring>
#include <cstdint>
#include <fstream>

#include <rafi/common.h>
#include <rafi/emu.h>

namespace rafi { namespace emu {

class RomImpl : public IMemory
{
public:
    RomImpl()
    {
        m_pBody = new char[Capacity];
        std::memset(m_pBody, 0, Capacity);
    }

    ~RomImpl()
    {
        delete[] m_pBody;
    }

    size_t GetCapacity() const
    {
        return Capacity;
    }

    void LoadFile(const char* path, int offset)
    {
        RAFI_EMU_CHECK_RANGE(0, offset, GetCapacity());

        std::ifstream f;
        f.open(path, std::fstream::binary | std::fstream::in);
        if (!f.is_open())
        {
            RAFI_EMU_ERROR("Failed to open file: %s\n", path);
        }
        f.read(&m_pBody[offset], Capacity - offset);
        f.close();
    }

    void Read(void* pOutBuffer, size_t size, uint64_t address) const
    {
        RAFI_EMU_CHECK_ACCESS(address, size, GetCapacity());

        std::memcpy(pOutBuffer, &m_pBody[address], size);
    }

    void Write(const void* pBuffer, size_t size, uint64_t address)
    {
        static_cast<void>(pBuffer);
        static_cast<void>(size);
        static_cast<void>(address);

        RAFI_EMU_ERROR("Rom does not support write operation.\n");
    }

private:
    // Constants
    static const int Capacity = 4 * 1024;

	char* m_pBody;
};

Rom::Rom()
{
    m_pImpl = new RomImpl();
}

Rom::~Rom()
{
    delete m_pImpl;
}

size_t Rom::GetCapacity() const
{
    return m_pImpl->GetCapacity();
}

void Rom::LoadFile(const char* path, int offset)
{
    m_pImpl->LoadFile(path, offset);
}

void Rom::Read(void* pOutBuffer, size_t size, uint64_t address) const
{
    m_pImpl->Read(pOutBuffer, size, address);
}

void Rom::Write(const void* pBuffer, size_t size, uint64_t address)
{
    m_pImpl->Write(pBuffer, size, address);
}

}}
