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

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include <rafi/trace.h>

#include "CommandLineOption.h"
#include "CycleFilter.h"

namespace rafi { namespace dump {

XLEN GetXLEN(const std::string& path)
{
    if (path.find("rv32") != path.npos)
    {
        return XLEN::XLEN32;
    }
    else if (path.find("rv64") != path.npos)
    {
        return XLEN::XLEN64;
    }
    else
    {
        std::cout << "Failed to determine XLEN from path." << std::endl;
        std::exit(1);
    }
}

void PrintTrace(const CommandLineOption& option, IFilter* filter)
{
    auto reader = rafi::trace::MakeTraceReader(option.GetPath());
    auto printer = rafi::trace::MakeTracePrinter(option.GetPrinterType(), GetXLEN(option.GetPath()));

    const int begin = option.GetCycleBegin();
    const int end = std::min(option.GetCycleBegin() + option.GetCycleCount(), option.GetCycleEnd());

    if (begin > 0)
    {
        reader->Next(static_cast<uint32_t>(begin));
    }

    for (int i = begin; i < end; i++)
    {
        if (reader->IsEnd())
        {
            return;
        }

        if (i >= begin && filter->Apply(reader->GetCycle()))
        {
            printer->Print(reader->GetCycle());
        }

        reader->Next();
    }
}

}}

int main(int argc, char** argv)
{
    rafi::dump::CommandLineOption option(argc, argv);

    try
    {
        auto filter = rafi::dump::MakeFilter(option.GetFilterDescription());

        PrintTrace(option, filter.get());
    }
    catch (rafi::trace::TraceException e)
    {
        e.PrintMessage();
        std::exit(1);
    }
    catch (rafi::FileOpenFailureException e)
    {
        e.PrintMessage();
        std::exit(1);
    }

    return 0;
}
