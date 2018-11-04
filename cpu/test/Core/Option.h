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

#include <rvtrace/writer.h>

class Option final
{
public:
    Option(int argc, char** argv);

    const char* GetDumpPath() const;
    const char* GetRamPath() const;
    const char* GetRomPath() const;
    const char* GetVcdPath() const;

    int GetCycle() const;

    bool IsRamPathValid() const;
    bool IsRomPathValid() const;
    bool IsStopByHostIo() const;

private:
    std::string m_DumpPath;
    std::string m_RamPath;
    std::string m_RomPath;
    std::string m_VcdPath;

    int m_Cycle {0};

    bool m_RamPathValid {false};
    bool m_RomPathValid {false};
    bool m_StopByHostIo {false};
};
