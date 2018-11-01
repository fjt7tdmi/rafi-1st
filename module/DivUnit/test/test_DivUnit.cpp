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

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "../../../work/verilator/test_DivUnit/VDivUnit32.h"

int main()
{
    Verilated::traceEverOn(true);

    auto vcd = std::make_unique<VerilatedVcdC>();
    auto top = std::make_unique<VDivUnit32>();

    top->trace(vcd.get(), 20);
    vcd->open("test_DivUnit.vcd");

    // reset
    top->rst = 1;
    top->clk = 0;
    top->eval();

    top->clk = 1;
    top->eval();

    top->clk = 0;
    top->rst = 0;

    top->isSigned = 1;
    top->dividend = 20;
    top->divisor = 6;
    top->enable = 1;
    top->stall = 0;
    top->flush = 0;
    top->eval();

    const int maxCycle = 100;

    for (int i = 0; i < maxCycle; i++)
    {
        top->clk = 1;
        top->eval();

        if (top->done)
        {
            break;
        }

        top->clk = 0;
        top->eval();
    }

    if (top->done)
    {
        printf("q:%d r:%d \n", top->quotient, top->remnant);
    }
    else
    {
        printf("Not done\n");
    }

    top->final();
    vcd->close();
}
