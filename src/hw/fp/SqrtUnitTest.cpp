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

#include "VSqrtUnit.h"
#include "FpTest.h"

namespace rafi { namespace test {

namespace {
    const int MaxCycle = 50;
}

class SqrtUnitTest : public FpTest<VSqrtUnit>
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
        GetTop()->src = 0;
        GetTop()->enable = false;

        // reset
        GetTop()->rst = 1;        
        GetTop()->clk = 0;
        GetTop()->eval();
        GetTfp()->dump(0);

        ProcessCycle();

        m_pTop->rst = 0;
    }

    virtual void TearDownModule() override
    {
    }
};

void RunTest(SqrtUnitTest* pTest, uint32_t expectedSqrt, uint32_t expectedRemnant, uint32_t src)
{
    pTest->GetTop()->src = src;
    pTest->GetTop()->enable = true;

    for (int i = 0; i < MaxCycle; i++)
    {
        pTest->ProcessCycle();
        
        if (pTest->GetTop()->done)
        {
            ASSERT_EQ(expectedSqrt, pTest->GetTop()->sqrt);
            ASSERT_EQ(expectedRemnant, pTest->GetTop()->remnant);
            return;
        }
    } 

    FAIL();
}

TEST_F(SqrtUnitTest, basic_0)
{
    RunTest(this, 0, 0, 0);
}

TEST_F(SqrtUnitTest, basic_1)
{
    RunTest(this, 1, 0, 1);
}

TEST_F(SqrtUnitTest, basic_2)
{
    RunTest(this, 1, 1, 2);
}

TEST_F(SqrtUnitTest, basic_3)
{
    RunTest(this, 1, 2, 3);
}

TEST_F(SqrtUnitTest, basic_4)
{
    RunTest(this, 2, 0, 4);
}

TEST_F(SqrtUnitTest, basic_5)
{
    RunTest(this, 2, 1, 5);
}

TEST_F(SqrtUnitTest, basic_81)
{
    RunTest(this, 9, 0, 81);
}

}}
