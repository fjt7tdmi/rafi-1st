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

#include <rafi/common.h>
#include <rafi/emu.h>

#include "Csr.h"
#include "Executor.h"
#include "FpRegFile.h"
#include "InterruptController.h"
#include "IntRegFile.h"
#include "MemoryAccessUnit.h"
#include "Trap.h"
#include "TrapProcessor.h"

namespace rafi { namespace emu { namespace cpu {

class Processor
{
public:
    // Setup
    Processor(XLEN xlen, Bus* pBus, trace::EventList* pEventList, vaddr_t initialPc);

    void SetIntReg(int regId, uint32_t regValue);

    // Interrupt source
    void RegisterExternalInterruptSource(IInterruptSource* pInterruptSource);
    void RegisterTimerInterruptSource(IInterruptSource* pInterruptSource);

    // for clint and plic
    xip_t ReadInterruptPending() const;
    void WriteInterruptPending(const xip_t& value);

    uint64_t ReadTime() const;
    void WriteTime(uint64_t value);

    // Process
    void ProcessCycle();

    // for Dump
    vaddr_t GetPc() const;

    void CopyIntReg(trace::NodeIntReg32* pOut) const;
    void CopyIntReg(trace::NodeIntReg64* pOut) const;
    void CopyFpReg(trace::NodeFpReg* pOut) const;

    void PrintStatus() const;

private:
    std::optional<Trap> Fetch(uint32_t* pOutInsn, vaddr_t pc);

    const vaddr_t InvalidValue = 0xffffffffffffffff;

    trace::EventList* m_pEventList;

    AtomicManager m_AtomicManager;
    Csr m_Csr;
    InterruptController m_InterruptController;
    TrapProcessor m_TrapProcessor;

    Decoder m_Decoder;
    FpRegFile m_FpRegFile;
    IntRegFile m_IntRegFile;
    MemoryAccessUnit m_MemAccessUnit;

    Executor m_Executor;

    uint32_t m_OpCount { 0 };
};

}}}
