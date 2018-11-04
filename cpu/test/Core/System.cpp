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

#include "System.h"
#include "../../../rafi-emu/src/rafi-emu/MemoryMap.h"

namespace rafi { namespace v1 {

System::System(VCore* pCore)
    : m_Bus()
    , m_Ram()
    , m_Uart()
    , m_Timer()
    , m_ExternalInterruptSource(&m_Uart)
    , m_TimerInterruptSource(&m_Timer)
    , m_Processor(pCore, &m_Bus)
{
    m_Bus.RegisterMemory(&m_Ram, emu::RamAddr, m_Ram.Capacity);
    m_Bus.RegisterMemory(&m_Rom, emu::RomAddr, m_Rom.Capacity);
    m_Bus.RegisterIo(&m_Uart, emu::UartAddr, m_Uart.GetSize());
    m_Bus.RegisterIo(&m_Timer, emu::TimerAddr, m_Timer.GetSize());

    m_Processor.RegisterExternalInterruptSource(&m_ExternalInterruptSource);
    m_Processor.RegisterTimerInterruptSource(&m_TimerInterruptSource);
}

void System::LoadFileToMemory(const char* path, emu::PhysicalAddress address)
{
    auto location = m_Bus.ConvertToMemoryLocation(address);
    location.pMemory->LoadFile(path, location.offset);
}

void System::ProcessPositiveEdge()
{
    m_Uart.ProcessCycle();
    m_Timer.ProcessCycle();
    m_Processor.ProcessPositiveEdge();
}

void System::ProcessNegativeEdge()
{
    m_Processor.ProcessNegativeEdge();
}

void System::UpdateSignal()
{
    m_Processor.UpdateSignal();
}

}}
