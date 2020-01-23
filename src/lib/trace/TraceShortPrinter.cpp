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

#include <cstdio>
#include <cinttypes>
#include <string>

#include <rafi/op.h>
#include <rafi/trace.h>

namespace rafi { namespace trace {

class TraceShortPrinterImpl
{
public:
    TraceShortPrinterImpl(XLEN xlen)
        : m_Decoder(xlen)
    {
    }

    void Print(const trace::ICycle* pCycle)
    {
        std::string opStr;

        if (pCycle->GetOpEventCount() > 0)
        {
            rafi::trace::OpEvent opEvent;
            pCycle->CopyOpEvent(&opEvent, 0);

            auto op = m_Decoder.Decode(opEvent.insn);
            
            if (op)
            {
                opStr = op->ToString();
            }
            else
            {
                opStr = "UNKNOWN";
            }
        }

        printf("%016" PRIx64 ":\t%s\n", pCycle->GetPc(), opStr.c_str());
    }

private:
    rafi::OpDecoder m_Decoder;
};

TraceShortPrinter::TraceShortPrinter(XLEN xlen)
{
    m_pImpl = new TraceShortPrinterImpl(xlen);
}

TraceShortPrinter::~TraceShortPrinter()
{
    delete m_pImpl;
}

void TraceShortPrinter::Print(const trace::ICycle* pCycle)
{
    m_pImpl->Print(pCycle);
}

}}
