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

#include <rafi/op.h>

namespace rafi { namespace op32 {

FLW::FLW(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string FLW::ToString() const
{
    char s[80];
    std::sprintf(s, "flw %s,%d(%s)",
        GetFpRegName(m_Rd),
        m_Imm,
        GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

FSW::FSW(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string FSW::ToString() const
{
    char s[80];
    std::sprintf(s, "fsw %s,%d(%s)",
        GetFpRegName(m_Rs2),
        m_Imm,
        GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

FMADD_S::FMADD_S(int rd, int rs1, int rs2, int rs3, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rs3(rs3)
    , m_Rm(rm)
{
}

std::string FMADD_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fmadd.s %s,%s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3),
            rm);
    }
    else
    {
        std::sprintf(s, "fmadd.s %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3));
    }

    return std::string(s);
}

// ============================================================================

FMSUB_S::FMSUB_S(int rd, int rs1, int rs2, int rs3, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rs3(rs3)
    , m_Rm(rm)
{
}

std::string FMSUB_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fmsub.s %s,%s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3),
            rm);
    }
    else
    {
        std::sprintf(s, "fmsub.s %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3));
    }

    return std::string(s);
}

// ============================================================================

FNMADD_S::FNMADD_S(int rd, int rs1, int rs2, int rs3, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rs3(rs3)
    , m_Rm(rm)
{
}

std::string FNMADD_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fnmadd.s %s,%s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3),
            rm);
    }
    else
    {
        std::sprintf(s, "fnmadd.s %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3));
    }

    return std::string(s);
}

// ============================================================================

FNMSUB_S::FNMSUB_S(int rd, int rs1, int rs2, int rs3, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rs3(rs3)
    , m_Rm(rm)
{
}

std::string FNMSUB_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fnmsub.s %s,%s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3),
            rm);
    }
    else
    {
        std::sprintf(s, "fnmsub.s %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3));
    }

    return std::string(s);
}

// ============================================================================

FADD_S::FADD_S(int rd, int rs1, int rs2, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rm(rm)
{
}

std::string FADD_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fadd.s %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            rm);
    }
    else
    {
        std::sprintf(s, "fadd.s %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2));
    }

    return std::string(s);
}

// ============================================================================

FSUB_S::FSUB_S(int rd, int rs1, int rs2, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rm(rm)
{
}

std::string FSUB_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fsub.s %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            rm);
    }
    else
    {
        std::sprintf(s, "fsub.s %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2));
    }

    return std::string(s);
}

// ============================================================================

FMUL_S::FMUL_S(int rd, int rs1, int rs2, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rm(rm)
{
}

std::string FMUL_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fmul.s %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            rm);
    }
    else
    {
        std::sprintf(s, "fmul.s %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2));
    }

    return std::string(s);
}

// ============================================================================

FDIV_S::FDIV_S(int rd, int rs1, int rs2, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rm(rm)
{
}

std::string FDIV_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fdiv.s %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            rm);
    }
    else
    {
        std::sprintf(s, "fdiv.s %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2));
    }

    return std::string(s);
}

// ============================================================================

FSQRT_S::FSQRT_S(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FSQRT_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fsqrt.s %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            rm);
    }
    else
    {
        std::sprintf(s, "fsqrt.s %s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

FSGNJ_S::FSGNJ_S(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FSGNJ_S::ToString() const
{
    char s[80];
    std::sprintf(s, "fsgnj.s %s,%s,%s",
        GetFpRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FSGNJN_S::FSGNJN_S(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FSGNJN_S::ToString() const
{
    char s[80];
    std::sprintf(s, "fsgnjn.s %s,%s,%s",
        GetFpRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FSGNJX_S::FSGNJX_S(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FSGNJX_S::ToString() const
{
    char s[80];
    std::sprintf(s, "fsgnjx.s %s,%s,%s",
        GetFpRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FMIN_S::FMIN_S(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FMIN_S::ToString() const
{
    char s[80];
    std::sprintf(s, "fmin.s %s,%s,%s",
        GetFpRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FMAX_S::FMAX_S(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FMAX_S::ToString() const
{
    char s[80];
    std::sprintf(s, "fmax.s %s,%s,%s",
        GetFpRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FCVT_W_S::FCVT_W_S(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FCVT_W_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fcvt.w.s %s,%s,%s",
            GetIntRegName(m_Rd),
            GetFpRegName(m_Rs1),
            rm);
    }
    else
    {
        std::sprintf(s, "fcvt.w.s %s,%s",
            GetIntRegName(m_Rd),
            GetFpRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

FCVT_WU_S::FCVT_WU_S(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FCVT_WU_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fcvt.wu.s %s,%s,%s",
            GetIntRegName(m_Rd),
            GetFpRegName(m_Rs1),
            rm);
    }
    else
    {
        std::sprintf(s, "fcvt.wu.s %s,%s",
            GetIntRegName(m_Rd),
            GetFpRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

FMV_X_W::FMV_X_W(int rd, int rs1)
    : m_Rd(rd)
    , m_Rs1(rs1)
{
}

std::string FMV_X_W::ToString() const
{
    char s[80];
    std::sprintf(s, "fmv.x.w %s,%s",
        GetIntRegName(m_Rd),
        GetFpRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

FEQ_S::FEQ_S(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FEQ_S::ToString() const
{
    char s[80];
    std::sprintf(s, "feq.s %s,%s,%s",
        GetIntRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FLT_S::FLT_S(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FLT_S::ToString() const
{
    char s[80];
    std::sprintf(s, "flt.s %s,%s,%s",
        GetIntRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FLE_S::FLE_S(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FLE_S::ToString() const
{
    char s[80];
    std::sprintf(s, "fle.s %s,%s,%s",
        GetIntRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FCLASS_S::FCLASS_S(int rd, int rs1)
    : m_Rd(rd)
    , m_Rs1(rs1)
{
}

std::string FCLASS_S::ToString() const
{
    char s[80];
    std::sprintf(s, "fclass.s %s,%s",
        GetIntRegName(m_Rd),
        GetFpRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

FCVT_S_W::FCVT_S_W(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FCVT_S_W::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fcvt.s.w %s,%s,%s",
            GetFpRegName(m_Rd),
            GetIntRegName(m_Rs1),
            rm);
    }
    else
    {
        std::sprintf(s, "fcvt.s.w %s,%s",
            GetFpRegName(m_Rd),
            GetIntRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

FCVT_S_WU::FCVT_S_WU(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FCVT_S_WU::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fcvt.s.wu %s,%s,%s",
            GetFpRegName(m_Rd),
            GetIntRegName(m_Rs1),
            rm);
    }
    else
    {
        std::sprintf(s, "fcvt.s.wu %s,%s",
            GetFpRegName(m_Rd),
            GetIntRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

FMV_W_X::FMV_W_X(int rd, int rs1)
    : m_Rd(rd)
    , m_Rs1(rs1)
{
}

std::string FMV_W_X::ToString() const
{
    char s[80];
    std::sprintf(s, "fmv.w.x %s,%s",
        GetFpRegName(m_Rd),
        GetIntRegName(m_Rs1));

    return std::string(s);
}

}}
