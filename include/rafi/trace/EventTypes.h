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

#include <variant>
#include <vector>

#include <rafi/common.h>

namespace rafi { namespace trace {

struct OpEvent
{
    uint32_t insn;
    PrivilegeLevel priv;
};

struct TrapEvent
{
    TrapType trapType;
    PrivilegeLevel from;
    PrivilegeLevel to;
    uint32_t cause;
    uint64_t trapValue;
};

struct MemoryEvent
{
    MemoryAccessType accessType;
    uint32_t size;
    uint64_t value;
    uint64_t vaddr;
    uint64_t paddr;
};

using Event = std::variant<OpEvent, TrapEvent, MemoryEvent>;
using EventList = std::vector<Event>;

}}
