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

#pragma once

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

#if defined(__GNUC__)
namespace fs = std::experimental::filesystem;
#else
namespace fs = std::filesystem;
#endif

namespace rafi { namespace test {

template<typename VTopModule>
class ModuleTest : public ::testing::Test
{
public:
    VTopModule* GetTop()
    {
        return m_pTop;
    }

    VerilatedVcdC* GetTfp()
    {
        return m_pTfp;        
    }
    
protected:
    virtual void SetUpModule() = 0;
    virtual void TearDownModule() = 0;

    virtual void SetUp() override
    {
        const char* dir = "work/vtest";
        fs::create_directories(dir);
        sprintf(m_VcdPath, "%s/%s.%s.vcd", dir,
            ::testing::UnitTest::GetInstance()->current_test_info()->test_case_name(),
            ::testing::UnitTest::GetInstance()->current_test_info()->name());

        Verilated::traceEverOn(true);

        m_pTfp = new VerilatedVcdC();
        m_pTop = new VTopModule();

        m_pTop->trace(m_pTfp, 20);
        m_pTfp->open(m_VcdPath);

        SetUpModule();
    }

    virtual void TearDown() override
    {
        TearDownModule();

        m_pTop->final();
        m_pTfp->close();

        delete m_pTop;
        delete m_pTfp;
    }

    char m_VcdPath[128];
    VerilatedVcdC* m_pTfp{ nullptr };
    VTopModule* m_pTop{ nullptr };
    int m_Cycle{ 0 };
};

}}
