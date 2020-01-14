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

#include <string>

#include <rafi/emu.h>

namespace rafi { namespace sim {

class CommandLineOption
{
public:
    CommandLineOption(int argc, char** argv);

    const trace::LoggerConfig& GetLoggerConfig() const;

    std::string GetLoadPath() const;
    std::string GetVcdPath() const;

    size_t GetRamSize() const;
    int GetCycle() const;

    uint64_t GetHostIoAddr() const;
    bool IsHostIoEnabled() const;

private:
    static const int DefaultRamSize = 64 * 1024;

    trace::LoggerConfig m_LoggerConfig;
    std::string m_LoadPath;
    std::string m_VcdPath;

    size_t m_RamSize {0};
    int m_Cycle {0};

    uint64_t m_HostIoAddr {0};
    bool m_HostIoEnabled {false};
};

}}
