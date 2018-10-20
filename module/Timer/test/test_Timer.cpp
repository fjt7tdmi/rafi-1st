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

#include "../obj_dir/VTimer.h"

int main()
{
    auto top = std::make_unique<VTimer>();

    // reset
    top->rst = 1;
    top->clk = 0;
    top->eval();

    top->clk = 1;
    top->eval();

    top->clk = 0;
    top->rst = 0;
    top->addr = 0;
    top->writeData = 0;
    top->readEnable = 1;
    top->writeEnable = 0;
    top->eval();

    for (int i = 0; i < 10; i++)
    {
        top->clk = 1;
        top->eval();

        int value = top->readData;
        printf("value: %d\n", value);

        top->clk = 0;
        top->eval();
    }

    top->final();
}
