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

#include "../../../work/verilator/test_Core/VCore.h"

#include "Dumper.h"
#include "Memory.h"
#include "Option.h"

int main(int argc, char** argv)
{
    Option option(argc, argv);

    auto memory = std::make_unique<Memory>();
    auto core = std::make_unique<VCore>();
    auto dumper = std::make_unique<Dumper>(option.GetDumpPath(), core.get());

    // begin reset
    core->rstIn = 1;

    core->clk = 0;
    core->eval();

    core->clk = 1;
    core->eval();

    core->clk = 0;
    core->eval();

    // init memory
    memory->LoadFile(option.GetLoadPath());
    memory->UpdateCore(core.get());

    // end reset
    core->rstIn = 0;

    for (int cycle = 0; cycle < option.GetCycle(); cycle++)
    {
        core->clk = 1;
        core->eval();

        core->clk = 0;
        core->eval();

        dumper->DumpCycle(cycle);

        memory->UpdateCore(core.get());
    }

    core->final();
}
