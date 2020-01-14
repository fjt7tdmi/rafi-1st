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

#include <rafi/emu.h>
#include <rafi/trace.h>

#include "VCore.h"

namespace rafi { namespace sim {

class System final : public trace::ILoggerTarget
{
public:
    explicit System(VCore* pCore, size_t ramSize);
    virtual ~System();

    void SetHostIoAddr(paddr_t hostIoAddr);
    void LoadFileToMemory(const char* path);
    void Reset();

    void ProcessPositiveEdge();
    void ProcessNegativeEdge();
    void UpdateSignal();

    bool IsOpRetired() const;

    // ILoggerTarget
    virtual uint32_t GetHostIoValue() const override;
    virtual uint64_t GetPc() const override;
    virtual size_t GetMemoryEventCount() const override;
    virtual bool IsOpEventExist() const override;
    virtual bool IsTrapEventExist() const override;
    virtual void CopyIntReg(trace::NodeIntReg32* pOut) const override;
    virtual void CopyIntReg(trace::NodeIntReg64* pOut) const override;
    virtual void CopyFpReg(trace::NodeFpReg* pOut) const override;
    virtual void CopyOpEvent(trace::NodeOpEvent* pOut) const override;
    virtual void CopyTrapEvent(trace::NodeTrapEvent* pOut) const override;
    virtual void CopyMemoryEvent(trace::NodeMemoryEvent* pOut, int index) const override;

private:
    static const paddr_t AddrRam = 0x80000000;

    paddr_t m_HostIoAddr;

    VCore* m_pCore;

    emu::Bus m_Bus;
    emu::Ram m_Ram;
};

}}
