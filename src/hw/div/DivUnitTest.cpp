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

#include "VDivUnit.h"

namespace rafi { namespace test {

struct DivUnitConfig
{
    bool isSigned;
};

const DivUnitConfig DivUnitConfigs[] = {
    { false },
    { true },
};

class DivUnitTest : public ::testing::TestWithParam<DivUnitConfig>
{
protected:
    virtual void SetUp() override
    {
        m_pTop = new VDivUnit();

        m_pTop->isSigned = 0;
        m_pTop->dividend = 0;
        m_pTop->divisor = 0;
        m_pTop->enable = 0;
        m_pTop->stall = 0;
        m_pTop->flush = 0;

        // reset
        m_pTop->rst = 1;
        m_pTop->clk = 0;
        m_pTop->eval();

        m_pTop->clk = 1;
        m_pTop->eval();

        m_pTop->clk = 0;
        m_pTop->rst = 0;
    }

    virtual void TearDown() override
    {
        m_pTop->final();

        delete m_pTop;
    }

    VDivUnit* m_pTop;
};

INSTANTIATE_TEST_SUITE_P(AllConfig, DivUnitTest, ::testing::ValuesIn(DivUnitConfigs));

void DoBasicTest(VDivUnit* pTop, const DivUnitConfig& config, uint32_t dividend, uint32_t divisor)
{
    pTop->isSigned = config.isSigned;
    pTop->dividend = dividend;
    pTop->divisor = divisor;
    pTop->enable = true;

    do
    {
        pTop->clk = 1;
        pTop->eval();
        pTop->clk = 0;
        pTop->eval();
    } while (!pTop->done);

    if (config.isSigned)
    {
        // quotient
        if (dividend == 0x80000000 && divisor == 0xffffffff)
        {
            ASSERT_EQ(0x80000000, pTop->quotient);
        }
        else if (divisor == 0x00000000)
        {
            ASSERT_EQ(0xffffffff, pTop->quotient);
        }
        else
        {
            ASSERT_EQ(static_cast<int32_t>(dividend) / static_cast<int32_t>(divisor), pTop->quotient);
        }

        // remnant
        if (dividend == 0x80000000 && divisor == 0xffffffff)
        {
            ASSERT_EQ(0x00000000, pTop->remnant);
        }
        else if (divisor == 0x00000000)
        {
            ASSERT_EQ(dividend, pTop->remnant);
        }
        else
        {
            ASSERT_EQ(static_cast<int32_t>(dividend) % static_cast<int32_t>(divisor), pTop->remnant);
        }
    }
    else
    {
        // quotient
        if (divisor == 0x00000000)
        {
            ASSERT_EQ(0xffffffff, pTop->quotient);
        }
        else
        {
            ASSERT_EQ(dividend / divisor, pTop->quotient);
        }

        // remnant
        if (divisor == 0x00000000)
        {
            ASSERT_EQ(dividend, pTop->remnant);
        }
        else
        {
            ASSERT_EQ(dividend % divisor, pTop->remnant);
        }
    }

    pTop->enable = false;
    pTop->clk = 1;
    pTop->eval();
    pTop->clk = 0;
    pTop->eval();
}

TEST_P(DivUnitTest, Basic)
{
    DoBasicTest(this->m_pTop, GetParam(), 0x00000000, 0x00000001);
    DoBasicTest(this->m_pTop, GetParam(), 0x00000000, 0x00000000);
    DoBasicTest(this->m_pTop, GetParam(), 0x00000000, 0x7fffffff);
    DoBasicTest(this->m_pTop, GetParam(), 0x00000000, 0x80000000);
    DoBasicTest(this->m_pTop, GetParam(), 0x00000000, 0xffffffff);
    DoBasicTest(this->m_pTop, GetParam(), 0x00000001, 0x00000000);
    DoBasicTest(this->m_pTop, GetParam(), 0x00000001, 0x00000001);
    DoBasicTest(this->m_pTop, GetParam(), 0x00000001, 0x7fffffff);
    DoBasicTest(this->m_pTop, GetParam(), 0x00000001, 0x80000000);
    DoBasicTest(this->m_pTop, GetParam(), 0x00000001, 0xffffffff);
    DoBasicTest(this->m_pTop, GetParam(), 0x7fffffff, 0x00000000);
    DoBasicTest(this->m_pTop, GetParam(), 0x7fffffff, 0x00000001);
    DoBasicTest(this->m_pTop, GetParam(), 0x7fffffff, 0x7fffffff);
    DoBasicTest(this->m_pTop, GetParam(), 0x7fffffff, 0x80000000);
    DoBasicTest(this->m_pTop, GetParam(), 0x7fffffff, 0xffffffff);
    DoBasicTest(this->m_pTop, GetParam(), 0x80000000, 0x00000001);
    DoBasicTest(this->m_pTop, GetParam(), 0x80000000, 0x00000000);
    DoBasicTest(this->m_pTop, GetParam(), 0x80000000, 0x7fffffff);
    DoBasicTest(this->m_pTop, GetParam(), 0x80000000, 0x80000000);
    DoBasicTest(this->m_pTop, GetParam(), 0x80000000, 0xffffffff);
    DoBasicTest(this->m_pTop, GetParam(), 0xffffffff, 0x00000000);
    DoBasicTest(this->m_pTop, GetParam(), 0xffffffff, 0x00000001);
    DoBasicTest(this->m_pTop, GetParam(), 0xffffffff, 0x7fffffff);
    DoBasicTest(this->m_pTop, GetParam(), 0xffffffff, 0x80000000);
    DoBasicTest(this->m_pTop, GetParam(), 0xffffffff, 0xffffffff);
    DoBasicTest(this->m_pTop, GetParam(), 0x00001234, 0x00005678);
    DoBasicTest(this->m_pTop, GetParam(), 0x12340000, 0x56780000);
    DoBasicTest(this->m_pTop, GetParam(), 0x12345678, 0x12345678);
    DoBasicTest(this->m_pTop, GetParam(), 0x12345678, 0xabcdabcd);
    DoBasicTest(this->m_pTop, GetParam(), 0xabcdabcd, 0xabcdabcd);

    for (int i = 0; i < 256; i++)
    {
        DoBasicTest(this->m_pTop, GetParam(), 0x000000ff, i);
    }

    DoBasicTest(this->m_pTop, GetParam(), 20, 6);
}

}}
