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

#include <cstdio>

#include <rafi/trace/ILoggerTarget.h>
#include <rafi/trace/LoggerConfig.h>

namespace rafi { namespace trace {

class LoggerImpl;

class Logger final
{
public:
    Logger(XLEN xlen, const trace::LoggerConfig& config, const trace::ILoggerTarget* pSystem);
    ~Logger();

    void BeginCycle(int cycle, uint64_t pc);
    void RecordState();
    void RecordEvent();
    void EndCycle();

private:
    LoggerImpl* m_pImpl;
};

}}
