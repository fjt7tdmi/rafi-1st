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

#include "VDCache.h"
#include <rafi/test.h>

namespace rafi { namespace test {

namespace {

const int MaxCycle = 100;

// Command
const uint32_t CMD_LOAD              = 0;
const uint32_t CMD_LOAD_RESERVED     = 1;
const uint32_t CMD_STORE             = 2;
const uint32_t CMD_STORE_CONDITIONAL = 3;
const uint32_t CMD_INVALIDATE        = 4;

}

// ----------------------------------------------------------------------------
// Test fixture

class DCacheTest : public ModuleTest<VDCache>
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

    void WaitMemWriteEnable()
    {
        while (!GetTop()->memWriteEnable)
        {
            ProcessCycle();

            if (m_Cycle > MaxCycle)
            {
                FAIL();
                return;
            }
        }
    }

    void WaitDone()
    {
        while (!GetTop()->done)
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
        GetTop()->memWriteDone = false;
        GetTop()->memReadValue = 0;

        GetTop()->enable = false;
        GetTop()->command = 0;
        GetTop()->addr = 0;
        GetTop()->writeMask = 0;
        GetTop()->writeValue = 0;

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

void DoLoad(DCacheTest* pTest, bool cacheHit, uint64_t addr, uint64_t readValue, bool reserved = false)
{
    pTest->GetTop()->enable = 1;
    pTest->GetTop()->command = reserved ? CMD_LOAD_RESERVED : CMD_LOAD;
    pTest->GetTop()->addr = addr;

    if (!cacheHit)
    {
        pTest->WaitMemReadEnable();
        ASSERT_EQ(addr, pTest->GetTop()->memAddr);

        pTest->GetTop()->memReadDone = 1;
        pTest->GetTop()->memReadValue = readValue;

        pTest->ProcessCycle();

        pTest->GetTop()->memReadDone = 0;
        pTest->GetTop()->memReadValue = 0;
    }

    pTest->WaitDone();
    ASSERT_FALSE(pTest->GetTop()->storeConditionalFailure);
    ASSERT_EQ(readValue, pTest->GetTop()->readValue);

    pTest->ProcessCycle();

    pTest->GetTop()->enable = 0;
    pTest->GetTop()->command = 0;
    pTest->GetTop()->addr = 0;

    pTest->ProcessCycle();
}

void DoLoadReserved(DCacheTest* pTest, bool cacheHit, uint64_t addr, uint64_t readValue)
{
    DoLoad(pTest, cacheHit, addr, readValue, true);
}

void DoStore(DCacheTest* pTest, bool cacheHit, uint64_t addr, uint64_t writeValue, uint8_t writeMask, uint64_t memReadValue, uint64_t memWriteValue, bool conditional = false, bool storeConditionalFailure = false)
{
    pTest->GetTop()->enable = 1;
    pTest->GetTop()->command = conditional ? CMD_STORE_CONDITIONAL : CMD_STORE;
    pTest->GetTop()->addr = addr;
    pTest->GetTop()->writeMask = writeMask;
    pTest->GetTop()->writeValue = writeValue;

    if (!cacheHit && !conditional)
    {
        pTest->WaitMemReadEnable();
        ASSERT_EQ(addr, pTest->GetTop()->memAddr);

        pTest->GetTop()->memReadDone = 1;
        pTest->GetTop()->memReadValue = memReadValue;

        pTest->ProcessCycle();

        pTest->GetTop()->memReadDone = 0;
        pTest->GetTop()->memReadValue = 0;
    }

    if (conditional && storeConditionalFailure)
    {
        pTest->WaitDone();
        ASSERT_TRUE(pTest->GetTop()->storeConditionalFailure);
    }
    else
    {
        pTest->WaitMemWriteEnable();
        ASSERT_EQ(addr, pTest->GetTop()->memAddr);
        ASSERT_EQ(memWriteValue, pTest->GetTop()->memWriteValue);

        pTest->GetTop()->memWriteDone = 1;
    }

    pTest->ProcessCycle();

    pTest->GetTop()->enable = 0;
    pTest->GetTop()->command = 0;
    pTest->GetTop()->addr = 0;
    pTest->GetTop()->memWriteDone = 0;

    pTest->ProcessCycle();
}

void DoStoreConditional(DCacheTest* pTest, bool cacheHit, uint64_t addr, uint64_t writeValue, uint8_t writeMask, uint64_t memReadValue, uint64_t memWriteValue, bool storeConditionalFailure = false)
{
    DoStore(pTest, cacheHit, addr, writeValue, writeMask, memReadValue, memWriteValue, true, storeConditionalFailure);
}

void DoInvalidate(DCacheTest* pTest, uint64_t addr)
{
    pTest->GetTop()->enable = 1;
    pTest->GetTop()->command = CMD_INVALIDATE;
    pTest->GetTop()->addr = addr;

    pTest->WaitDone();
    ASSERT_FALSE(pTest->GetTop()->storeConditionalFailure);

    pTest->ProcessCycle();

    pTest->GetTop()->enable = 0;
    pTest->GetTop()->command = 0;
    pTest->GetTop()->addr = 0;

    pTest->ProcessCycle();
}

// ----------------------------------------------------------------------------
// Test cases

TEST_F(DCacheTest, SameLine_LoadLoad)
{
    const uint64_t addr = 0x00000000'00000000ull;
    const uint64_t readValue = 0x12341234'56785678ull;

    DoLoad(this, false, addr, readValue);
    DoLoad(this, true, addr, readValue);
}

TEST_F(DCacheTest, SameLine_LoadStore)
{
    const uint64_t addr = 0x00000000'80000000ull;
    const uint64_t readValue = 0x11111111'11111111ull;
    const uint64_t writeValue = 0x33333333'33333333ull;
    const uint8_t writeMask = 0b00001111;
    const uint64_t memReadValue = readValue;
    const uint64_t memWriteValue = 0x11111111'33333333ull;

    DoLoad(this, false, addr, readValue);
    DoStore(this, true, addr, writeValue, writeMask, memReadValue, memWriteValue);
}

TEST_F(DCacheTest, SameLine_StoreLoad)
{
    const uint64_t addr = 0x00000000'12345678ull;
    const uint64_t writeValue = 0x33333333'33333333ull;
    const uint8_t writeMask = 0b00001111;
    const uint64_t memReadValue = 0x11111111'22222222ull;
    const uint64_t memWriteValue = 0x11111111'33333333ull;
    const uint64_t readValue = memWriteValue;

    DoStore(this, false, addr, writeValue, writeMask, memReadValue, memWriteValue);
    DoLoad(this, true, addr, readValue);
}

TEST_F(DCacheTest, SameLine_StoreStore)
{
    const uint64_t addr = 0x00000003'fffffff8ull;
    const uint64_t writeValue1 = 0x11111111'11111111ull;
    const uint64_t writeValue2 = 0x22222222'22222222ull;
    const uint8_t writeMask1 = 0b00110000;
    const uint8_t writeMask2 = 0b00010000;
    const uint64_t memReadValue = 0x00000000'00000000ull;
    const uint64_t memWriteValue1 = 0x00001111'00000000ull;
    const uint64_t memWriteValue2 = 0x00001122'00000000ull;

    DoStore(this, false, addr, writeValue1, writeMask1, memReadValue, memWriteValue1);
    DoStore(this, true, addr, writeValue2, writeMask2, memReadValue, memWriteValue2);
}

TEST_F(DCacheTest, SameIndex)
{
    const uint64_t addr1 = 0x00000000'10000000ull;
    const uint64_t addr2 = 0x00000000'20000000ull;
    const uint64_t readValue1 = 0xabababab'ababababull;
    const uint64_t readValue2 = 0xcdcdcdcd'cdcdcdcdull;

    DoLoad(this, false, addr1, readValue1);
    DoLoad(this, false, addr2, readValue2);
    DoLoad(this, false, addr1, readValue1);
}

TEST_F(DCacheTest, DifferentIndex)
{
    const uint64_t addr1 = 0x00000000'00000010ull;
    const uint64_t addr2 = 0x00000000'00000020ull;
    const uint64_t readValue1 = 0x5555aaaa'5555aaaaull;
    const uint64_t readValue2 = 0x66669999'66669999ull;

    DoLoad(this, false, addr1, readValue1);
    DoLoad(this, false, addr2, readValue2);
    DoLoad(this, true, addr1, readValue1);
}

TEST_F(DCacheTest, Invalidate)
{
    const uint64_t addr = 0x00000000'00000000ull;
    const uint64_t readValue = 0x12341234'56785678ull;

    DoLoad(this, false, addr, readValue);
    DoInvalidate(this, addr);
    DoLoad(this, false, addr, readValue);
}

TEST_F(DCacheTest, StoreConditional_Success_LoadReservedCacheHit)
{
    const uint64_t addr = 0x00000000'80000000ull;
    const uint64_t readValue = 0x00000000'00000000ull;
    const uint64_t writeValue = 0xffffffff'ffffffffull;
    const uint8_t writeMask = 0b11111111;
    const uint64_t memReadValue = readValue;
    const uint64_t memWriteValue = writeValue;

    DoLoad(this, false, addr, readValue);
    DoLoadReserved(this, true, addr, readValue);
    DoStoreConditional(this, true, addr, writeValue, writeMask, memReadValue, memWriteValue, false);
}

TEST_F(DCacheTest, StoreConditional_Success_LoadReservedCacheMiss)
{
    const uint64_t addr = 0x00000000'80000000ull;
    const uint64_t readValue = 0xffffffff'ffffffffull;
    const uint64_t writeValue = 0x00000000'00000000ull;
    const uint8_t writeMask = 0b11111111;
    const uint64_t memReadValue = readValue;
    const uint64_t memWriteValue = writeValue;

    DoLoadReserved(this, false, addr, readValue);
    DoStoreConditional(this, true, addr, writeValue, writeMask, memReadValue, memWriteValue, false);
}

TEST_F(DCacheTest, StoreConditional_FailureByNotLoaded)
{
    const uint64_t addr = 0x00000000'80000000ull;
    const uint64_t writeValue = 0xffffffff'ffffffffull;
    const uint8_t writeMask = 0b11111111;
    const uint64_t memReadValue = 0x00000000'00000000ull;
    const uint64_t memWriteValue = writeValue;

    DoStoreConditional(this, true, addr, writeValue, writeMask, memReadValue, memWriteValue, true);
}

TEST_F(DCacheTest, StoreConditional_FailureByNotReserved)
{
    const uint64_t addr = 0x00000000'80000000ull;
    const uint64_t readValue = 0xffffffff'ffffffffull;
    const uint64_t writeValue = 0x00000000'00000000ull;
    const uint8_t writeMask = 0b11111111;
    const uint64_t memReadValue = readValue;
    const uint64_t memWriteValue = writeValue;

    DoLoad(this, false, addr, readValue);
    DoStoreConditional(this, true, addr, writeValue, writeMask, memReadValue, memWriteValue, true);
}

TEST_F(DCacheTest, StoreConditional_FailureBySandwichedStore)
{
    const uint64_t addr = 0x00000000'80000000ull;
    const uint64_t readValue = 0xffffffff'ffffffffull;
    const uint64_t writeValue = 0x00000000'00000000ull;
    const uint8_t writeMask = 0b11111111;
    const uint64_t memReadValue = readValue;
    const uint64_t memWriteValue = writeValue;

    DoLoadReserved(this, false, addr, readValue);
    DoStore(this, true, addr, writeValue, writeMask, memReadValue, memWriteValue);
    DoStoreConditional(this, true, addr, writeValue, writeMask, memReadValue, memWriteValue, true);
}

TEST_F(DCacheTest, StoreConditional_FailureBySandwichedStoreConditional)
{
    const uint64_t addr = 0x00000000'80000000ull;
    const uint64_t readValue = 0xffffffff'ffffffffull;
    const uint64_t writeValue = 0x00000000'00000000ull;
    const uint8_t writeMask = 0b11111111;
    const uint64_t memReadValue = readValue;
    const uint64_t memWriteValue = writeValue;

    DoLoadReserved(this, false, addr, readValue);
    DoStoreConditional(this, true, addr, writeValue, writeMask, memReadValue, memWriteValue, false);
    DoStoreConditional(this, true, addr, writeValue, writeMask, memReadValue, memWriteValue, true);
}

TEST_F(DCacheTest, StoreConditional_FailureByCacheMiss)
{
    const uint64_t addr = 0x00000000'80000000ull;
    const uint64_t readValue = 0xffffffff'ffffffffull;
    const uint64_t writeValue = 0x00000000'00000000ull;
    const uint8_t writeMask = 0b11111111;
    const uint64_t memReadValue = readValue;
    const uint64_t memWriteValue = writeValue;

    DoLoadReserved(this, false, addr, readValue);
    DoInvalidate(this, addr);
    DoStoreConditional(this, true, addr, writeValue, writeMask, memReadValue, memWriteValue, true);
}

}}
