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

#include <memory>
#include <string>
#include <sstream>

#include <rafi/trace.h>

namespace rafi { namespace trace {

class LoggerImpl final
{
public:
    LoggerImpl(XLEN xlen, const trace::LoggerConfig& config, const trace::ILoggerTarget* pLoggerTarget)
        : m_XLEN(xlen)
        , m_Config(config)
        , m_pLoggerTarget(pLoggerTarget)
    {
        if (m_Config.enabled)
        {
            m_pTraceWriter = new TraceIndexWriter(m_Config.path.c_str());
        }
    }

    ~LoggerImpl()
    {
        if (m_pTraceWriter != nullptr)
        {
            delete m_pTraceWriter;
        }
    }

    void BeginCycle(int cycle, uint64_t pc)
    {
        if (!m_Config.enabled)
        {
            return;
        }

        m_pCurrentCycle = new BinaryCycleBuilder(cycle, m_XLEN, pc);
    }

    void RecordState()
    {
        if (!m_Config.enabled)
        {
            return;
        }

        if (m_Config.enableDumpIntReg)
        {
            if (m_XLEN == XLEN::XLEN32)
            {
                NodeIntReg32 node;
                m_pLoggerTarget->CopyIntReg(&node);
                m_pCurrentCycle->Add(node);
            }
            else if (m_XLEN == XLEN::XLEN64)
            {
                NodeIntReg64 node;
                m_pLoggerTarget->CopyIntReg(&node);
                m_pCurrentCycle->Add(node);
            }
            else
            {
                RAFI_NOT_IMPLEMENTED;
            }
        }

        if (m_Config.enableDumpFpReg)
        {
            NodeFpReg node;
            m_pLoggerTarget->CopyFpReg(&node);
            m_pCurrentCycle->Add(node);
        }

        if (m_Config.enableDumpHostIo)
        {
            NodeIo node = { m_pLoggerTarget->GetHostIoValue(), 0 };
            m_pCurrentCycle->Add(node);
        }        
    }

    void RecordEvent()
    {
        if (!m_Config.enabled)
        {
            return;
        }

        for (const auto event: m_pLoggerTarget->GetEventList())
        {
            if (std::holds_alternative<trace::OpEvent>(event))
            {
                const auto opEvent = std::get<trace::OpEvent>(event);

                m_pCurrentCycle->Add(NodeOpEvent {
                    opEvent.insn,
                    opEvent.priv,
                });
            }
            if (std::holds_alternative<trace::TrapEvent>(event))
            {
                const auto trapEvent = std::get<trace::TrapEvent>(event);

                m_pCurrentCycle->Add(NodeTrapEvent {
                    trapEvent.trapType,
                    trapEvent.from,
                    trapEvent.to,
                    trapEvent.cause,
                    trapEvent.trapValue,
                });
            }
            if (std::holds_alternative<trace::MemoryEvent>(event))
            {
                const auto memoryEvent = std::get<trace::MemoryEvent>(event);

                m_pCurrentCycle->Add(NodeMemoryEvent {
                    memoryEvent.accessType,
                    memoryEvent.size,
                    memoryEvent.value,
                    memoryEvent.vaddr,
                    memoryEvent.paddr,
                });
            }
        }
    }

    void EndCycle()
    {
        if (!m_Config.enabled)
        {
            return;
        }

        m_pCurrentCycle->Break();

        m_pTraceWriter->Write(m_pCurrentCycle->GetData(), m_pCurrentCycle->GetDataSize());

        delete m_pCurrentCycle;
        m_pCurrentCycle = nullptr;
    }

private:
    XLEN m_XLEN;
    const trace::LoggerConfig& m_Config;
    const trace::ILoggerTarget* m_pLoggerTarget {nullptr};

    trace::ITraceWriter* m_pTraceWriter {nullptr};
    trace::BinaryCycleBuilder* m_pCurrentCycle {nullptr};
};

Logger::Logger(XLEN xlen, const trace::LoggerConfig& config, const trace::ILoggerTarget* pSystem)
{
    m_pImpl = new LoggerImpl(xlen, config, pSystem);
}

Logger::~Logger()
{
    delete m_pImpl;
}

void Logger::BeginCycle(int cycle, uint64_t pc)
{
    m_pImpl->BeginCycle(cycle, pc);
}

void Logger::RecordState()
{
    m_pImpl->RecordState();
}

void Logger::RecordEvent()
{
    m_pImpl->RecordEvent();
}

void Logger::EndCycle()
{
    m_pImpl->EndCycle();
}

}}
