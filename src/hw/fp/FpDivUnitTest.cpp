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

#include "VFpDivUnit.h"

#if defined(__GNUC__)
namespace fs = std::experimental::filesystem;
#else
namespace fs = std::filesystem;
#endif

namespace rafi { namespace test {

class FpDivUnitTest : public ::testing::Test
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

    VFpDivUnit* GetTop()
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
        m_pTop = new VFpDivUnit();

        m_pTop->trace(m_pTfp, 20);
        m_pTfp->open(m_VcdPath);

        m_pTop->roundingMode = 0;
        m_pTop->fpSrc1 = 0;
        m_pTop->fpSrc2 = 0;

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
    VFpDivUnit* m_pTop{ nullptr };
    int m_Cycle{ 0 };
};

void RunTest(FpDivUnitTest* pTest, uint32_t expectedFlags, uint32_t expectedResult, uint32_t src1, uint32_t src2)
{
    pTest->GetTop()->roundingMode = 0;
    pTest->GetTop()->fpSrc1 = src1;
    pTest->GetTop()->fpSrc2 = src2;
    pTest->ProcessCycle();

    ASSERT_EQ(expectedFlags, pTest->GetTop()->flags);
    ASSERT_EQ(expectedResult, pTest->GetTop()->fpResult);
};

TEST_F(FpDivUnitTest, fdiv_2)
{
    RunTest(this, 1, 0x3f93eee0, 0x40490fdb, 0x402df854); // 1.1557273520668288, 3.14159265, 2.71828182
}

TEST_F(FpDivUnitTest, fdiv_3)
{
    RunTest(this, 1, 0xbf7fc5a2, 0xc49a4000, 0x449a6333); // -0.9991093838555584, -1234, 1235.1
}

TEST_F(FpDivUnitTest, fdiv_4)
{
    RunTest(this, 0, 0x40490fdb, 0x40490fdb, 0x3f800000); // 3.14159265, 3.14159265, 1.0
}

}}
