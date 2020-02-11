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

#if defined(__GNUC__)
#include <experimental/filesystem>
#else
#include <filesystem>
#endif

#pragma warning(push)
#pragma warning(disable : 4389)
#include <gtest/gtest.h>
#pragma warning(pop)

#include <rafi/common.h>

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "VFpSqrtUnit.h"

#if defined(__GNUC__)
namespace fs = std::experimental::filesystem;
#else
namespace fs = std::filesystem;
#endif

namespace rafi { namespace test {

class FpSqrtUnitTest : public ::testing::Test
{
public:
    void ProcessCycle()
    {
        m_pTop->clk = 1;
        m_pTop->eval();
        m_pTfp->dump(m_Cycle * 10 + 5);

        m_pTop->clk = 0;
        m_pTop->eval();
        m_pTfp->dump(m_Cycle * 10 + 10);

        m_Cycle++;
    }

    VFpSqrtUnit* GetTop()
    {
        return m_pTop;
    }

protected:
    virtual void SetUp() override
    {
        const char* dir = "work/vtest";
        fs::create_directories(dir);
        sprintf(m_VcdPath, "%s/%s.%s.vcd", dir,
            ::testing::UnitTest::GetInstance()->current_test_info()->test_case_name(),
            ::testing::UnitTest::GetInstance()->current_test_info()->name());

        Verilated::traceEverOn(true);

        m_pTfp = new VerilatedVcdC();
        m_pTop = new VFpSqrtUnit();

        m_pTop->trace(m_pTfp, 20);
        m_pTfp->open(m_VcdPath);

        m_pTop->roundingMode = 0;
        m_pTop->fpSrc = 0;

        // reset
        m_pTop->rst = 1;        
        m_pTop->clk = 0;
        m_pTop->eval();
        m_pTfp->dump(0);

        ProcessCycle();

        m_pTop->rst = 0;
    }

    virtual void TearDown() override
    {
        m_pTop->final();
        m_pTfp->close();

        delete m_pTop;
        delete m_pTfp;
    }

    char m_VcdPath[128];
    VerilatedVcdC* m_pTfp{ nullptr };
    VFpSqrtUnit* m_pTop{ nullptr };
    int m_Cycle{ 0 };
};

void RunTest(FpSqrtUnitTest* pTest, uint32_t expectedFlags, uint32_t expectedResult, uint32_t src)
{
    pTest->GetTop()->roundingMode = 0;
    pTest->GetTop()->fpSrc = src1;
    pTest->ProcessCycle();

    ASSERT_EQ(expectedFlags, pTest->GetTop()->flags);
    ASSERT_EQ(expectedResult, pTest->GetTop()->fpResult);
};

TEST_F(FpSqrtUnitTest, fdiv_5)
{
    RunTest(this, 1, 0x3fe2dfc5, 0x40490fdb); // 1.7724538498928541, 3.14159265
}

TEST_F(FpSqrtUnitTest, fdiv_6)
{
    RunTest(this, 0, 0x42c80000, 0x461c4000); // 100, 10000
}

TEST_F(FpSqrtUnitTest, fdiv_7)
{
    RunTest(this, 0x10, 0x7fc00000, 0xbf800000); // NaN, -1.0
}

TEST_F(FpSqrtUnitTest, fdiv_8)
{
    RunTest(this, 1, 0x41513a26, 0x432b0000); // 13.076696, 171.0
}

}}
