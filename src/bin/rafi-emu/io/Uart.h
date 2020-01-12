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

#include <vector>

#include <rafi/emu.h>

#include "../io/IIo.h"

namespace rafi { namespace emu { namespace io {

class Uart : public IIo
{
public:
    virtual void Read(void* pOutBuffer, size_t size, uint64_t address) override;
    virtual void Write(const void* pBuffer, size_t size, uint64_t address) override;
    virtual int GetSize() const override;
    virtual bool IsInterruptRequested() const override;

    void ProcessCycle();

private:
    struct InterruptEnable : BitField32
    {
        InterruptEnable()
        {
        }

        InterruptEnable(uint32_t value) : BitField32(value)
        {
        }

        using TXIE = Member<1>;
        using RXIE = Member<2>;
    };

    struct InterruptPending : BitField32
    {
        InterruptPending()
        {
        }

        InterruptPending(uint32_t value) : BitField32(value)
        {
        }

        using TXIP = Member<1>;
        using RXIP = Member<2>;
    };


    static const int RegisterSpaceSize = 32;
    static const int InitialRxCycle = 100;
    static const int RxCycle = 50;

    // Register address
    static const int Address_TxData = 0;
    static const int Address_RxData = 4;
    static const int Address_InterruptEnable = 16;
    static const int Address_InterruptPending = 24;

    void UpdateRx();
    void PrintTx();

    InterruptEnable m_InterruptEnable;
    InterruptPending m_InterruptPending;

    std::vector<char> m_TxChars;
    char m_RxChar {'\0'};

    int m_Cycle {0};
    size_t m_PrintCount {0};
};

}}}
