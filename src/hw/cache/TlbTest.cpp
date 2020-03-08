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

#include "VTlb.h"
#include <rafi/test.h>

namespace rafi { namespace test {

namespace {

const int MaxCycle = 50;

// Command
const uint32_t CMD_MARK_DIRTY = 0x1;
const uint32_t CMD_INVALIDATE = 0x2;
const uint32_t CMD_TRANSLATE  = 0x3;

// AccessType
const uint32_t ACCESS_TYPE_INSN  = static_cast<uint32_t>(MemoryAccessType::Instruction);
const uint32_t ACCESS_TYPE_LOAD  = static_cast<uint32_t>(MemoryAccessType::Load);
const uint32_t ACCESS_TYPE_STORE = static_cast<uint32_t>(MemoryAccessType::Store);

// Priv
const uint32_t PRIV_M = static_cast<uint32_t>(PrivilegeLevel::Machine);
const uint32_t PRIV_S = static_cast<uint32_t>(PrivilegeLevel::Supervisor);
const uint32_t PRIV_U = static_cast<uint32_t>(PrivilegeLevel::User);

// Address
const uint64_t PADDR_PAGE_TABLE_L1 = 0x80004000;
const uint64_t PADDR_PAGE_TABLE_L2 = 0x80005000;

}

// ----------------------------------------------------------------------------
// Test fixture

class TlbTest : public ModuleTest<VTlb>
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

protected:
    virtual void SetUpModule() override
    {
        GetTop()->memReadDone = false;
        GetTop()->memWriteDone = false;
        GetTop()->memReadValue = 0;

        GetTop()->enable = false;
        GetTop()->command = 0;
        GetTop()->vaddr = 0;
        GetTop()->accessType = 0;

        GetTop()->satp = 0;
        GetTop()->status = 0;
        GetTop()->priv = 0;

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
// Common utilities

uint32_t GetVPN1(uint32_t vaddr)
{
    return (vaddr >> 22) & 0x03ff;
}

uint32_t GetVPN0(uint32_t vaddr)
{
    return (vaddr >> 12) & 0x03ff;
}

uint32_t GetPPN1(uint64_t paddr)
{
    return (paddr >> 22) & 0x0fff;
}

uint32_t GetPPN0(uint64_t paddr)
{
    return (paddr >> 12) & 0x03ff;
}

uint32_t MakeSatp(AddressTranslationMode mode, uint32_t asid, uint64_t rootPageTableAddr)
{
    satp_t satp;

    satp.SetMember<satp_t::MODE_RV32>(static_cast<uint32_t>(mode));
    satp.SetMember<satp_t::ASID_RV32>(asid);
    satp.SetMember<satp_t::PPN_RV32>(rootPageTableAddr >> 12);

    return static_cast<uint32_t>(satp.GetValue());
}

uint32_t MakeStatus(bool sum, bool mxr)
{
    xstatus_t status;

    status.SetMember<xstatus_t::SUM>(sum);
    status.SetMember<xstatus_t::MXR>(mxr);

    return static_cast<uint32_t>(status.GetValue());
}

// ----------------------------------------------------------------------------
// Assertion utilities

void AssertTlbState_Invalidate(TlbTest* pTest, uint32_t vaddr, uint64_t paddr, bool dirty)
{
    PageTableEntrySv32 expectedEntry(0);
    {
        expectedEntry.SetMember<PageTableEntrySv32::PPN1>(GetPPN1(paddr));
        expectedEntry.SetMember<PageTableEntrySv32::PPN0>(GetPPN0(paddr));
        expectedEntry.SetMember<PageTableEntrySv32::D>(dirty ? 1 : 0);
        expectedEntry.SetMember<PageTableEntrySv32::A>(1);
        expectedEntry.SetMember<PageTableEntrySv32::X>(1);
        expectedEntry.SetMember<PageTableEntrySv32::W>(1);
        expectedEntry.SetMember<PageTableEntrySv32::R>(1);
        expectedEntry.SetMember<PageTableEntrySv32::V>(1);
    }

    ASSERT_FALSE(pTest->GetTop()->done);
    ASSERT_FALSE(pTest->GetTop()->memReadEnable);
    ASSERT_TRUE(pTest->GetTop()->memWriteEnable);
    ASSERT_EQ(PADDR_PAGE_TABLE_L1 + GetVPN1(vaddr) * 4, pTest->GetTop()->memAddr);
    ASSERT_EQ(expectedEntry.GetValue(), pTest->GetTop()->memWriteValue);
}

void AssertTlbState_PageTableRead(TlbTest* pTest, uint64_t pageTableEntryAddr)
{
    ASSERT_FALSE(pTest->GetTop()->done);
    ASSERT_FALSE(pTest->GetTop()->memWriteEnable);
    ASSERT_TRUE(pTest->GetTop()->memReadEnable);
    ASSERT_EQ(pageTableEntryAddr, pTest->GetTop()->memAddr);
}

void AssertTlbState_PageTableDecode(TlbTest* pTest)
{
    ASSERT_FALSE(pTest->GetTop()->done);
    ASSERT_FALSE(pTest->GetTop()->memWriteEnable);
    ASSERT_FALSE(pTest->GetTop()->memReadEnable);
}

void AssertTlbState_Done(TlbTest* pTest, bool fault, uint64_t paddr)
{
    ASSERT_TRUE(pTest->GetTop()->done);
    if (fault)
    {
        ASSERT_TRUE(pTest->GetTop()->fault);
    }
    else
    {
        ASSERT_FALSE(pTest->GetTop()->fault);
        ASSERT_EQ(paddr, pTest->GetTop()->paddr);
    }
}

// ----------------------------------------------------------------------------
// Test sequence utilities

// Preapration for some test cases
void DoFirstAccessForPrepare(TlbTest* pTest, uint32_t vaddr, uint64_t paddr)
{
    pTest->GetTop()->enable = true;
    pTest->GetTop()->command = CMD_TRANSLATE;
    pTest->GetTop()->vaddr = vaddr;
    pTest->GetTop()->accessType = ACCESS_TYPE_INSN;

    pTest->ProcessCycle();

    // TLB State: PageTableRead1
    AssertTlbState_PageTableRead(pTest, PADDR_PAGE_TABLE_L1 + GetVPN1(vaddr) * 4);

    PageTableEntrySv32 entryL1(0);
    {
        entryL1.SetMember<PageTableEntrySv32::PPN1>(GetPPN1(paddr));
        entryL1.SetMember<PageTableEntrySv32::PPN0>(GetPPN0(paddr));
        entryL1.SetMember<PageTableEntrySv32::X>(1);
        entryL1.SetMember<PageTableEntrySv32::W>(1);
        entryL1.SetMember<PageTableEntrySv32::R>(1);
        entryL1.SetMember<PageTableEntrySv32::V>(1);
    }

    pTest->GetTop()->memReadValue = entryL1.GetValue();
    pTest->GetTop()->memReadDone = true;

    pTest->ProcessCycle();

    // TLB State: PageTableDecode1
    AssertTlbState_PageTableDecode(pTest);

    pTest->GetTop()->memReadValue = 0;
    pTest->GetTop()->memReadDone = false;

    pTest->ProcessCycle();

    // TLB State: Done
    AssertTlbState_Done(pTest, false, paddr);

    pTest->GetTop()->enable = false;
    pTest->GetTop()->command = 0;
    pTest->GetTop()->vaddr = 0;
    pTest->GetTop()->accessType = 0;

    pTest->ProcessCycle();
}

void DoFaultTest(TlbTest* pTest, bool expectedFault, MemoryAccessType accessType, bool valid, bool readable, bool writable, bool executable, bool user)
{
    const uint32_t vaddr = 0x0;
    const uint64_t paddr = 0x80000000;

    pTest->GetTop()->enable = true;
    pTest->GetTop()->command = CMD_TRANSLATE;
    pTest->GetTop()->vaddr = vaddr;
    pTest->GetTop()->accessType = static_cast<uint32_t>(accessType);

    pTest->ProcessCycle();

    // TLB State: PageTableRead1
    AssertTlbState_PageTableRead(pTest, PADDR_PAGE_TABLE_L1 + GetVPN1(vaddr) * 4);

    PageTableEntrySv32 entryL1(0);
    {
        entryL1.SetMember<PageTableEntrySv32::PPN1>(GetPPN1(paddr));
        entryL1.SetMember<PageTableEntrySv32::PPN0>(GetPPN0(paddr));
        entryL1.SetMember<PageTableEntrySv32::U>(user ? 1 : 0);
        entryL1.SetMember<PageTableEntrySv32::X>(executable ? 1 : 0);
        entryL1.SetMember<PageTableEntrySv32::W>(writable ? 1 : 0);
        entryL1.SetMember<PageTableEntrySv32::R>(readable ? 1 : 0);
        entryL1.SetMember<PageTableEntrySv32::V>(valid ? 1 : 0);
    }

    pTest->GetTop()->memReadValue = entryL1.GetValue();
    pTest->GetTop()->memReadDone = true;

    pTest->ProcessCycle();

    // TLB State: PageTableDecode1
    AssertTlbState_PageTableDecode(pTest);

    pTest->GetTop()->memReadValue = 0;
    pTest->GetTop()->memReadDone = false;

    pTest->ProcessCycle();

    // TLB State: Done
    AssertTlbState_Done(pTest, expectedFault, paddr);

    pTest->GetTop()->enable = false;
    pTest->GetTop()->command = 0;
    pTest->GetTop()->vaddr = 0;
    pTest->GetTop()->accessType = 0;

    pTest->ProcessCycle();

    // Access cached TLB entry
    pTest->GetTop()->enable = true;
    pTest->GetTop()->command = CMD_TRANSLATE;
    pTest->GetTop()->vaddr = vaddr;
    pTest->GetTop()->accessType = static_cast<uint32_t>(accessType);

    pTest->ProcessCycle();

    // TLB State: Done
    AssertTlbState_Done(pTest, expectedFault, paddr);
}

// ----------------------------------------------------------------------------
// Test cases

TEST_F(TlbTest, NoTranslation_Bare)
{
    const uint32_t addr = 0x12345678;

    GetTop()->enable = true;
    GetTop()->command = CMD_TRANSLATE;
    GetTop()->vaddr = addr;
    GetTop()->accessType = ACCESS_TYPE_INSN;
    GetTop()->satp = MakeSatp(AddressTranslationMode::Bare, 0, 0);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    ProcessCycle();

    // TLB State: Done
    AssertTlbState_Done(this, false, addr);
}

TEST_F(TlbTest, NoTranslation_Machine)
{
    const uint32_t addr = 0x12345678;

    GetTop()->enable = true;
    GetTop()->command = CMD_TRANSLATE;
    GetTop()->vaddr = addr;
    GetTop()->accessType = ACCESS_TYPE_INSN;
    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, 0);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_M;

    ProcessCycle();

    // TLB State: Done
    AssertTlbState_Done(this, false, addr);
}

TEST_F(TlbTest, PageTableWalk_Level1)
{
    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    DoFirstAccessForPrepare(this, 0x0, 0x80000000);
}

TEST_F(TlbTest, PageTableWalk_Level2)
{
    const uint32_t vaddr = 0xffc01000;
    const uint32_t paddr = 0x80001000;

    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    GetTop()->enable = true;
    GetTop()->command = CMD_TRANSLATE;
    GetTop()->vaddr = vaddr;
    GetTop()->accessType = ACCESS_TYPE_INSN;

    ProcessCycle();

    // TLB State: PageTableRead1
    AssertTlbState_PageTableRead(this, PADDR_PAGE_TABLE_L1 + GetVPN1(vaddr) * 4);

    PageTableEntrySv32 entryL1(0);
    {
        entryL1.SetMember<PageTableEntrySv32::PPN1>(GetPPN1(PADDR_PAGE_TABLE_L2));
        entryL1.SetMember<PageTableEntrySv32::PPN0>(GetPPN0(PADDR_PAGE_TABLE_L2));
        entryL1.SetMember<PageTableEntrySv32::V>(1);
    }

    GetTop()->memReadValue = entryL1.GetValue();
    GetTop()->memReadDone = true;

    ProcessCycle();

    // TLB State: PageTableDecode1
    AssertTlbState_PageTableDecode(this);

    GetTop()->memReadValue = 0;
    GetTop()->memReadDone = false;

    ProcessCycle();

    // TLB State: PageTableRead0
    AssertTlbState_PageTableRead(this, PADDR_PAGE_TABLE_L2 + GetVPN0(vaddr) * 4);

    PageTableEntrySv32 entryL2(0);
    {
        entryL2.SetMember<PageTableEntrySv32::PPN1>(GetPPN1(paddr));
        entryL2.SetMember<PageTableEntrySv32::PPN0>(GetPPN0(paddr));
        entryL2.SetMember<PageTableEntrySv32::W>(1);
        entryL2.SetMember<PageTableEntrySv32::X>(1);
        entryL2.SetMember<PageTableEntrySv32::R>(1);
        entryL2.SetMember<PageTableEntrySv32::V>(1);
    }

    GetTop()->memReadValue = entryL2.GetValue();
    GetTop()->memReadDone = true;

    ProcessCycle();

    // TLB State: PageTableDecode0
    AssertTlbState_PageTableDecode(this);

    GetTop()->memReadValue = 0;
    GetTop()->memReadDone = false;

    ProcessCycle();

    // TLB State: Done
    AssertTlbState_Done(this, false, paddr);
}

TEST_F(TlbTest, CacheHit)
{
    const uint32_t vaddr = 0x12345000;
    const uint32_t paddr = 0x54321000;
    const uint32_t offset = 0xabc;    

    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    DoFirstAccessForPrepare(this, vaddr, paddr);

    ProcessCycle();

    GetTop()->enable = true;
    GetTop()->command = CMD_TRANSLATE;
    GetTop()->vaddr = vaddr + offset;
    GetTop()->accessType = ACCESS_TYPE_LOAD;

    ProcessCycle();

    // TLB State: Default
    AssertTlbState_Done(this, false, paddr + offset);
}

TEST_F(TlbTest, Invalidate)
{
    const uint32_t vaddr = 0x0;
    const uint32_t paddr = 0x80000000;

    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    DoFirstAccessForPrepare(this, vaddr, paddr);

    GetTop()->enable = true;
    GetTop()->command = CMD_INVALIDATE;
    GetTop()->vaddr = vaddr;
    GetTop()->accessType = ACCESS_TYPE_INSN;

    ProcessCycle();

    // TLB State: Invalidate
    AssertTlbState_Invalidate(this, vaddr, paddr, false);

    GetTop()->memWriteDone = true;

    ProcessCycle();

    // TLB State: Done
    ASSERT_TRUE(GetTop()->done);
    ASSERT_FALSE(GetTop()->fault);
}

TEST_F(TlbTest, Replace)
{
    const uint32_t vaddr = 0x1000;
    const uint32_t paddr = 0x80001000;
    const uint32_t vaddrForPrepare = 0xffc00000;
    const uint32_t paddrForPrepare = 0x80000000;

    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    DoFirstAccessForPrepare(this, vaddrForPrepare, paddrForPrepare);

    // 2nd Translation
    GetTop()->enable = true;
    GetTop()->command = CMD_TRANSLATE;
    GetTop()->vaddr = vaddr;
    GetTop()->accessType = ACCESS_TYPE_INSN;

    ProcessCycle();

    // TLB State: Invalidate
    AssertTlbState_Invalidate(this, vaddrForPrepare, paddrForPrepare, false);

    GetTop()->memWriteDone = true;

    ProcessCycle();

    // TLB State: PageTableRead1
    AssertTlbState_PageTableRead(this, PADDR_PAGE_TABLE_L1 + GetVPN1(vaddr) * 4);

    PageTableEntrySv32 entry(0);
    {
        entry.SetMember<PageTableEntrySv32::PPN1>(GetPPN1(paddr));
        entry.SetMember<PageTableEntrySv32::PPN0>(GetPPN0(paddr));
        entry.SetMember<PageTableEntrySv32::X>(1);
        entry.SetMember<PageTableEntrySv32::W>(1);
        entry.SetMember<PageTableEntrySv32::R>(1);
        entry.SetMember<PageTableEntrySv32::V>(1);
    }

    GetTop()->memReadValue = entry.GetValue();
    GetTop()->memReadDone = true;

    ProcessCycle();

    // TLB State: PageTableDecode1
    AssertTlbState_PageTableDecode(this);

    GetTop()->memReadValue = 0;
    GetTop()->memReadDone = false;

    ProcessCycle();

    // TLB State: Done
    AssertTlbState_Done(this, false, paddr);
}

TEST_F(TlbTest, Dirty)
{
    const uint32_t vaddr = 0x0;
    const uint32_t paddr = 0x80000000;

    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    DoFirstAccessForPrepare(this, 0x0, 0x80000000);

    // Mark Dirty
    GetTop()->enable = true;
    GetTop()->command = CMD_MARK_DIRTY;

    ProcessCycle();

    GetTop()->enable = false;
    GetTop()->command = 0;

    ProcessCycle();

    // 2nd Translation
    GetTop()->enable = true;
    GetTop()->command = CMD_INVALIDATE;

    ProcessCycle();

    // TLB State: Invalidate
    AssertTlbState_Invalidate(this, vaddr, paddr, true);
}

TEST_F(TlbTest, FaultByValidFlag)
{
    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    DoFaultTest(this, true, MemoryAccessType::Load, false, false, false, false, false);
}

TEST_F(TlbTest, FaultByReadableFlag)
{
    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    DoFaultTest(this, true, MemoryAccessType::Load, true, false, true, true, false);
}

TEST_F(TlbTest, FaultByWritableFlag)
{
    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    DoFaultTest(this, true, MemoryAccessType::Store, true, true, false, true, false);
}

TEST_F(TlbTest, FaultByExecutableFlag)
{
    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    DoFaultTest(this, true, MemoryAccessType::Instruction, true, true, true, false, false);
}

TEST_F(TlbTest, FaultByPrivU)
{
    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_U;

    DoFaultTest(this, true, MemoryAccessType::Load, true, true, true, true, false);
}

TEST_F(TlbTest, FaultByPrivS)
{
    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, false);
    GetTop()->priv = PRIV_S;

    DoFaultTest(this, true, MemoryAccessType::Load, true, true, true, true, true);
}

TEST_F(TlbTest, AvoidFaultBySUM)
{
    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(true, false);
    GetTop()->priv = PRIV_S;

    DoFaultTest(this, false, MemoryAccessType::Load, true, true, true, true, true);
}

TEST_F(TlbTest, AvoidFaultByMXR)
{
    GetTop()->satp = MakeSatp(AddressTranslationMode::Sv32, 0, PADDR_PAGE_TABLE_L1);
    GetTop()->status = MakeStatus(false, true);
    GetTop()->priv = PRIV_S;

    DoFaultTest(this, false, MemoryAccessType::Load, true, false, false, true, false);
}

}}
