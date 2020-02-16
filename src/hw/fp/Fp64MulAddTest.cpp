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

class Fp64MulAddTest : public FpMulAddTest<VFpMulAdd>
{
};

void RunTest(Fp64MulAddTest* pTest, int command, uint32_t expectedFlags, uint64_t expectedResult, uint64_t src1, uint64_t src2, uint64_t src3 = 0)
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

TEST_F(Fp64MulAddTest, fadd_2)
{
    RunTest(this, CMD_FADD, 0, 0x400c0000'00000000ull, 0x40040000'00000000ull, 0x3ff00000'00000000ull); // 3.5, 2,5 ,1.0
}

TEST_F(Fp64MulAddTest, fadd_3)
{
    RunTest(this, CMD_FADD, 1, 0xc0934800'00000000ull, 0xc0934c66'66666666ull, 0x3ff19999'9999999aull); // -1234, -1235.1, 1.1
}

TEST_F(Fp64MulAddTest, fadd_4)
{
    RunTest(this, CMD_FADD, 1, 0x400921fb'55206ddfull, 0x400921fb'53c8d4f1ull, 0x3e45798e'e2308c3aull); // 3.14159265, 3.14159265, 0.00000001
}

TEST_F(Fp64MulAddTest, fadd_5)
{
    RunTest(this, CMD_FSUB, 0, 0x3ff80000'00000000ull, 0x40040000'00000000ull, 0x3ff00000'00000000ull); // 1.5, 2,5 ,1.0
}

TEST_F(Fp64MulAddTest, fadd_6)
{
    RunTest(this, CMD_FSUB, 1, 0xc0934800'00000000ull, 0xc0934c66'66666666ull, 0xbff19999'9999999aull); // -1234, -1235.1, -1.1
}

TEST_F(Fp64MulAddTest, fadd_7)
{
    RunTest(this, CMD_FSUB, 1, 0x400921fb'52713c03ull, 0x400921fb'53c8d4f1ull, 0x3e45798e'e2308c3aull); // 3.1415926400000001, 3.14159265, 0.00000001
}

TEST_F(Fp64MulAddTest, fadd_8)
{
    RunTest(this, CMD_FMUL, 0, 0x40040000'00000000ull, 0x40040000'00000000ull, 0x3ff00000'00000000ull); // 2.5, 2,5 ,1.0
}

TEST_F(Fp64MulAddTest, fadd_9)
{
    RunTest(this, CMD_FMUL, 1, 0x40953a70'a3d70a3dull, 0xc0934c66'66666666ull, 0xbff19999'9999999aull); // 1358.61, -1235.1, -1.1
}

TEST_F(Fp64MulAddTest, fadd_10)
{
    RunTest(this, CMD_FMUL, 1, 0x3e60ddc5'a5c1ff09ull, 0x400921fb'53c8d4f1ull, 0x3e45798e'e2308c3aull); // 3.14159265e-8, 3.14159265, 0.00000001
}

TEST_F(Fp64MulAddTest, fadd_11)
{
    RunTest(this, CMD_FSUB, 0x10, 0x7ff80000'00000000ull, 0x7ff00000'00000000ull, 0x7ff00000'00000000ull); // qNaNf, Inf, Inf
}

TEST_F(Fp64MulAddTest, fmadd_2)
{
    RunTest(this, CMD_FMADD, 0, 0x400c0000'00000000ull, 0x3ff00000'00000000ull, 0x40040000'00000000ull, 0x3ff00000'00000000ull); // 3.5, 1.0, 2,5 ,1.0
}

TEST_F(Fp64MulAddTest, fmadd_3)
{
    RunTest(this, CMD_FMADD, 1, 0x409350cc'ccccccccull, 0xbff00000'00000000ull, 0xc0934c66'66666666ull, 0x3ff19999'9999999aull); // 1236.2, -1.0, -1235.1, 1.1
}

TEST_F(Fp64MulAddTest, fmadd_4)
{
    RunTest(this, CMD_FMADD, 0, 0xc0280000'00000000ull, 0x40000000'00000000ull, 0xc0140000'00000000ull, 0xc0000000'00000000ull); // -12.0, 2.0, -5.0, -2.0
}

TEST_F(Fp64MulAddTest, fmadd_5)
{
    RunTest(this, CMD_FNMADD, 0, 0xc00c0000'00000000ull, 0x3ff00000'00000000ull, 0x40040000'00000000ull, 0x3ff00000'00000000ull); // 3.5, 1.0, 2,5 ,1.0
}

TEST_F(Fp64MulAddTest, fmadd_6)
{
    RunTest(this, CMD_FNMADD, 1, 0xc09350cc'ccccccccull, 0xbff00000'00000000ull, 0xc0934c66'66666666ull, 0x3ff19999'9999999aull); // 1236.2, -1.0, -1235.1, 1.1
}

TEST_F(Fp64MulAddTest, fmadd_7)
{
    RunTest(this, CMD_FNMADD, 0, 0x40280000'00000000ull, 0x40000000'00000000ull, 0xc0140000'00000000ull, 0xc0000000'00000000ull); // 12.0, 2.0, -5.0, -2.0
}

TEST_F(Fp64MulAddTest, fmadd_8)
{
    RunTest(this, CMD_FMSUB, 0, 0x3ff80000'00000000ull, 0x3ff00000'00000000ull, 0x40040000'00000000ull, 0x3ff00000'00000000ull); // 3.5, 1.0, 2,5 ,1.0
}

TEST_F(Fp64MulAddTest, fmadd_9)
{
    RunTest(this, CMD_FMSUB, 1, 0x40934800'00000000ull, 0xbff00000'00000000ull, 0xc0934c66'66666666ull, 0x3ff19999'9999999aull); // 1234, -1.0, -1235.1, 1.1
}

TEST_F(Fp64MulAddTest, fmadd_10)
{
    RunTest(this, CMD_FMSUB, 0, 0xc0200000'00000000ull, 0x40000000'00000000ull, 0xc0140000'00000000ull, 0xc0000000'00000000ull); // -8.0, 2.0, -5.0, -2.0
}

TEST_F(Fp64MulAddTest, fmadd_11)
{
    RunTest(this, CMD_FNMSUB, 0, 0xbff80000'00000000ull, 0x3ff00000'00000000ull, 0x40040000'00000000ull, 0x3ff00000'00000000ull); // 3.5, 1.0, 2,5 ,1.0
}

TEST_F(Fp64MulAddTest, fmadd_12)
{
    RunTest(this, CMD_FNMSUB, 1, 0xc0934800'00000000ull, 0xbff00000'00000000ull, 0xc0934c66'66666666ull, 0x3ff19999'9999999aull); // -1234, -1.0, -1235.1, 1.1
}

TEST_F(Fp64MulAddTest, fmadd_13)
{
    RunTest(this, CMD_FNMSUB, 0, 0x40200000'00000000ull, 0x40000000'00000000ull, 0xc0140000'00000000ull, 0xc0000000'00000000ull); // 8.0, 2.0, -5.0, -2.0
}

}}
