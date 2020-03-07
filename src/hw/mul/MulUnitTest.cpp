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

#include "VMulUnit.h"

namespace rafi { namespace test {

struct MulUnitConfig
{
    bool high;
    bool src1_signed;
    bool src2_signed;
};

const MulUnitConfig MulUnitConfigs[] = {
    { false, false, false },
    { false, false,  true },
    { false,  true, false },
    { false,  true,  true },
    {  true, false, false },
    {  true, false,  true },
    {  true,  true, false },
    {  true,  true,  true },
};

class MulUnitTest : public ::testing::TestWithParam<MulUnitConfig>
{
protected:
    virtual void SetUp() override
    {
        m_pTop = new VMulUnit();

        m_pTop->high = 0;
        m_pTop->src1_signed = 0;
        m_pTop->src2_signed = 0;
        m_pTop->src1 = 0;
        m_pTop->src2 = 0;
        m_pTop->enable = 0;
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

    VMulUnit* m_pTop;
};

INSTANTIATE_TEST_SUITE_P(AllConfig, MulUnitTest, ::testing::ValuesIn(MulUnitConfigs));

void DoBasicTest(VMulUnit* pTop, const MulUnitConfig& config, uint32_t src1, uint32_t src2)
{
    pTop->high = config.high;
    pTop->src1_signed = config.src1_signed;
    pTop->src2_signed = config.src2_signed;
    pTop->src1 = src1;
    pTop->src2 = src2;
    pTop->enable = 1;

    do
    {
        pTop->clk = 1;
        pTop->eval();
        pTop->clk = 0;
        pTop->eval();
    } while (!pTop->done);

    uint64_t expected;
    if (config.src1_signed && config.src2_signed)
    {
        const uint64_t lhs = SignExtend<uint64_t>(32, src1);
        const uint64_t rhs = SignExtend<uint64_t>(32, src2);
        expected = static_cast<uint64_t>(lhs * rhs);
    }
    else if (config.src1_signed && !config.src2_signed)
    {
        const uint64_t lhs = SignExtend<uint64_t>(32, src1);
        const uint64_t rhs = ZeroExtend<uint64_t>(32, src2);
        expected = static_cast<uint64_t>(lhs * rhs);
    }
    else if (!config.src1_signed && config.src2_signed)
    {
        const uint64_t lhs = ZeroExtend<uint64_t>(32, src1);
        const uint64_t rhs = SignExtend<uint64_t>(32, src2);
        expected = static_cast<uint64_t>(lhs * rhs);
    }
    else
    {
        const uint64_t lhs = ZeroExtend<uint64_t>(32, src1);
        const uint64_t rhs = ZeroExtend<uint64_t>(32, src2);
        expected = static_cast<uint64_t>(lhs * rhs);
    }

    if (config.high)
    {
        ASSERT_EQ(GetHigh32(expected), pTop->result);
    }
    else
    {
        ASSERT_EQ(GetLow32(expected), pTop->result);
    }
}

TEST_P(MulUnitTest, Basic)
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
}

}}
