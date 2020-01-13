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

#include <cstdlib>

#include <boost/program_options.hpp>

#include <rafi/common.h>

#include "CommandLineOption.h"

namespace po = boost::program_options;

namespace rafi { namespace sim {

CommandLineOption::CommandLineOption(int argc, char** argv)
{
    po::options_description desc("options");
    desc.add_options()
        ("cycle", po::value<int>(&m_Cycle)->default_value(0), "number of emulation cycles")
        ("dump-path", po::value<std::string>(), "path of dump file")
        ("enable-dump-int-reg", "output int register contents to dump file")
        ("help", "show help")
        ("host-io-addr", po::value<std::string>(), "host io address (hex)")
        ("load-path", po::value<std::string>(&m_LoadPath)->required(), "path of binary file which is loaded to memory")
        ("ram-size", po::value<size_t>(&m_RamSize)->default_value(DefaultRamSize), "ram size (byte)")
        ("vcd-path", po::value<std::string>(&m_VcdPath)->required(), "path of output vcd");

    po::variables_map variables;
    try
    {
        po::store(po::parse_command_line(argc, argv, desc), variables);
        po::notify(variables);
    }
    catch (const boost::program_options::error_with_option_name& e)
    {
        std::cout << e.what() << std::endl;
        std::cout << desc << std::endl;
        std::exit(1);
    }

    if (variables.count("help"))
    {
        std::cout << desc << std::endl;
        std::exit(0);
    }

    m_HostIoEnabled = variables.count("host-io-addr") > 0;

    if (variables.count("host-io-addr"))
    {
        m_HostIoAddress = strtoull(variables["host-io-addr"].as<std::string>().c_str(), 0, 16);
    }

    if (variables.count("dump-path"))
    {
        m_LoggerConfig.enabled = true;
        m_LoggerConfig.enableDumpIntReg = variables.count("enable-dump-int-reg") > 0;
        m_LoggerConfig.enableDumpFpReg = false;
        m_LoggerConfig.enableDumpHostIo = m_HostIoEnabled;
        m_LoggerConfig.path = variables["dump-path"].as<std::string>();
    }
    else
    {
        m_LoggerConfig.enabled = false;
    }
}

const trace::LoggerConfig& CommandLineOption::GetLoggerConfig() const
{
    return m_LoggerConfig;
}

std::string CommandLineOption::GetLoadPath() const
{
    return m_LoadPath;
}

std::string CommandLineOption::GetVcdPath() const
{
    return m_VcdPath;
}

int CommandLineOption::GetCycle() const
{
    return m_Cycle;
}

size_t CommandLineOption::GetRamSize() const
{
    return m_RamSize;
}

bool CommandLineOption::IsHostIoEnabled() const
{
    return m_HostIoEnabled;
}

}}
