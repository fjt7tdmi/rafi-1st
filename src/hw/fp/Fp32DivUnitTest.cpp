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

#include "FpDivUnitTest.h"
#include "VFp32DivUnit.h"

namespace rafi { namespace test {

class Fp32DivUnitTest : public FpDivUnitTest<VFp32DivUnit>
{
};

void RunTest(Fp32DivUnitTest* pTest, uint32_t expectedFlags, uint32_t expectedResult, uint32_t src1, uint32_t src2)
{
    pTest->GetTop()->roundingMode = 0;
    pTest->GetTop()->fpSrc1 = src1;
    pTest->GetTop()->fpSrc2 = src2;
    pTest->ProcessCycle();

    ASSERT_EQ(expectedFlags, pTest->GetTop()->flags);
    ASSERT_EQ(expectedResult, pTest->GetTop()->fpResult);
};

TEST_F(Fp32DivUnitTest, fdiv_2)
{
    RunTest(this, 1, 0x3f93eee0, 0x40490fdb, 0x402df854); // 1.1557273520668288, 3.14159265, 2.71828182
}

TEST_F(Fp32DivUnitTest, fdiv_3)
{
    RunTest(this, 1, 0xbf7fc5a2, 0xc49a4000, 0x449a6333); // -0.9991093838555584, -1234, 1235.1
}

TEST_F(Fp32DivUnitTest, fdiv_4)
{
    RunTest(this, 0, 0x40490fdb, 0x40490fdb, 0x3f800000); // 3.14159265, 3.14159265, 1.0
}

}}
