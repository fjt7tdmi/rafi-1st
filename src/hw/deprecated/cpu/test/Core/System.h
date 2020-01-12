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

#pragma once

#include "../../../rafi-emu/src/rafi-emu/io/IoInterruptSource.h"
#include "../../../rafi-emu/src/rafi-emu/uart/Uart.h"
#include "../../../rafi-emu/src/rafi-emu/timer/Timer.h"

#include "Processor.h"

#include <rafi/Event.h>

namespace rafi { namespace v1 {

class System
{
public:
    explicit System(VCore* pCore);

    // Setup
    void LoadFileToMemory(const char* path, emu::PhysicalAddress address);

    // Process
    void ProcessPositiveEdge();
    void ProcessNegativeEdge();
    void UpdateSignal();

    // Dump
    int GetRamSize() const;
    void CopyRam(void* buffer, size_t size) const;

private:
    emu::Bus m_Bus;
    emu::Ram m_Ram;
    emu::Rom m_Rom;
    emu::uart::Uart m_Uart;
    emu::timer::Timer m_Timer;

    emu::io::IoInterruptSource m_ExternalInterruptSource;
    emu::io::IoInterruptSource m_TimerInterruptSource;

    Processor m_Processor;
};

}}
