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

#include "FpTest.h"

namespace rafi { namespace test {

namespace {
    const int CMD_EQ = 1;
    const int CMD_LT = 2;
    const int CMD_LE = 3;
    const int CMD_MIN = 4;
    const int CMD_MAX = 5;
}

template<typename VTopModule>
class FpComparatorTest : public FpTest<VTopModule>
{
public:
    void ProcessCycle()
    {
        this->GetTop()->clk = 1;
        this->GetTop()->eval();
        this->GetTfp()->dump(this->m_Cycle * 10 + 5);

        this->GetTop()->clk = 0;
        this->GetTop()->eval();
        this->GetTfp()->dump(this->m_Cycle * 10 + 10);

        this->m_Cycle++;
    }

protected:
    virtual void SetUpModule() override
    {
        this->GetTop()->command = 0;
        this->GetTop()->fpSrc1 = 0;
        this->GetTop()->fpSrc2 = 0;

        // reset
        this->GetTop()->rst = 1;
        this->GetTop()->clk = 0;
        this->GetTop()->eval();
        this->GetTfp()->dump(0);

        ProcessCycle();

        this->GetTop()->rst = 0;
    }

    virtual void TearDownModule() override
    {
    }
};

}}
