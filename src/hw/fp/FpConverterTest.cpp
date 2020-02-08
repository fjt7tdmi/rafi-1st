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

#pragma warning(push)
#pragma warning(disable : 4389)
#include <gtest/gtest.h>
#pragma warning(pop)

#include <rafi/common.h>

#include "VFpConverter.h"

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

class FpConverterTest : public ::testing::Test
{
protected:
    virtual void SetUp() override
    {
        m_pTop = new VFpConverter();

        m_pTop->command = 0;
        m_pTop->roundingMode = 0;
        m_pTop->intSrc = 0;
        m_pTop->fpSrc = 0;

        // reset
        m_pTop->rst = 1;
        m_pTop->clk = 0;
        m_pTop->eval();

        m_pTop->clk = 1;
        m_pTop->eval();

        m_pTop->clk = 0;
        m_pTop->rst = 0;
        m_pTop->eval();
    }

    virtual void TearDown() override
    {
        m_pTop->final();

        delete m_pTop;
    }

    VFpConverter* m_pTop;
};

void run_test_fcvt(VFpConverter* pTop, int command, uint32_t expectedResult, uint32_t intSrc)
{
    pTop->command = command;
    pTop->roundingMode = 0;
    pTop->intSrc = intSrc;
    pTop->fpSrc = 0;

    pTop->clk = 1;
    pTop->eval();
    pTop->clk = 0;
    pTop->eval();

    ASSERT_EQ(expectedResult, pTop->fpResult);
};

TEST_F(FpConverterTest, fcvt_2)
{
    run_test_fcvt(m_pTop, CMD_S_W, 0x40000000, 0x00000002); //  2.0,  2
}

TEST_F(FpConverterTest, fcvt_3)
{
    run_test_fcvt(m_pTop, CMD_S_W, 0xc0000000, 0xfffffffe); // -2.0, -2
}

TEST_F(FpConverterTest, fcvt_4)
{
    run_test_fcvt(m_pTop, CMD_S_WU, 0x40000000, 0x00000002); //         2.0,  2
}

TEST_F(FpConverterTest, fcvt_5)
{
    run_test_fcvt(m_pTop, CMD_S_WU, 0x4f800000, 0xfffffffe); // 4.2949673e9, -2
}

void run_test_fcvt_w_with_flags(VFpConverter* pTop, int command, uint32_t expectedFlags, uint32_t expectedResult, uint32_t fpSrc, int roundingMode)
{
    pTop->command = command;
    pTop->roundingMode = roundingMode;
    pTop->intSrc = 0;
    pTop->fpSrc = fpSrc;

    pTop->clk = 1;
    pTop->eval();
    pTop->clk = 0;
    pTop->eval();

    ASSERT_EQ(expectedFlags, pTop->flags);
    ASSERT_EQ(expectedResult, pTop->intResult);
}

TEST_F(FpConverterTest, fcvt_w_2)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_W_S, 0x01, 0xffffffff, 0xbf8ccccd, FRM_RTZ); // -1, -1.1
}

TEST_F(FpConverterTest, fcvt_w_3)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_W_S, 0x00, 0xffffffff, 0xbf800000, FRM_RTZ); // -1, -1.0
}

TEST_F(FpConverterTest, fcvt_w_4)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_W_S, 0x01, 0x00000000, 0xbf666666, FRM_RTZ); //  0, -0.9
}

TEST_F(FpConverterTest, fcvt_w_5)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_W_S, 0x01, 0x00000000, 0x3f666666, FRM_RTZ); //  0,  0.9
}

TEST_F(FpConverterTest, fcvt_w_6)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_W_S, 0x00, 0x00000001, 0x3f800000, FRM_RTZ); //  1,  1.0
}

TEST_F(FpConverterTest, fcvt_w_7)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_W_S, 0x01, 0x00000001, 0x3f8ccccd, FRM_RTZ); //  1,  1.1
}

TEST_F(FpConverterTest, fcvt_w_8)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_W_S, 0x10, 0x80000000, 0xcf32d05e, FRM_RTZ); //    -1<<31, -3e9
}

TEST_F(FpConverterTest, fcvt_w_9)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_W_S, 0x10, 0x7fffffff, 0x4f32d05e, FRM_RTZ); // (1<<31)-1,  3e9
}

TEST_F(FpConverterTest, fcvt_w_12)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_WU_S, 0x10, 0x00000000, 0xc0400000, FRM_RTZ); // 0, -3.0
}

TEST_F(FpConverterTest, fcvt_w_13)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_WU_S, 0x10, 0x00000000, 0xbf800000, FRM_RTZ); // 0, -1.0
}

TEST_F(FpConverterTest, fcvt_w_14)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_WU_S, 0x01, 0x00000000, 0xbf666666, FRM_RTZ); // 0, -0.9
}

TEST_F(FpConverterTest, fcvt_w_15)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_WU_S, 0x01, 0x00000000, 0x3f666666, FRM_RTZ); // 0,  0.9
}

TEST_F(FpConverterTest, fcvt_w_16)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_WU_S, 0x00, 0x00000001, 0x3f800000, FRM_RTZ); // 1,  1.0
}

TEST_F(FpConverterTest, fcvt_w_17)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_WU_S, 0x01, 0x00000001, 0x3f8ccccd, FRM_RTZ); // 1,  1.1
}

TEST_F(FpConverterTest, fcvt_w_18)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_WU_S, 0x10, 0x00000000, 0xcf32d05e, FRM_RTZ); // 0, -3e9
}

TEST_F(FpConverterTest, fcvt_w_19)
{
    run_test_fcvt_w_with_flags(m_pTop, CMD_WU_S, 0x00, 0xb2d05e00, 0x4f32d05e, FRM_RTZ); // 300000000, 3e9
}

void run_test_fcvt_w(VFpConverter* pTop, int command, uint32_t expectedResult, uint32_t fpSrc)
{
    pTop->command = command;
    pTop->roundingMode = 0;
    pTop->intSrc = 0;
    pTop->fpSrc = fpSrc;

    pTop->clk = 1;
    pTop->eval();
    pTop->clk = 0;
    pTop->eval();

    ASSERT_EQ(expectedResult, pTop->intResult);
}

TEST_F(FpConverterTest, fcvt_w_42)
{
    run_test_fcvt_w(m_pTop, CMD_W_S, 0x7fffffff, 0xffffffff);
}

TEST_F(FpConverterTest, fcvt_w_44)
{
    run_test_fcvt_w(m_pTop, CMD_W_S, 0x80000000, 0xff800000);
}

TEST_F(FpConverterTest, fcvt_w_52)
{
    run_test_fcvt_w(m_pTop, CMD_W_S, 0x7fffffff, 0x7fffffff);
}

TEST_F(FpConverterTest, fcvt_w_54)
{
    run_test_fcvt_w(m_pTop, CMD_W_S, 0x7fffffff, 0x7f800000);
}

TEST_F(FpConverterTest, fcvt_w_62)
{
    run_test_fcvt_w(m_pTop, CMD_WU_S, 0xffffffff, 0xffffffff);
}

TEST_F(FpConverterTest, fcvt_w_63)
{
    run_test_fcvt_w(m_pTop, CMD_WU_S, 0xffffffff, 0x7fffffff);
}

TEST_F(FpConverterTest, fcvt_w_64)
{
    run_test_fcvt_w(m_pTop, CMD_WU_S, 0x00000000, 0xff800000);
}

TEST_F(FpConverterTest, fcvt_w_65)
{
    run_test_fcvt_w(m_pTop, CMD_WU_S, 0xffffffff, 0x7f800000);
}

}}
