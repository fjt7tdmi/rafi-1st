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

namespace rafi { namespace op32 {

MUL::MUL(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string MUL::ToString() const
{
    char s[80];
    std::sprintf(s, "mul %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

MULH::MULH(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string MULH::ToString() const
{
    char s[80];
    std::sprintf(s, "mulh %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

MULHSU::MULHSU(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string MULHSU::ToString() const
{
    char s[80];
    std::sprintf(s, "mulhsu %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

MULHU::MULHU(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string MULHU::ToString() const
{
    char s[80];
    std::sprintf(s, "mulhu %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

DIV::DIV(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string DIV::ToString() const
{
    char s[80];
    std::sprintf(s, "div %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

DIVU::DIVU(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string DIVU::ToString() const
{
    char s[80];
    std::sprintf(s, "divu %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

REM::REM(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string REM::ToString() const
{
    char s[80];
    std::sprintf(s, "rem %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

REMU::REMU(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string REMU::ToString() const
{
    char s[80];
    std::sprintf(s, "remu %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

}}
