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

#include "VFpMulAdd.h"
#include "FpMulAddTest.h"

namespace rafi { namespace test {

class Fp32MulAddTest : public FpMulAddTest<VFpMulAdd>
{
};

void RunTest(Fp32MulAddTest* pTest, int command, uint32_t expectedFlags, uint32_t expectedResult, uint32_t src1, uint32_t src2, uint32_t src3 = 0)
{
    pTest->GetTop()->command = command;
    pTest->GetTop()->roundingMode = 0;
    pTest->GetTop()->fpSrc1 = src1;
    pTest->GetTop()->fpSrc2 = src2;
    pTest->GetTop()->fpSrc3 = src3;
    pTest->ProcessCycle();

    ASSERT_EQ(expectedFlags, pTest->GetTop()->flags);
    ASSERT_EQ(expectedResult, pTest->GetTop()->fpResult);
};

TEST_F(Fp32MulAddTest, fadd_2)
{
    RunTest(this, CMD_FADD, 0, 0x40600000, 0x3f800000, 0x40200000); // 3.5, 2,5 ,1.0
}

TEST_F(Fp32MulAddTest, fadd_3)
{
    RunTest(this, CMD_FADD, 1, 0xc49a4000, 0xc49a6333, 0x3f8ccccd); // -1234, -1235.1, 1.1
}

TEST_F(Fp32MulAddTest, fadd_4)
{
    RunTest(this, CMD_FADD, 1, 0x40490fdb, 0x40490fdb, 0x322bcc77); // 3.14159265, 3.14159265, 0.00000001
}

TEST_F(Fp32MulAddTest, fadd_5)
{
    RunTest(this, CMD_FSUB, 0, 0x3fc00000, 0x40200000, 0x3f800000); // 1.5, 2,5 ,1.0
}

TEST_F(Fp32MulAddTest, fadd_6)
{
    RunTest(this, CMD_FSUB, 1, 0xc49a4000, 0xc49a6333, 0xbf8ccccd); // -1234, -1235.1, -1.1
}

TEST_F(Fp32MulAddTest, fadd_7)
{
    RunTest(this, CMD_FSUB, 1, 0x40490fdb, 0x40490fdb, 0x322bcc77); // 3.14159265, 3.14159265, 0.00000001
}

TEST_F(Fp32MulAddTest, fadd_8)
{
    RunTest(this, CMD_FMUL, 0, 0x40200000, 0x40200000, 0x3f800000); // 2.5, 2,5 ,1.0
}

TEST_F(Fp32MulAddTest, fadd_9)
{
    RunTest(this, CMD_FMUL, 1, 0x44a9d385, 0xc49a6333, 0xbf8ccccd); // 1358.61, -1235.1, -1.1
}

TEST_F(Fp32MulAddTest, fadd_10)
{
    RunTest(this, CMD_FMUL, 1, 0x3306ee2d, 0x40490fdb, 0x322bcc77); // 3.14159265e-8, 3.14159265, 0.00000001
}

TEST_F(Fp32MulAddTest, fadd_11)
{
    RunTest(this, CMD_FSUB, 0x10, 0x7fc00000, 0x7f800000, 0x7f800000); // qNaNf, Inf, Inf
}

TEST_F(Fp32MulAddTest, fmadd_2)
{
    RunTest(this, CMD_FMADD, 0, 0x40600000, 0x3f800000, 0x40200000, 0x3f800000); // 3.5, 1.0, 2,5 ,1.0
}

TEST_F(Fp32MulAddTest, fmadd_3)
{
    RunTest(this, CMD_FMADD, 1, 0x449a8666, 0xbf800000, 0xc49a6333, 0x3f8ccccd); // 1236.2, -1.0, -1235.1, 1.1
}

TEST_F(Fp32MulAddTest, fmadd_4)
{
    RunTest(this, CMD_FMADD, 0, 0xc1400000, 0x40000000, 0xc0a00000, 0xc0000000); // -12.0, 2.0, -5.0, -2.0
}

TEST_F(Fp32MulAddTest, fmadd_5)
{
    RunTest(this, CMD_FNMADD, 0, 0xc0600000, 0x3f800000, 0x40200000, 0x3f800000); // 3.5, 1.0, 2,5 ,1.0
}

TEST_F(Fp32MulAddTest, fmadd_6)
{
    RunTest(this, CMD_FNMADD, 1, 0xc49a8666, 0xbf800000, 0xc49a6333, 0x3f8ccccd); // 1236.2, -1.0, -1235.1, 1.1
}

TEST_F(Fp32MulAddTest, fmadd_7)
{
    RunTest(this, CMD_FNMADD, 0, 0x41400000, 0x40000000, 0xc0a00000, 0xc0000000); // -12.0, 2.0, -5.0, -2.0
}

TEST_F(Fp32MulAddTest, fmadd_8)
{
    RunTest(this, CMD_FMSUB, 0, 0x3fc00000, 0x3f800000, 0x40200000, 0x3f800000); // 3.5, 1.0, 2,5 ,1.0
}

TEST_F(Fp32MulAddTest, fmadd_9)
{
    RunTest(this, CMD_FMSUB, 1, 0x449a4000, 0xbf800000, 0xc49a6333, 0x3f8ccccd); // 1236.2, -1.0, -1235.1, 1.1
}

TEST_F(Fp32MulAddTest, fmadd_10)
{
    RunTest(this, CMD_FMSUB, 0, 0xc1000000, 0x40000000, 0xc0a00000, 0xc0000000); // -12.0, 2.0, -5.0, -2.0
}

TEST_F(Fp32MulAddTest, fmadd_11)
{
    RunTest(this, CMD_FNMSUB, 0, 0xbfc00000, 0x3f800000, 0x40200000, 0x3f800000); // 3.5, 1.0, 2,5 ,1.0
}

TEST_F(Fp32MulAddTest, fmadd_12)
{
    RunTest(this, CMD_FNMSUB, 1, 0xc49a4000, 0xbf800000, 0xc49a6333, 0x3f8ccccd); // 1236.2, -1.0, -1235.1, 1.1
}

TEST_F(Fp32MulAddTest, fmadd_13)
{
    RunTest(this, CMD_FNMSUB, 0, 0x41000000, 0x40000000, 0xc0a00000, 0xc0000000); // -12.0, 2.0, -5.0, -2.0
}

}}
