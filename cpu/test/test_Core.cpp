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

#include "../../work/verilator/test_Core/VCore.h"

int main()
{
    auto top = std::make_unique<VCore>();

    // reset
    top->rstIn = 1;
    top->clk = 0;
    top->eval();

    top->clk = 1;
    top->eval();

    top->clk = 0;
    top->rstIn = 0;
    top->eval();

    for (int i = 0; i < 10; i++)
    {
        top->clk = 1;
        top->eval();

        for (int i = 0; i < 32; i++)
        {
            printf("0x%08x\n", top->Core__DOT__m_RegFile__DOT__body[i]);
        }

        top->clk = 0;
        top->eval();
    }

    top->final();
}
