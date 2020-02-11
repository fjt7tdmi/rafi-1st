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

#include "VFpSqrtUnit.h"
#include "FpTest.h"

namespace rafi { namespace test {

class FpSqrtUnitTest : public FpTest<VFpSqrtUnit>
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
        GetTop()->fpSrc = 0;

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

void RunTest(FpSqrtUnitTest* pTest, uint32_t expectedFlags, uint32_t expectedResult, uint32_t src)
{
    pTest->GetTop()->roundingMode = 0;
    pTest->GetTop()->fpSrc = src1;
    pTest->ProcessCycle();

    ASSERT_EQ(expectedFlags, pTest->GetTop()->flags);
    ASSERT_EQ(expectedResult, pTest->GetTop()->fpResult);
};

TEST_F(FpSqrtUnitTest, fdiv_5)
{
    RunTest(this, 1, 0x3fe2dfc5, 0x40490fdb); // 1.7724538498928541, 3.14159265
}

TEST_F(FpSqrtUnitTest, fdiv_6)
{
    RunTest(this, 0, 0x42c80000, 0x461c4000); // 100, 10000
}

TEST_F(FpSqrtUnitTest, fdiv_7)
{
    RunTest(this, 0x10, 0x7fc00000, 0xbf800000); // NaN, -1.0
}

TEST_F(FpSqrtUnitTest, fdiv_8)
{
    RunTest(this, 1, 0x41513a26, 0x432b0000); // 13.076696, 171.0
}

}}
