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
    auto run_test = [this](int command, uint32_t fpSrc1, uint32_t fpSrc2, uint32_t expected)
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

    run_test(CommandEq, 0xbfae147b, 0xbfae147b, 1); // -1.36, -1.36
    run_test(CommandLe, 0xbfae147b, 0xbfae147b, 1); // -1.36, -1.36
    run_test(CommandLt, 0xbfae147b, 0xbfae147b, 0); // -1.36, -1.36

    run_test(CommandEq, 0xbfaf5c29, 0xbfae147b, 0); // -1.37, -1.36
    run_test(CommandLe, 0xbfaf5c29, 0xbfae147b, 1); // -1.37, -1.36
    run_test(CommandLt, 0xbfaf5c29, 0xbfae147b, 1); // -1.37, -1.36

    run_test(CommandEq, 0x7fffffff, 0x00000000, 0); // NaN, 0
    run_test(CommandEq, 0x7fffffff, 0x7fffffff, 0); // NaN, NaN
    run_test(CommandEq, 0x7f800001, 0x00000000, 0); // sNaNf, 0

    run_test(CommandLt, 0x7fffffff, 0x00000000, 0); // NaN, 0
    run_test(CommandLt, 0x7fffffff, 0x7fffffff, 0); // NaN, NaN
    run_test(CommandLt, 0x7f800001, 0x00000000, 0); // sNaNf, 0

    run_test(CommandLe, 0x7fffffff, 0x00000000, 0); // NaN, 0
    run_test(CommandLe, 0x7fffffff, 0x7fffffff, 0); // NaN, NaN
    run_test(CommandLe, 0x7f800001, 0x00000000, 0); // sNaNf, 0
}

}}
