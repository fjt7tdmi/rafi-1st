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

#include <iostream>
#include <boost/program_options.hpp>

#include "Option.h"

namespace po = boost::program_options;

Option::Option(int argc, char** argv)
{
    po::options_description desc("options");
    desc.add_options()
        ("cycle", po::value<int>(&m_Cycle)->default_value(0), "number of emulation cycles")
        ("dump-path", po::value<std::string>(), "path of dump file")
        ("load-path", po::value<std::string>(), "path of binary file that is loaded to memory")
        ("vcd-path", po::value<std::string>(), "path of vcd file")
        ("stop-by-host-io", "stop emulation when host io value is changed")
        ("help", "show help");

    po::variables_map options;
    try
    {
        po::store(po::parse_command_line(argc, argv, desc), options);
    }
    catch (const boost::program_options::error_with_option_name& e)
    {
        std::cerr << e.what() << std::endl;
        std::exit(1);
    }
    po::notify(options);

    if (options.count("help") || options.count("dump-path") == 0 || options.count("load-path") == 0 || options.count("vcd-path") == 0)
    {
        std::cout << desc << std::endl;
        exit(0);
    }

    if (options.count("dump-path"))
    {
        m_DumpPath = options["dump-path"].as<std::string>();
    }

    if (options.count("load-path"))
    {
        m_LoadPath = options["load-path"].as<std::string>();
    }

    if (options.count("vcd-path"))
    {
        m_VcdPath = options["vcd-path"].as<std::string>();
    }

    m_IsStopByHostIo = options.count("stop-by-host-io") != 0;
}

int Option::GetCycle() const
{
    return m_Cycle;
}

const char* Option::GetDumpPath() const
{
    return m_DumpPath.c_str();
}

const char* Option::GetLoadPath() const
{
    return m_LoadPath.c_str();
}

const char* Option::GetVcdPath() const
{
    return m_VcdPath.c_str();
}

bool Option::IsStopByHostIo() const
{
    return m_IsStopByHostIo;
}
