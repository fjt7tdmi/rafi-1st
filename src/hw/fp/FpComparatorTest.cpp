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

#include "VFpComparator.h"

namespace rafi { namespace test {

namespace {
    const int CommandEq = 1;
    const int CommandLt = 2;
    const int CommandLe = 3;
    const int CommandMin = 4;
    const int CommandMax = 5;
}

class FpComparatorTest : public ::testing::Test
{
protected:
    virtual void SetUp() override
    {
        m_pTop = new VFpComparator();

        m_pTop->command = 0;
        m_pTop->fpSrc1 = 0;
        m_pTop->fpSrc2 = 0;

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

    VFpComparator* m_pTop;
};

TEST_F(FpComparatorTest, fcmp)
{
    auto run_test = [this](int command, uint32_t expected, uint32_t fpSrc1, uint32_t fpSrc2)
    {
        this->m_pTop->command = command;
        this->m_pTop->fpSrc1 = fpSrc1;
        this->m_pTop->fpSrc2 = fpSrc2;

        this->m_pTop->clk = 1;
        this->m_pTop->eval();
        this->m_pTop->clk = 0;
        this->m_pTop->eval();

        ASSERT_EQ(expected, this->m_pTop->intResult);
    };

    run_test(CommandEq, 1, 0xbfae147b, 0xbfae147b); // -1.36, -1.36
    run_test(CommandLe, 1, 0xbfae147b, 0xbfae147b); // -1.36, -1.36
    run_test(CommandLt, 0, 0xbfae147b, 0xbfae147b); // -1.36, -1.36

    run_test(CommandEq, 0, 0xbfaf5c29, 0xbfae147b); // -1.37, -1.36
    run_test(CommandLe, 1, 0xbfaf5c29, 0xbfae147b); // -1.37, -1.36
    run_test(CommandLt, 1, 0xbfaf5c29, 0xbfae147b); // -1.37, -1.36

    run_test(CommandEq, 0, 0x7fffffff, 0x00000000); // NaN, 0
    run_test(CommandEq, 0, 0x7fffffff, 0x7fffffff); // NaN, NaN
    run_test(CommandEq, 0, 0x7f800001, 0x00000000); // sNaNf, 0

    run_test(CommandLt, 0, 0x7fffffff, 0x00000000); // NaN, 0
    run_test(CommandLt, 0, 0x7fffffff, 0x7fffffff); // NaN, NaN
    run_test(CommandLt, 0, 0x7f800001, 0x00000000); // sNaNf, 0

    run_test(CommandLe, 0, 0x7fffffff, 0x00000000); // NaN, 0
    run_test(CommandLe, 0, 0x7fffffff, 0x7fffffff); // NaN, NaN
    run_test(CommandLe, 0, 0x7f800001, 0x00000000); // sNaNf, 0
}

TEST_F(FpComparatorTest, fmin)
{
    auto run_test = [this](int command, uint32_t expected, uint32_t fpSrc1, uint32_t fpSrc2)
    {
        this->m_pTop->command = command;
        this->m_pTop->fpSrc1 = fpSrc1;
        this->m_pTop->fpSrc2 = fpSrc2;

        this->m_pTop->clk = 1;
        this->m_pTop->eval();
        this->m_pTop->clk = 0;
        this->m_pTop->eval();

        ASSERT_EQ(expected, this->m_pTop->fpResult);
    };

    run_test(CommandMin, 0x3f800000, 0x40200000, 0x3f800000); // 1.0, 2.5, 1.0
    run_test(CommandMin, 0xc49a6333, 0xc49a6333, 0x3f8ccccd); // -1235.1, -1235.1, 1.1
    run_test(CommandMin, 0xc49a6333, 0x3f8ccccd, 0xc49a6333); // -1235.1, 1.1, -1235.1, 
    run_test(CommandMin, 0xc49a6333, 0x7fffffff, 0xc49a6333); // -1235.1, NaN, -1235.1, 
    run_test(CommandMin, 0x322bcc77, 0x40490fdb, 0x322bcc77); // 0.00000001, 3.14159265, 0.00000001
    run_test(CommandMin, 0xc0000000, 0xbf800000, 0xc0000000); // -2.0, -1.0, -2.0

    run_test(CommandMax, 0x40200000, 0x40200000, 0x3f800000); // 2.5, 2.5, 1.0
    run_test(CommandMax, 0x3f8ccccd, 0xc49a6333, 0x3f8ccccd); // 1.1, -1235.1, 1.1
    run_test(CommandMax, 0x3f8ccccd, 0x3f8ccccd, 0xc49a6333); // 1.1, 1.1, -1235.1, 
    run_test(CommandMax, 0xc49a6333, 0x7fffffff, 0xc49a6333); // -1235.1, NaN, -1235.1, 
    run_test(CommandMax, 0x40490fdb, 0x40490fdb, 0x322bcc77); // 3.14159265, 3.14159265, 0.00000001
    run_test(CommandMax, 0xbf800000, 0xbf800000, 0xc0000000); // -1.0, -1.0, -2.0

    run_test(CommandMax, 0x3f800000, 0x7f800001, 0x3f800000); // 1.0, sNaNf, 1.0
    run_test(CommandMax, 0x7fc00000, 0x7fffffff, 0x7fffffff); // qNaNf, NaN, NaN

    run_test(CommandMin, 0x80000000, 0x80000000, 0x00000000); // -0.0, -0.0,  0.0
    run_test(CommandMin, 0x80000000, 0x00000000, 0x80000000); // -0.0,  0.0, -0.0
    run_test(CommandMax, 0x00000000, 0x80000000, 0x00000000); //  0.0, -0.0,  0.0
    run_test(CommandMax, 0x00000000, 0x00000000, 0x80000000); //  0.0,  0.0, -0.0
}

}}
