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

#include "VFp64SqrtUnit.h"
#include "FpSqrtUnitTest.h"

namespace rafi { namespace test {

namespace {
    const int MaxCycle = 50;
}

class Fp64SqrtUnitTest : public FpSqrtUnitTest<VFp64SqrtUnit>
{
};

void RunTest(Fp64SqrtUnitTest* pTest, uint32_t expectedFlags, uint64_t expectedResult, uint64_t src)
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

TEST_F(Fp64SqrtUnitTest, fdiv_5)
{
    RunTest(this, 1, 0x3ffc5bf8'916f587bull, 0x400921fb'53c8d4f1ull); // 1.7724538498928541, 3.14159265
}

TEST_F(Fp64SqrtUnitTest, fdiv_6)
{
    RunTest(this, 0, 0x40590000'00000000ull, 0x40c38800'00000000ull); // 100, 10000
}

TEST_F(Fp64SqrtUnitTest, fdiv_16)
{
    RunTest(this, 0x10, 0x7ff80000'00000000ull, 0x40c38800'00000000ull); // NaN, -1.0
}

TEST_F(Fp64SqrtUnitTest, fdiv_7)
{
    RunTest(this, 1, 0x402a2744'ce9674f5ull, 0x40656000'00000000ull); // 13.076696830622021, 171.0
}

TEST_F(Fp64SqrtUnitTest, fdiv_8)
{
    RunTest(this, 1, 0x3f3a4789'c0e37f99ull, 0x3e8594df'c70aa105ull); // 0.00040099251863345283320230749702, 1.60795e-7
}

}}
