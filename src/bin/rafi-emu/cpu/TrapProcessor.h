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

#include <cstring>

#include <rafi/emu.h>

#include "Csr.h"
#include "Trap.h"

namespace rafi { namespace emu { namespace cpu {

class TrapProcessor
{
public:
    explicit TrapProcessor(XLEN xlen, Csr* pCsr, trace::EventList* pEventList)
        : m_XLEN(xlen)
        , m_pCsr(pCsr)
        , m_pEventList(pEventList)
	{
	}

    void ProcessException(const Trap& trap);
    void ProcessInterrupt(InterruptType type, vaddr_t pc);
    void ProcessTrapReturn(PrivilegeLevel level);

private:
    void ProcessTrapEnter(bool isInterrupt, uint32_t exceptionCode, uint64_t trapValue, vaddr_t pc, PrivilegeLevel nextPriv);

    XLEN m_XLEN;
    Csr* m_pCsr;
    trace::EventList* m_pEventList;
};

}}}
