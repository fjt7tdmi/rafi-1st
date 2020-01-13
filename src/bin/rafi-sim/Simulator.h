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

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "CommandLineOption.h"
#include "System.h"
#include "VCore.h"

namespace rafi { namespace sim {

class Simulator
{
public:
    Simulator(const CommandLineOption& option);
    ~Simulator();

    void Process(int cycle);

    int GetCycle() const;

private:
    void ProcessCycle();

    const CommandLineOption& m_Option;

    VerilatedVcdC* m_pTfp;
    VCore* m_pCore;
    System* m_pSystem;

    int m_Cycle{0};
};

}}
