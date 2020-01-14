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
#include <rafi/trace.h>

#include "Simulator.h"

namespace rafi { namespace sim {

Simulator::Simulator(const CommandLineOption& option)
    : m_Option(option)
{
    Verilated::traceEverOn(true);

    m_pTfp = new VerilatedVcdC();
    m_pCore = new VCore();
    m_pSystem = new System(m_pCore, option.GetRamSize());
    m_pLogger = new trace::Logger(XLEN::XLEN32, option.GetLoggerConfig(), m_pSystem);

    m_pCore->trace(m_pTfp, 20);
    m_pTfp->open(option.GetVcdPath().c_str());

    m_pSystem->SetHostIoAddr(option.GetHostIoAddr());
    m_pSystem->Reset();
    m_pSystem->LoadFileToMemory(option.GetLoadPath().c_str());

    m_pTfp->dump(0);
}

Simulator::~Simulator()
{
    m_pCore->final();
    m_pTfp->close();

    delete m_pLogger;
    delete m_pSystem;
    delete m_pCore;
    delete m_pTfp;
}

void Simulator::Process(int cycle)
{
    for (int i = 0; i < cycle; i++)
    {
        ProcessCycle();
    }
}

int Simulator::GetCycle() const
{
    return m_Cycle;
}

void Simulator::ProcessCycle()
{
    m_pSystem->ProcessPositiveEdge();
    m_pTfp->dump(m_Cycle * 10 + 5);
    m_pSystem->ProcessNegativeEdge();
    m_pTfp->dump(m_Cycle * 10 + 10);
    m_pSystem->UpdateSignal();

    m_Cycle++;

    if (m_pSystem->IsOpRetired())
    {
        const auto pc = m_pSystem->GetPc();

        m_pLogger->BeginCycle(m_Cycle, pc);
        m_pLogger->RecordState();
        m_pLogger->EndCycle();
    }
}

}}
