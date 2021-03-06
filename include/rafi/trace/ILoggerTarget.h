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
#include <rafi/trace/CycleTypes.h>
#include <rafi/trace/EventTypes.h>

namespace rafi { namespace trace {

class ILoggerTarget
{
public:
    virtual ~ILoggerTarget(){};

    virtual uint32_t GetHostIoValue() const = 0;
    virtual uint64_t GetPc() const = 0;

    virtual void CopyIntReg(NodeIntReg32* pOut) const = 0;
    virtual void CopyIntReg(NodeIntReg64* pOut) const = 0;
    virtual void CopyFpReg(NodeFpReg* pOut) const = 0;

    virtual const EventList& GetEventList() const = 0;
};

}}
