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

#include <rafi/emu.h>

#include "VCore.h"

namespace rafi { namespace sim {

class System
{
public:
    explicit System(VCore* pCore, size_t ramSize);

    void LoadFileToMemory(const char* path);

    void Reset();
    void ProcessPositiveEdge();
    void ProcessNegativeEdge();
    void UpdateSignal();

private:
    static const paddr_t AddrRam = 0x80000000;

    VCore* m_pCore;

    emu::Bus m_Bus;
    emu::Ram m_Ram;
};

}}
