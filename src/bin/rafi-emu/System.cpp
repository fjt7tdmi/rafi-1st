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

#include <rafi/emu.h>

#include "System.h"

namespace rafi { namespace emu {

System::System(XLEN xlen, vaddr_t pc, size_t ramSize)
    : m_EventList()
    , m_Bus()
    , m_Ram(ramSize)
    , m_Clint()
    , m_Plic()
    , m_Uart()
    , m_Timer()
    , m_ExternalInterruptSource(&m_Plic)
    , m_TimerInterruptSource(&m_Clint)
    , m_Processor(xlen, &m_Bus, &m_EventList, pc)
{
    m_Bus.RegisterMemory(&m_Ram, AddrRam, m_Ram.GetCapacity());
    m_Bus.RegisterMemory(&m_Rom, AddrRom, m_Rom.GetCapacity());

    // E31 compatible IOs
    m_Bus.RegisterIo(&m_Clint, AddrClint, m_Clint.GetSize());
    m_Bus.RegisterIo(&m_Plic, AddrPlic, m_Plic.GetSize());
    m_Bus.RegisterIo(&m_Uart16550, AddrUart16550, m_Uart16550.GetSize());
    m_Bus.RegisterIo(&m_VirtIo1, AddrVirtIo1, m_VirtIo1.GetSize());
    m_Bus.RegisterIo(&m_VirtIo2, AddrVirtIo2, m_VirtIo2.GetSize());
    m_Bus.RegisterIo(&m_VirtIo3, AddrVirtIo3, m_VirtIo3.GetSize());
    m_Bus.RegisterIo(&m_VirtIo4, AddrVirtIo4, m_VirtIo4.GetSize());
    m_Bus.RegisterIo(&m_VirtIo5, AddrVirtIo5, m_VirtIo5.GetSize());
    m_Bus.RegisterIo(&m_VirtIo6, AddrVirtIo6, m_VirtIo6.GetSize());
    m_Bus.RegisterIo(&m_VirtIo7, AddrVirtIo7, m_VirtIo7.GetSize());
    m_Bus.RegisterIo(&m_VirtIo8, AddrVirtIo8, m_VirtIo8.GetSize());

    // IOs for zephyr
    m_Bus.RegisterIo(&m_Uart, AddrUart, m_Uart.GetSize());
    m_Bus.RegisterIo(&m_Timer, AddrTimer, m_Timer.GetSize());

    m_Processor.RegisterExternalInterruptSource(&m_ExternalInterruptSource);
    m_Processor.RegisterTimerInterruptSource(&m_TimerInterruptSource);

    m_Clint.RegisterProcessor(&m_Processor);
}

System::~System()
{    
}

void System::LoadFileToMemory(const char* path, paddr_t address)
{
    m_Bus.LoadFileToMemory(path, address);
}

void System::SetDtbAddress(vaddr_t address)
{
    //  11 (a1) holds dtb address
    m_Processor.SetIntReg(11, address);
}

void System::SetHostIoAddress(vaddr_t address)
{
    m_HostIoAddress = address;
}

void System::ProcessCycle()
{
    m_EventList.clear();

    m_Clint.ProcessCycle();
    m_Uart16550.ProcessCycle();
    m_Uart.ProcessCycle();
    m_Timer.ProcessCycle();

    m_Processor.ProcessCycle();
}

bool System::IsValidMemory(paddr_t addr, size_t size) const
{
    return m_Bus.IsValidAddress(addr, size);
}

void System::ReadMemory(void* pOutBuffer, size_t bufferSize, paddr_t addr)
{
    return m_Bus.Read(pOutBuffer, bufferSize, addr);
}

void System::WriteMemory(const void* pBuffer, size_t bufferSize, paddr_t addr)
{
    return m_Bus.Write(pBuffer, bufferSize, addr);
}

uint32_t System::GetHostIoValue() const
{
    uint32_t value;
    m_Ram.Read(&value, sizeof(value), m_HostIoAddress - AddrRam);

    return value;
}

vaddr_t System::GetPc() const
{
    return m_Processor.GetPc();
}

void System::CopyIntReg(trace::NodeIntReg32* pOut) const
{
    m_Processor.CopyIntReg(pOut);
}

void System::CopyIntReg(trace::NodeIntReg64* pOut) const
{
    m_Processor.CopyIntReg(pOut);
}

void System::CopyFpReg(trace::NodeFpReg* pOut) const
{
    m_Processor.CopyFpReg(pOut);
}

const trace::EventList& System::GetEventList() const
{
    return m_EventList;
}

void System::PrintStatus() const
{
    return m_Processor.PrintStatus();
}

}}
