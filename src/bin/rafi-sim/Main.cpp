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

#include "CommandLineOption.h"
#include "Simulator.h"

int main(int argc, char** argv)
{
    rafi::sim::CommandLineOption option(argc, argv);
    rafi::sim::Simulator simulator(option);

    simulator.Process(option.GetCycle());

    std::cout << "Simulation finished @ cycle "
        << std::dec << simulator.GetCycle()
        << std::hex << " (0x" << simulator.GetCycle() << ")" << std::endl;

    return 0;
}

