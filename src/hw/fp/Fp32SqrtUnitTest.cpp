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

#include "VFp32SqrtUnit.h"
#include "FpSqrtUnitTest.h"

namespace rafi { namespace test {

namespace {
    const int MaxCycle = 50;
}

class Fp32SqrtUnitTest : public FpSqrtUnitTest<VFp32SqrtUnit>
{
};

void RunTest(Fp32SqrtUnitTest* pTest, uint32_t expectedFlags, uint32_t expectedResult, uint32_t src)
{
    pTest->GetTop()->roundingMode = 0;
    pTest->GetTop()->fpSrc = src;
    pTest->GetTop()->enable = true;

    for (int i = 0; i < MaxCycle; i++)
    {
        pTest->ProcessCycle();

        if (pTest->GetTop()->done)
        {
            ASSERT_EQ(expectedFlags, pTest->GetTop()->flags);
            ASSERT_EQ(expectedResult, pTest->GetTop()->fpResult);
            return;
        }
    }

    FAIL();
}

TEST_F(Fp32SqrtUnitTest, fdiv_5)
{
    RunTest(this, 1, 0x3fe2dfc5, 0x40490fdb); // 1.7724538498928541, 3.14159265
}

TEST_F(Fp32SqrtUnitTest, fdiv_6)
{
    RunTest(this, 0, 0x42c80000, 0x461c4000); // 100, 10000
}

TEST_F(Fp32SqrtUnitTest, fdiv_7)
{
    RunTest(this, 0x10, 0x7fc00000, 0xbf800000); // NaN, -1.0
}

TEST_F(Fp32SqrtUnitTest, fdiv_8)
{
    RunTest(this, 1, 0x41513a26, 0x432b0000); // 13.076696, 171.0
}

}}
