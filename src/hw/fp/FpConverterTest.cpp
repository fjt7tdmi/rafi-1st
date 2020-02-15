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

#include "VFpConverter.h"
#include "FpTest.h"

namespace rafi { namespace test {

namespace {
    // Command
    const int CMD_W_S  = 0x0;
    const int CMD_WU_S = 0x1;
    const int CMD_L_S  = 0x2;
    const int CMD_LU_S = 0x3;
    const int CMD_W_D  = 0x4;
    const int CMD_WU_D = 0x5;
    const int CMD_L_D  = 0x6;
    const int CMD_LU_D = 0x7;
    const int CMD_S_W  = 0x8;
    const int CMD_S_WU = 0x9;
    const int CMD_S_L  = 0xa;
    const int CMD_S_LU = 0xb;
    const int CMD_D_W  = 0xc;
    const int CMD_D_WU = 0xd;
    const int CMD_D_L  = 0xe;
    const int CMD_D_LU = 0xf;

    // Rounding Mode
    const int FRM_RNE = 0b000; // Round to Nearest, ties to Even
    const int FRM_RTZ = 0b001; // Round towards Zero
    const int FRM_RDN = 0b010; // Round Down
    const int FRM_RUP = 0b011; // Round Up
    const int FRM_RMM = 0b100; // Round to Nearest, ties to Max Magnitude
    const int FRM_DYN = 0b111; // In instruction's rm field, selects dynamic rounding mode; In Rounding Mode register, Invalid.
}

class FpConverterTest : public FpTest<VFpConverter>
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
        GetTop()->roundingMode = 0;
        GetTop()->intSrc = 0;
        GetTop()->fpSrc = 0;

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

void RunTest_FCVT(FpConverterTest* pTest, int command, uint64_t expectedResult, uint32_t intSrc)
{
    pTest->GetTop()->command = command;
    pTest->GetTop()->roundingMode = 0;
    pTest->GetTop()->intSrc = intSrc;
    pTest->GetTop()->fpSrc = 0;
    pTest->ProcessCycle();

    ASSERT_EQ(expectedResult, pTest->GetTop()->fpResult);
};

TEST_F(FpConverterTest, fcvt_f2)
{
    RunTest_FCVT(this, CMD_S_W, 0x40000000, 0x00000002); //  2.0,  2
}

TEST_F(FpConverterTest, fcvt_f3)
{
    RunTest_FCVT(this, CMD_S_W, 0xc0000000, 0xfffffffe); // -2.0, -2
}

TEST_F(FpConverterTest, fcvt_f4)
{
    RunTest_FCVT(this, CMD_S_WU, 0x40000000, 0x00000002); // 2.0,  2
}

TEST_F(FpConverterTest, fcvt_f5)
{
    RunTest_FCVT(this, CMD_S_WU, 0x4f800000, 0xfffffffe); // 4.2949673e9, 2^32-2
}

TEST_F(FpConverterTest, fcvt_d2)
{
    RunTest_FCVT(this, CMD_D_W, 0x40000000'00000000ull, 0x00000002); //  2.0,  2
}

TEST_F(FpConverterTest, fcvt_d3)
{
    RunTest_FCVT(this, CMD_D_W, 0xc0000000'00000000ull, 0xfffffffe); // -2.0, -2
}

TEST_F(FpConverterTest, fcvt_d4)
{
    RunTest_FCVT(this, CMD_D_WU, 0x40000000'00000000ull, 0x00000002); // 2.0,  2
}

TEST_F(FpConverterTest, fcvt_d5)
{
    RunTest_FCVT(this, CMD_D_WU, 0x41efffff'ffc00000ull, 0xfffffffe); // 4.2949673e9, 2^32-2
}

void RunTest_FCVT_W_WithFlags(FpConverterTest* pTest, int command, uint32_t expectedFlags, uint32_t expectedResult, uint64_t fpSrc, int roundingMode)
{
    pTest->GetTop()->command = command;
    pTest->GetTop()->roundingMode = roundingMode;
    pTest->GetTop()->intSrc = 0;
    pTest->GetTop()->fpSrc = fpSrc;
    pTest->ProcessCycle();

    ASSERT_EQ(expectedFlags, pTest->GetTop()->writeFlagsValue);
    ASSERT_EQ(expectedResult, pTest->GetTop()->intResult);
}

TEST_F(FpConverterTest, fcvt_w_f2)
{
    RunTest_FCVT_W_WithFlags(this, CMD_W_S, 0x01, 0xffffffff, 0xbf8ccccd, FRM_RTZ); // -1, -1.1
}

TEST_F(FpConverterTest, fcvt_w_f3)
{
    RunTest_FCVT_W_WithFlags(this, CMD_W_S, 0x00, 0xffffffff, 0xbf800000, FRM_RTZ); // -1, -1.0
}

TEST_F(FpConverterTest, fcvt_w_f4)
{
    RunTest_FCVT_W_WithFlags(this, CMD_W_S, 0x01, 0x00000000, 0xbf666666, FRM_RTZ); //  0, -0.9
}

TEST_F(FpConverterTest, fcvt_w_f5)
{
    RunTest_FCVT_W_WithFlags(this, CMD_W_S, 0x01, 0x00000000, 0x3f666666, FRM_RTZ); //  0,  0.9
}

TEST_F(FpConverterTest, fcvt_w_f6)
{
    RunTest_FCVT_W_WithFlags(this, CMD_W_S, 0x00, 0x00000001, 0x3f800000, FRM_RTZ); //  1,  1.0
}

TEST_F(FpConverterTest, fcvt_w_f7)
{
    RunTest_FCVT_W_WithFlags(this, CMD_W_S, 0x01, 0x00000001, 0x3f8ccccd, FRM_RTZ); //  1,  1.1
}

TEST_F(FpConverterTest, fcvt_w_f8)
{
    RunTest_FCVT_W_WithFlags(this, CMD_W_S, 0x10, 0x80000000, 0xcf32d05e, FRM_RTZ); //    -1<<31, -3e9
}

TEST_F(FpConverterTest, fcvt_w_f9)
{
    RunTest_FCVT_W_WithFlags(this, CMD_W_S, 0x10, 0x7fffffff, 0x4f32d05e, FRM_RTZ); // (1<<31)-1,  3e9
}

TEST_F(FpConverterTest, fcvt_w_f12)
{
    RunTest_FCVT_W_WithFlags(this, CMD_WU_S, 0x10, 0x00000000, 0xc0400000, FRM_RTZ); // 0, -3.0
}

TEST_F(FpConverterTest, fcvt_w_f13)
{
    RunTest_FCVT_W_WithFlags(this, CMD_WU_S, 0x10, 0x00000000, 0xbf800000, FRM_RTZ); // 0, -1.0
}

TEST_F(FpConverterTest, fcvt_w_f14)
{
    RunTest_FCVT_W_WithFlags(this, CMD_WU_S, 0x01, 0x00000000, 0xbf666666, FRM_RTZ); // 0, -0.9
}

TEST_F(FpConverterTest, fcvt_w_f15)
{
    RunTest_FCVT_W_WithFlags(this, CMD_WU_S, 0x01, 0x00000000, 0x3f666666, FRM_RTZ); // 0,  0.9
}

TEST_F(FpConverterTest, fcvt_w_f16)
{
    RunTest_FCVT_W_WithFlags(this, CMD_WU_S, 0x00, 0x00000001, 0x3f800000, FRM_RTZ); // 1,  1.0
}

TEST_F(FpConverterTest, fcvt_w_f17)
{
    RunTest_FCVT_W_WithFlags(this, CMD_WU_S, 0x01, 0x00000001, 0x3f8ccccd, FRM_RTZ); // 1,  1.1
}

TEST_F(FpConverterTest, fcvt_w_f18)
{
    RunTest_FCVT_W_WithFlags(this, CMD_WU_S, 0x10, 0x00000000, 0xcf32d05e, FRM_RTZ); // 0, -3e9
}

TEST_F(FpConverterTest, fcvt_w_f19)
{
    RunTest_FCVT_W_WithFlags(this, CMD_WU_S, 0x00, 0xb2d05e00, 0x4f32d05e, FRM_RTZ); // 300000000, 3e9
}

void RunTest_FCVT_W(FpConverterTest* pTest, int command, uint32_t expectedResult, uint32_t fpSrc)
{
    pTest->GetTop()->command = command;
    pTest->GetTop()->roundingMode = 0;
    pTest->GetTop()->intSrc = 0;
    pTest->GetTop()->fpSrc = fpSrc;
    pTest->ProcessCycle();

    ASSERT_EQ(expectedResult, pTest->GetTop()->intResult);
}

TEST_F(FpConverterTest, fcvt_w_f42)
{
    RunTest_FCVT_W(this, CMD_W_S, 0x7fffffff, 0xffffffff);
}

TEST_F(FpConverterTest, fcvt_w_f44)
{
    RunTest_FCVT_W(this, CMD_W_S, 0x80000000, 0xff800000);
}

TEST_F(FpConverterTest, fcvt_w_f52)
{
    RunTest_FCVT_W(this, CMD_W_S, 0x7fffffff, 0x7fffffff);
}

TEST_F(FpConverterTest, fcvt_w_f54)
{
    RunTest_FCVT_W(this, CMD_W_S, 0x7fffffff, 0x7f800000);
}

TEST_F(FpConverterTest, fcvt_w_f62)
{
    RunTest_FCVT_W(this, CMD_WU_S, 0xffffffff, 0xffffffff);
}

TEST_F(FpConverterTest, fcvt_w_f63)
{
    RunTest_FCVT_W(this, CMD_WU_S, 0xffffffff, 0x7fffffff);
}

TEST_F(FpConverterTest, fcvt_w_f64)
{
    RunTest_FCVT_W(this, CMD_WU_S, 0x00000000, 0xff800000);
}

TEST_F(FpConverterTest, fcvt_w_f65)
{
    RunTest_FCVT_W(this, CMD_WU_S, 0xffffffff, 0x7f800000);
}

}}
