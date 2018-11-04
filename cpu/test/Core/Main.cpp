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
#include <cstdio>

#include <boost/program_options.hpp>

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "../../../work/verilator/test_Core/VCore.h"

#include "../../../rafi-emu/src/rafi-emu/MemoryMap.h"

#include "Dumper.h"
#include "Option.h"
#include "System.h"

int main(int argc, char** argv)
{
    Option option(argc, argv);

    Verilated::traceEverOn(true);

    auto tfp = std::make_unique<VerilatedVcdC>();

    auto core = std::make_unique<VCore>();
    auto dumper = std::make_unique<Dumper>(option.GetDumpPath(), core.get());
    auto system = std::make_unique<rafi::v1::System>(core.get());

    core->trace(tfp.get(), 20);

    tfp->open(option.GetVcdPath());

    // begin reset
    core->rst = 1;

    core->clk = 0;
    core->eval();

    core->clk = 1;
    core->eval();

    core->clk = 0;
    core->eval();

    // init memory
    if (option.IsRamPathValid())
    {
        system->LoadFileToMemory(option.GetRamPath(), rafi::emu::RamAddr);
    }
    if (option.IsRomPathValid())
    {
        system->LoadFileToMemory(option.GetRomPath(), rafi::emu::RomAddr);
    }

    // end reset
    core->rst = 0;

    for (int cycle = 0; cycle < option.GetCycle(); cycle++)
    {
        system->ProcessPositiveEdge();

        tfp->dump(cycle * 10 + 5);

        system->ProcessNegativeEdge();

        tfp->dump(cycle * 10 + 10);

        dumper->DumpCycle(cycle);

        system->UpdateSignal();
    }

    core->final();

    tfp->close();
}
