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

#include <cstdio>

#include <rvtrace/writer.h>

#include <rafi/IInterruptSource.h>

#include "../../../rafi-emu/src/rafi-emu/bus/Bus.h"

#include "../../../work/verilator/test_Core/VCore.h"

namespace rafi { namespace v1 {

class Processor final
{
public:
    explicit Processor(VCore* pCore, emu::bus::Bus* pBus);
    ~Processor();

    // Interrupt source
    void RegisterExternalInterruptSource(emu::IInterruptSource* pInterruptSource);
    void RegisterTimerInterruptSource(emu::IInterruptSource* pInterruptSource);

    // Process
    void ProcessPositiveEdge();
    void ProcessNegativeEdge();
    void UpdateSignal();

private:
    emu::IInterruptSource* m_pExternalInterruptSource;
    emu::IInterruptSource* m_pTimerInterruptSource;

    VCore* m_pCore;
    emu::bus::Bus* m_pBus;
};

}}
