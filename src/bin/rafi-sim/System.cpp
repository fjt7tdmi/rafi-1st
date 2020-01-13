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

#include <rafi/emu.h>

#include "System.h"

namespace rafi { namespace sim {

namespace {
    const int RamSize = 32 * 1024;
}

System::System(VCore* pCore, size_t ramSize)
    : m_pCore(pCore)
    , m_Bus()
    , m_Ram(ramSize)
{
    m_Bus.RegisterMemory(&m_Ram, AddrRam, m_Ram.GetCapacity());
}

void System::LoadFileToMemory(const char* path)
{
    m_Bus.LoadFileToMemory(path, AddrRam);
}

void System::Reset()
{
    m_pCore->rst = 1;

    m_pCore->irq = 0;
    m_pCore->irqTimer = 0;
    m_pCore->ready = 0;
    m_pCore->rdata = 0;

    m_pCore->clk = 0;
    m_pCore->eval();
    m_pCore->clk = 1;
    m_pCore->eval();
    m_pCore->clk = 0;
    m_pCore->eval();

    m_pCore->rst = 0;
}

void System::ProcessPositiveEdge()
{
    m_pCore->clk = 1;
    m_pCore->eval();
}

void System::ProcessNegativeEdge()
{
    m_pCore->clk = 0;
    m_pCore->eval();
}

void System::UpdateSignal()
{
    const auto addr = static_cast<paddr_t>(m_pCore->addr);
    const auto wdata = static_cast<int32_t>(m_pCore->wdata);

    // ready & rdata
    if (m_pCore->enable && m_pCore->write)
    {
        m_pCore->ready = 1;
        m_pCore->rdata = 0;
        m_Bus.WriteUInt32(addr, wdata);
    }
    else if (m_pCore->enable && !m_pCore->write)
    {
        m_pCore->ready = 1;
        m_pCore->rdata = m_Bus.ReadUInt32(addr);
    }
    else
    {
        m_pCore->ready = 0;
        m_pCore->rdata = 0;
    }
}

}}
