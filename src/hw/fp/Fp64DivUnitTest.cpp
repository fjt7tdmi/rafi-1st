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
#include "VFp64DivUnit.h"

namespace rafi { namespace test {

class Fp64DivUnitTest : public FpDivUnitTest<VFp64DivUnit>
{
};

void RunTest(Fp64DivUnitTest* pTest, uint32_t expectedFlags, uint64_t expectedResult, uint64_t src1, uint64_t src2)
{
    pTest->GetTop()->roundingMode = 0;
    pTest->GetTop()->fpSrc1 = src1;
    pTest->GetTop()->fpSrc2 = src2;
    pTest->ProcessCycle();

    ASSERT_EQ(expectedFlags, pTest->GetTop()->flags);
    ASSERT_EQ(expectedResult, pTest->GetTop()->fpResult);
};

TEST_F(Fp64DivUnitTest, fdiv_2)
{
    RunTest(this, 1, 0x3ff27ddb'f6c383ecull, 0x400921fb'53c8d4f1ull, 0x4005bf0a'89f1b0ddull); // 1.1557273520668288, 3.14159265, 2.71828182
}

TEST_F(Fp64DivUnitTest, fdiv_3)
{
    RunTest(this, 1, 0xbfeff8b4'3e1929a5ull, 0xc0934800'00000000ull, 0x40934c66'66666666ull); // -0.9991093838555584, -1234, 1235.1
}

TEST_F(Fp64DivUnitTest, fdiv_4)
{
    RunTest(this, 0, 0x400921fb'53c8d4f1ull, 0x400921fb'53c8d4f1ull, 0x3ff00000'00000000ull); // 3.14159265, 3.14159265, 1.0
}

}}
