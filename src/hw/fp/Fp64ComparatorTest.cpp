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

#include "FpComparatorTest.h"
#include "VFp64Comparator.h"

namespace rafi { namespace test {

class Fp64ComparatorTest : public FpComparatorTest<VFp64Comparator>
{
};

void RunTestFCMP(Fp64ComparatorTest* pTest, int command, uint64_t expected, uint64_t fpSrc1, uint64_t fpSrc2)
{
    pTest->GetTop()->command = command;
    pTest->GetTop()->fpSrc1 = fpSrc1;
    pTest->GetTop()->fpSrc2 = fpSrc2;

    pTest->GetTop()->clk = 1;
    pTest->GetTop()->eval();
    pTest->GetTop()->clk = 0;
    pTest->GetTop()->eval();

    ASSERT_EQ(expected, pTest->GetTop()->intResult);
};

TEST_F(Fp64ComparatorTest, fcmp_2)
{
    RunTestFCMP(this, CMD_EQ, 1, 0xbff5c28f'5c28f5c3ull, 0xbff5c28f'5c28f5c3ull); // -1.36, -1.36
}

TEST_F(Fp64ComparatorTest, fcmp_3)
{
    RunTestFCMP(this, CMD_LE, 1, 0xbff5c28f'5c28f5c3ull, 0xbff5c28f'5c28f5c3ull); // -1.36, -1.36
}

TEST_F(Fp64ComparatorTest, fcmp_4)
{
    RunTestFCMP(this, CMD_LT, 0, 0xbff5c28f'5c28f5c3ull, 0xbff5c28f'5c28f5c3ull); // -1.36, -1.36
}

TEST_F(Fp64ComparatorTest, fcmp_5)
{
    RunTestFCMP(this, CMD_EQ, 0, 0xbff5eb85'1eb851ecull, 0xbff5c28f'5c28f5c3ull); // -1.37, -1.36
}

TEST_F(Fp64ComparatorTest, fcmp_6)
{
    RunTestFCMP(this, CMD_LE, 1, 0xbff5eb85'1eb851ecull, 0xbff5c28f'5c28f5c3ull); // -1.37, -1.36
}

TEST_F(Fp64ComparatorTest, fcmp_7)
{
    RunTestFCMP(this, CMD_LT, 1, 0xbff5eb85'1eb851ecull, 0xbff5c28f'5c28f5c3ull); // -1.37, -1.36
}

TEST_F(Fp64ComparatorTest, fcmp_8)
{
    RunTestFCMP(this, CMD_EQ, 0, 0x7fffffff'ffffffffull, 0x00000000'00000000ull); // NaN, 0
}

TEST_F(Fp64ComparatorTest, fcmp_9)
{
    RunTestFCMP(this, CMD_EQ, 0, 0x7fffffff'ffffffffull, 0x7fffffff'ffffffffull); // NaN, NaN
}

TEST_F(Fp64ComparatorTest, fcmp_10)
{
    RunTestFCMP(this, CMD_EQ, 0, 0x7ff00000'00000001ull, 0x00000000'00000000ull); // sNaNf, 0
}

TEST_F(Fp64ComparatorTest, fcmp_11)
{
    RunTestFCMP(this, CMD_LT, 0, 0x7fffffff'ffffffffull, 0x00000000'00000000ull); // NaN, 0
}

TEST_F(Fp64ComparatorTest, fcmp_12)
{
    RunTestFCMP(this, CMD_LT, 0, 0x7fffffff'ffffffffull, 0x7fffffff'ffffffffull); // NaN, NaN
}

TEST_F(Fp64ComparatorTest, fcmp_13)
{
    RunTestFCMP(this, CMD_LT, 0, 0x7ff00000'00000001ull, 0x00000000'00000000ull); // sNaNf, 0
}

TEST_F(Fp64ComparatorTest, fcmp_14)
{
    RunTestFCMP(this, CMD_LE, 0, 0x7fffffff'ffffffffull, 0x00000000'00000000ull); // NaN, 0
}

TEST_F(Fp64ComparatorTest, fcmp_15)
{
    RunTestFCMP(this, CMD_LE, 0, 0x7fffffff'ffffffffull, 0x7fffffff'ffffffffull); // NaN, NaN
}

TEST_F(Fp64ComparatorTest, fcmp_16)
{
    RunTestFCMP(this, CMD_LE, 0, 0x7ff00000'00000001ull, 0x00000000'00000000ull); // sNaNf, 0
}

void RunTestFMIN(Fp64ComparatorTest* pTest, int command, uint64_t expected, uint64_t fpSrc1, uint64_t fpSrc2)
{
    pTest->GetTop()->command = command;
    pTest->GetTop()->fpSrc1 = fpSrc1;
    pTest->GetTop()->fpSrc2 = fpSrc2;

    pTest->GetTop()->clk = 1;
    pTest->GetTop()->eval();
    pTest->GetTop()->clk = 0;
    pTest->GetTop()->eval();

    ASSERT_EQ(expected, pTest->GetTop()->fpResult);
};

TEST_F(Fp64ComparatorTest, fmin_2)
{
    RunTestFMIN(this, CMD_MIN, 0x3ff00000'00000000ull, 0x40040000'00000000ull, 0x3ff00000'00000000ull); // 1.0, 2.5, 1.0
}

TEST_F(Fp64ComparatorTest, fmin_3)
{
    RunTestFMIN(this, CMD_MIN, 0xc0934c66'66666666ull, 0x3ff19999'9999999aull, 0xc0934c66'66666666ull); // -1235.1, -1235.1, 1.1
}

TEST_F(Fp64ComparatorTest, fmin_4)
{
    RunTestFMIN(this, CMD_MIN, 0xc0934c66'66666666ull, 0x3ff19999'9999999aull, 0xc0934c66'66666666ull); // -1235.1, 1.1, -1235.1
}

TEST_F(Fp64ComparatorTest, fmin_5)
{
    RunTestFMIN(this, CMD_MIN, 0xc0934c66'66666666ull, 0x7fffffff'ffffffffull, 0xc0934c66'66666666ull); // -1235.1, NaN, -1235.1
}

TEST_F(Fp64ComparatorTest, fmin_6)
{
    RunTestFMIN(this, CMD_MIN, 0x3e45798e'e2308c3aull, 0x400921fb'53c8d4f1ull, 0x3e45798e'e2308c3aull); // 0.00000001, 3.14159265, 0.00000001
}

TEST_F(Fp64ComparatorTest, fmin_7)
{
    RunTestFMIN(this, CMD_MIN, 0xc0000000'00000000ull, 0xbff00000'00000000ull, 0xc0000000'00000000ull); // -2.0, -1.0, -2.0
}

TEST_F(Fp64ComparatorTest, fmin_12)
{
    RunTestFMIN(this, CMD_MAX, 0x40040000'00000000ull, 0x40040000'00000000ull, 0x3ff00000'00000000ull); // 2.5, 2.5, 1.0
}

TEST_F(Fp64ComparatorTest, fmin_13)
{
    RunTestFMIN(this, CMD_MAX, 0x3ff19999'9999999aull, 0xc0934c66'66666666ull, 0x3ff19999'9999999aull); // 1.1, -1235.1, 1.1
}

TEST_F(Fp64ComparatorTest, fmin_14)
{
    RunTestFMIN(this, CMD_MAX, 0x3ff19999'9999999aull, 0x3ff19999'9999999aull, 0xc0934c66'66666666ull); // 1.1, 1.1, -1235.1
}

TEST_F(Fp64ComparatorTest, fmin_15)
{
    RunTestFMIN(this, CMD_MAX, 0xc0934c66'66666666ull, 0x7fffffff'ffffffffull, 0xc0934c66'66666666ull); // -1235.1, NaN, -1235.1
}

TEST_F(Fp64ComparatorTest, fmin_16)
{
    RunTestFMIN(this, CMD_MAX, 0x400921fb'53c8d4f1ull, 0x3e45798e'e2308c3aull, 0x400921fb'53c8d4f1ull); // 3.14159265, 3.14159265, 0.00000001
}

TEST_F(Fp64ComparatorTest, fmin_17)
{
    RunTestFMIN(this, CMD_MAX, 0xbff00000'00000000ull, 0xbff00000'00000000ull, 0xc0000000'00000000ull); // -1.0, -1.0, -2.0
}

TEST_F(Fp64ComparatorTest, fmin_20)
{
    RunTestFMIN(this, CMD_MAX, 0x3ff00000'00000000ull, 0x7ff00000'00000001ull, 0x3ff00000'00000000ull); // 1.0, sNaNf, 1.0
}

TEST_F(Fp64ComparatorTest, fmin_21)
{
    RunTestFMIN(this, CMD_MAX, 0x7ff80000'00000000ull, 0x7fffffff'ffffffffull, 0x7fffffff'ffffffffull); // qNaNf, NaN, NaN
}

TEST_F(Fp64ComparatorTest, fmin_30)
{
    RunTestFMIN(this, CMD_MIN, 0x80000000'00000000ull, 0x80000000'00000000ull, 0x00000000'00000000ull); // -0.0, -0.0,  0.0
}

TEST_F(Fp64ComparatorTest, fmin_31)
{
    RunTestFMIN(this, CMD_MIN, 0x80000000'00000000ull, 0x00000000'00000000ull, 0x80000000'00000000ull); // -0.0,  0.0, -0.0
}

TEST_F(Fp64ComparatorTest, fmin_32)
{
    RunTestFMIN(this, CMD_MAX, 0x00000000'00000000ull, 0x80000000'00000000ull, 0x00000000'00000000ull); //  0.0, -0.0,  0.0
}

TEST_F(Fp64ComparatorTest, fmin_33)
{
    RunTestFMIN(this, CMD_MAX, 0x00000000'00000000ull, 0x00000000'00000000ull, 0x80000000'00000000ull); //  0.0,  0.0, -0.0
}

}}
