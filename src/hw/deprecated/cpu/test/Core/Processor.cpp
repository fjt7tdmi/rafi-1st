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

#include "Processor.h"

using namespace rvtrace;

namespace rafi { namespace v1 {

Processor::Processor(VCore* pCore, emu::bus::Bus* pBus)
    : m_pCore(pCore)
    , m_pBus(pBus)
{
}

Processor::~Processor()
{
}

void Processor::RegisterExternalInterruptSource(emu::IInterruptSource* pInterruptSource)
{
    m_pExternalInterruptSource = pInterruptSource;
}

void Processor::RegisterTimerInterruptSource(emu::IInterruptSource* pInterruptSource)
{
    m_pTimerInterruptSource = pInterruptSource;
}

void Processor::ProcessPositiveEdge()
{
    m_pCore->clk = 1;
    m_pCore->eval();
}

void Processor::ProcessNegativeEdge()
{
    m_pCore->clk = 0;
    m_pCore->eval();
}

void Processor::UpdateSignal()
{
    const auto addr = static_cast<emu::PhysicalAddress>(m_pCore->addr);
    const auto wdata = static_cast<int32_t>(m_pCore->wdata);

    // ready & rdata
    if (m_pCore->enable && m_pCore->write)
    {
        m_pCore->ready = 1;
        m_pCore->rdata = 0;
        m_pBus->SetInt32(addr, wdata);
    }
    else if (m_pCore->enable && !m_pCore->write)
    {
        m_pCore->ready = 1;
        m_pCore->rdata = m_pBus->GetInt32(addr);
    }
    else
    {
        m_pCore->ready = 0;
        m_pCore->rdata = 0;
    }

    // irq
    if (m_pExternalInterruptSource != nullptr)
    {
        m_pCore->irq = m_pExternalInterruptSource->IsRequested();
    }
    else
    {
        m_pCore->irq = 0;
    }

    // irqTimer
    if (m_pTimerInterruptSource != nullptr)
    {
        m_pCore->irqTimer = m_pTimerInterruptSource->IsRequested();
    }
    else
    {
        m_pCore->irqTimer = 0;
    }
}

}}
