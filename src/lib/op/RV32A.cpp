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

#include <cstring>
#include <rafi/op.h>

namespace rafi { namespace rv32a {

LR_W::LR_W(int rd, int rs1, bool aq, bool rl)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Aq(aq)
    , m_Rl(rl)
{
}

std::string LR_W::ToString() const
{
    char s[80];
    std::sprintf(s, "lr.w %s,(%s)", GetIntRegName(m_Rd), GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

SC_W::SC_W(int rd, int rs1, int rs2, bool aq, bool rl)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Aq(aq)
    , m_Rl(rl)
{
}

std::string SC_W::ToString() const
{
    char s[80];
    std::sprintf(s, "sc.w %s,%s,(%s)", GetIntRegName(m_Rd), GetIntRegName(m_Rs2), GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

AMOSWAP_W::AMOSWAP_W(int rd, int rs1, int rs2, bool aq, bool rl)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Aq(aq)
    , m_Rl(rl)
{
}

std::string AMOSWAP_W::ToString() const
{
    char s[80];
    std::sprintf(s, "amoswap.w %s,%s,(%s)", GetIntRegName(m_Rd), GetIntRegName(m_Rs2), GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

AMOADD_W::AMOADD_W(int rd, int rs1, int rs2, bool aq, bool rl)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Aq(aq)
    , m_Rl(rl)
{
}

std::string AMOADD_W::ToString() const
{
    char s[80];
    std::sprintf(s, "amoadd.w %s,%s,(%s)", GetIntRegName(m_Rd), GetIntRegName(m_Rs2), GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

AMOXOR_W::AMOXOR_W(int rd, int rs1, int rs2, bool aq, bool rl)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Aq(aq)
    , m_Rl(rl)
{
}

std::string AMOXOR_W::ToString() const
{
    char s[80];
    std::sprintf(s, "amoxor.w %s,%s,(%s)", GetIntRegName(m_Rd), GetIntRegName(m_Rs2), GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

AMOAND_W::AMOAND_W(int rd, int rs1, int rs2, bool aq, bool rl)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Aq(aq)
    , m_Rl(rl)
{
}

std::string AMOAND_W::ToString() const
{
    char s[80];
    std::sprintf(s, "amoand.w %s,%s,(%s)", GetIntRegName(m_Rd), GetIntRegName(m_Rs2), GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

AMOOR_W::AMOOR_W(int rd, int rs1, int rs2, bool aq, bool rl)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Aq(aq)
    , m_Rl(rl)
{
}

std::string AMOOR_W::ToString() const
{
    char s[80];
    std::sprintf(s, "amoor.w %s,%s,(%s)", GetIntRegName(m_Rd), GetIntRegName(m_Rs2), GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

AMOMIN_W::AMOMIN_W(int rd, int rs1, int rs2, bool aq, bool rl)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Aq(aq)
    , m_Rl(rl)
{
}

std::string AMOMIN_W::ToString() const
{
    char s[80];
    std::sprintf(s, "amomin.w %s,%s,(%s)", GetIntRegName(m_Rd), GetIntRegName(m_Rs2), GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

AMOMAX_W::AMOMAX_W(int rd, int rs1, int rs2, bool aq, bool rl)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Aq(aq)
    , m_Rl(rl)
{
}

std::string AMOMAX_W::ToString() const
{
    char s[80];
    std::sprintf(s, "amomax.w %s,%s,(%s)", GetIntRegName(m_Rd), GetIntRegName(m_Rs2), GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

AMOMINU_W::AMOMINU_W(int rd, int rs1, int rs2, bool aq, bool rl)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Aq(aq)
    , m_Rl(rl)
{
}

std::string AMOMINU_W::ToString() const
{
    char s[80];
    std::sprintf(s, "amominu.w %s,%s,(%s)", GetIntRegName(m_Rd), GetIntRegName(m_Rs2), GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

AMOMAXU_W::AMOMAXU_W(int rd, int rs1, int rs2, bool aq, bool rl)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Aq(aq)
    , m_Rl(rl)
{
}

std::string AMOMAXU_W::ToString() const
{
    char s[80];
    std::sprintf(s, "amomaxu.w %s,%s,(%s)", GetIntRegName(m_Rd), GetIntRegName(m_Rs2), GetIntRegName(m_Rs1));

    return std::string(s);
}

}}
