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

#include "VICache.h"
#include <rafi/test.h>

namespace rafi { namespace test {

namespace {

const int MaxCycle = 100;

}

// ----------------------------------------------------------------------------
// Test fixture

class ICacheTest : public ModuleTest<VICache>
{
public:
    void ProcessCycle()
    {
        GetTop()->clk = 0;
        GetTop()->eval();
        GetTfp()->dump(m_Cycle * 10 + 5);

        GetTop()->clk = 1;
        GetTop()->eval();
        GetTfp()->dump(m_Cycle * 10 + 10);

        m_Cycle++;
    }

    void WaitMemReadEnable()
    {
        while (!GetTop()->memReadEnable)
        {
            ProcessCycle();

            if (m_Cycle > MaxCycle)
            {
                FAIL();
                return;
            }
        }
    }

    void WaitInvalidateDone()
    {
        while (!GetTop()->invalidateDone)
        {
            ProcessCycle();

            if (m_Cycle > MaxCycle)
            {
                FAIL();
                return;
            }
        }
    }

    void WaitNextStageValid()
    {
        while (!GetTop()->nextStageValid)
        {
            ProcessCycle();

            if (m_Cycle > MaxCycle)
            {
                FAIL();
                return;
            }
        }
    }

protected:
    virtual void SetUpModule() override
    {
        GetTop()->memReadDone = false;
        GetTop()->memReadValue = 0;

        GetTop()->fetchEnable = false;
        GetTop()->invalidateEnable = false;
        GetTop()->addr = 0;

        // reset
        GetTop()->rst = 1;

        GetTop()->clk = 1;
        GetTop()->eval();
        GetTfp()->dump(0);

        GetTop()->clk = 0;
        GetTop()->eval();
        GetTfp()->dump(m_Cycle * 10 + 5);

        GetTop()->rst = 0;

        GetTop()->clk = 1;
        GetTop()->eval();
        GetTfp()->dump(m_Cycle * 10 + 10);

        m_Cycle++;
    }

    virtual void TearDownModule() override
    {
    }
};

// ----------------------------------------------------------------------------
// Utilities

void DoFetch(ICacheTest* pTest, bool cacheHit, uint64_t addr, uint64_t readValue)
{
    pTest->GetTop()->fetchEnable = 1;
    pTest->GetTop()->addr = addr;
    pTest->ProcessCycle();

    if (cacheHit)
    {
        ASSERT_FALSE(pTest->GetTop()->nextStageCacheMiss);
    }
    else
    {
        ASSERT_TRUE(pTest->GetTop()->nextStageCacheMiss);

        pTest->WaitMemReadEnable();
        ASSERT_EQ(addr, pTest->GetTop()->memAddr);

        pTest->GetTop()->memReadDone = 1;
        pTest->GetTop()->memReadValue = readValue;

        pTest->ProcessCycle();

        pTest->GetTop()->memReadDone = 0;
        pTest->GetTop()->memReadValue = 0;
    }

    pTest->WaitNextStageValid();
    ASSERT_EQ(readValue, pTest->GetTop()->nextStageReadValue);

    pTest->GetTop()->fetchEnable = 0;
    pTest->GetTop()->addr = 0;

    pTest->ProcessCycle();
}

void DoInvalidate(ICacheTest* pTest, uint64_t addr)
{
    pTest->GetTop()->invalidateEnable = 1;
    pTest->GetTop()->addr = addr;

    pTest->WaitInvalidateDone();
    pTest->ProcessCycle();

    pTest->GetTop()->invalidateEnable = 0;
    pTest->GetTop()->addr = 0;

    pTest->ProcessCycle();
}

// ----------------------------------------------------------------------------
// Test cases

TEST_F(ICacheTest, SameLine)
{
    const uint64_t addr = 0x00000000'00000000ull;
    const uint64_t readValue = 0x12341234'56785678ull;

    DoFetch(this, false, addr, readValue);
    DoFetch(this, true, addr, readValue);
}

TEST_F(ICacheTest, SameIndex)
{
    const uint64_t addr1 = 0x00000000'10000000ull;
    const uint64_t addr2 = 0x00000000'20000000ull;
    const uint64_t readValue1 = 0xabababab'ababababull;
    const uint64_t readValue2 = 0xcdcdcdcd'cdcdcdcdull;

    DoFetch(this, false, addr1, readValue1);
    DoFetch(this, false, addr2, readValue2);
    DoFetch(this, false, addr1, readValue1);
}

TEST_F(ICacheTest, DifferentIndex)
{
    const uint64_t addr1 = 0x00000000'00000010ull;
    const uint64_t addr2 = 0x00000000'00000020ull;
    const uint64_t readValue1 = 0x5555aaaa'5555aaaaull;
    const uint64_t readValue2 = 0x66669999'66669999ull;

    DoFetch(this, false, addr1, readValue1);
    DoFetch(this, false, addr2, readValue2);
    DoFetch(this, true, addr1, readValue1);
}

TEST_F(ICacheTest, Invalidate)
{
    const uint64_t addr = 0x00000000'00000000ull;
    const uint64_t readValue = 0x12341234'56785678ull;

    DoFetch(this, false, addr, readValue);
    DoInvalidate(this, addr);
    DoFetch(this, false, addr, readValue);
}

}}
