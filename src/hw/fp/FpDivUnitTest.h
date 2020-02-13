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

template<typename VTopModule>
class FpDivUnitTest : public FpTest<VTopModule>
{
public:
    void ProcessCycle()
    {
        GetTop()->clk = 1;
        GetTop()->eval();
        GetTfp()->dump(m_Cycle * 10 + 5);

        GetTop()->clk = 0;
        GetTop()->eval();
        GetTfp()->dump(m_Cycle * 10 + 10);

        m_Cycle++;
    }

protected:
    virtual void SetUpModule() override
    {
        GetTop()->roundingMode = 0;
        GetTop()->fpSrc1 = 0;
        GetTop()->fpSrc2 = 0;

        // reset
        GetTop()->rst = 1;
        GetTop()->clk = 0;
        GetTop()->eval();
        GetTfp()->dump(0);

        ProcessCycle();

        GetTop()->rst = 0;
    }

    virtual void TearDownModule() override
    {
    }
};

}}
