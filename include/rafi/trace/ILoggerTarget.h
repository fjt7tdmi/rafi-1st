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

namespace rafi { namespace trace {

class ILoggerTarget
{
public:
    virtual ~ILoggerTarget(){};

    virtual uint32_t GetHostIoValue() const = 0;
    virtual vaddr_t GetPc() const = 0;

    virtual size_t GetMemoryAccessEventCount() const = 0;
    virtual bool IsOpEventExist() const = 0;
    virtual bool IsTrapEventExist() const = 0;

    virtual void CopyIntReg(trace::NodeIntReg32* pOut) const = 0;
    virtual void CopyIntReg(trace::NodeIntReg64* pOut) const = 0;
    virtual void CopyFpReg(void* pOut, size_t size) const = 0;
    virtual void CopyOpEvent(OpEvent* pOut) const = 0;
    virtual void CopyTrapEvent(TrapEvent* pOut) const = 0;
    virtual void CopyMemoryAccessEvent(MemoryAccessEvent* pOut, int index) const = 0;
};

}}
