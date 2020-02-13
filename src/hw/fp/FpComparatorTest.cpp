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

#include "FpTest.h"
#include "VFpComparator.h"

namespace rafi { namespace test {

namespace {
    const int CMD_EQ = 1;
    const int CMD_LT = 2;
    const int CMD_LE = 3;
    const int CMD_MIN = 4;
    const int CMD_MAX = 5;
}

class FpComparatorTest : public FpTest<VFpComparator>
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
        GetTop()->command = 0;
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

void RunTestFCMP(FpComparatorTest* pTest, int command, uint32_t expected, uint32_t fpSrc1, uint32_t fpSrc2)
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

TEST_F(FpComparatorTest, fcmp_2)
{
    RunTestFCMP(this, CMD_EQ, 1, 0xbfae147b, 0xbfae147b); // -1.36, -1.36
}

TEST_F(FpComparatorTest, fcmp_3)
{
    RunTestFCMP(this, CMD_LE, 1, 0xbfae147b, 0xbfae147b); // -1.36, -1.36
}

TEST_F(FpComparatorTest, fcmp_4)
{
    RunTestFCMP(this, CMD_LT, 0, 0xbfae147b, 0xbfae147b); // -1.36, -1.36
}

TEST_F(FpComparatorTest, fcmp_5)
{
    RunTestFCMP(this, CMD_EQ, 0, 0xbfaf5c29, 0xbfae147b); // -1.37, -1.36
}

TEST_F(FpComparatorTest, fcmp_6)
{
    RunTestFCMP(this, CMD_LE, 1, 0xbfaf5c29, 0xbfae147b); // -1.37, -1.36
}

TEST_F(FpComparatorTest, fcmp_7)
{
    RunTestFCMP(this, CMD_LT, 1, 0xbfaf5c29, 0xbfae147b); // -1.37, -1.36
}

TEST_F(FpComparatorTest, fcmp_8)
{
    RunTestFCMP(this, CMD_EQ, 0, 0x7fffffff, 0x00000000); // NaN, 0
}

TEST_F(FpComparatorTest, fcmp_9)
{
    RunTestFCMP(this, CMD_EQ, 0, 0x7fffffff, 0x7fffffff); // NaN, NaN
}

TEST_F(FpComparatorTest, fcmp_10)
{
    RunTestFCMP(this, CMD_EQ, 0, 0x7f800001, 0x00000000); // sNaNf, 0
}

TEST_F(FpComparatorTest, fcmp_11)
{
    RunTestFCMP(this, CMD_LT, 0, 0x7fffffff, 0x00000000); // NaN, 0
}

TEST_F(FpComparatorTest, fcmp_12)
{
    RunTestFCMP(this, CMD_LT, 0, 0x7fffffff, 0x7fffffff); // NaN, NaN
}

TEST_F(FpComparatorTest, fcmp_13)
{
    RunTestFCMP(this, CMD_LT, 0, 0x7f800001, 0x00000000); // sNaNf, 0
}

TEST_F(FpComparatorTest, fcmp_14)
{
    RunTestFCMP(this, CMD_LE, 0, 0x7fffffff, 0x00000000); // NaN, 0
}

TEST_F(FpComparatorTest, fcmp_15)
{
    RunTestFCMP(this, CMD_LE, 0, 0x7fffffff, 0x7fffffff); // NaN, NaN
}

TEST_F(FpComparatorTest, fcmp_16)
{
    RunTestFCMP(this, CMD_LE, 0, 0x7f800001, 0x00000000); // sNaNf, 0
}

void RunTestFMIN(FpComparatorTest* pTest, int command, uint32_t expected, uint32_t fpSrc1, uint32_t fpSrc2)
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

TEST_F(FpComparatorTest, fmin_2)
{
    RunTestFMIN(this, CMD_MIN, 0x3f800000, 0x40200000, 0x3f800000); // 1.0, 2.5, 1.0
}

TEST_F(FpComparatorTest, fmin_3)
{
    RunTestFMIN(this, CMD_MIN, 0xc49a6333, 0xc49a6333, 0x3f8ccccd); // -1235.1, -1235.1, 1.1
}

TEST_F(FpComparatorTest, fmin_4)
{
    RunTestFMIN(this, CMD_MIN, 0xc49a6333, 0x3f8ccccd, 0xc49a6333); // -1235.1, 1.1, -1235.1
}

TEST_F(FpComparatorTest, fmin_5)
{
    RunTestFMIN(this, CMD_MIN, 0xc49a6333, 0x7fffffff, 0xc49a6333); // -1235.1, NaN, -1235.1
}

TEST_F(FpComparatorTest, fmin_6)
{
    RunTestFMIN(this, CMD_MIN, 0x322bcc77, 0x40490fdb, 0x322bcc77); // 0.00000001, 3.14159265, 0.00000001
}

TEST_F(FpComparatorTest, fmin_7)
{
    RunTestFMIN(this, CMD_MIN, 0xc0000000, 0xbf800000, 0xc0000000); // -2.0, -1.0, -2.0
}

TEST_F(FpComparatorTest, fmin_12)
{
    RunTestFMIN(this, CMD_MAX, 0x40200000, 0x40200000, 0x3f800000); // 2.5, 2.5, 1.0
}

TEST_F(FpComparatorTest, fmin_13)
{
    RunTestFMIN(this, CMD_MAX, 0x3f8ccccd, 0xc49a6333, 0x3f8ccccd); // 1.1, -1235.1, 1.1
}

TEST_F(FpComparatorTest, fmin_14)
{
    RunTestFMIN(this, CMD_MAX, 0x3f8ccccd, 0x3f8ccccd, 0xc49a6333); // 1.1, 1.1, -1235.1
}

TEST_F(FpComparatorTest, fmin_15)
{
    RunTestFMIN(this, CMD_MAX, 0xc49a6333, 0x7fffffff, 0xc49a6333); // -1235.1, NaN, -1235.1
}

TEST_F(FpComparatorTest, fmin_16)
{
    RunTestFMIN(this, CMD_MAX, 0x40490fdb, 0x40490fdb, 0x322bcc77); // 3.14159265, 3.14159265, 0.00000001
}

TEST_F(FpComparatorTest, fmin_17)
{
    RunTestFMIN(this, CMD_MAX, 0xbf800000, 0xbf800000, 0xc0000000); // -1.0, -1.0, -2.0
}

TEST_F(FpComparatorTest, fmin_20)
{
    RunTestFMIN(this, CMD_MAX, 0x3f800000, 0x7f800001, 0x3f800000); // 1.0, sNaNf, 1.0
}

TEST_F(FpComparatorTest, fmin_21)
{
    RunTestFMIN(this, CMD_MAX, 0x7fc00000, 0x7fffffff, 0x7fffffff); // qNaNf, NaN, NaN
}

TEST_F(FpComparatorTest, fmin_30)
{
    RunTestFMIN(this, CMD_MIN, 0x80000000, 0x80000000, 0x00000000); // -0.0, -0.0,  0.0
}

TEST_F(FpComparatorTest, fmin_31)
{
    RunTestFMIN(this, CMD_MIN, 0x80000000, 0x00000000, 0x80000000); // -0.0,  0.0, -0.0
}

TEST_F(FpComparatorTest, fmin_32)
{
    RunTestFMIN(this, CMD_MAX, 0x00000000, 0x80000000, 0x00000000); //  0.0, -0.0,  0.0
}

TEST_F(FpComparatorTest, fmin_33)
{
    RunTestFMIN(this, CMD_MAX, 0x00000000, 0x00000000, 0x80000000); //  0.0,  0.0, -0.0
}

}}
