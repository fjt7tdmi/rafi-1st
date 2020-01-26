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

FLD::FLD(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string FLD::ToString() const
{
    char s[80];
    std::sprintf(s, "fld %s,%d(%s)",
        GetFpRegName(m_Rd),
        m_Imm,
        GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

FSD::FSD(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string FSD::ToString() const
{
    char s[80];
    std::sprintf(s, "fsd %s,%d(%s)",
        GetFpRegName(m_Rs2),
        m_Imm,
        GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

FMADD_D::FMADD_D(int rd, int rs1, int rs2, int rs3, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rs3(rs3)
    , m_Rm(rm)
{
}

std::string FMADD_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fmadd.d %s,%s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3),
            rm);
    }
    else
    {
        std::sprintf(s, "fmadd.d %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3));
    }

    return std::string(s);
}

// ============================================================================

FMSUB_D::FMSUB_D(int rd, int rs1, int rs2, int rs3, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rs3(rs3)
    , m_Rm(rm)
{
}

std::string FMSUB_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fmsub.d %s,%s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3),
            rm);
    }
    else
    {
        std::sprintf(s, "fmsub.d %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3));
    }

    return std::string(s);
}

// ============================================================================

FNMADD_D::FNMADD_D(int rd, int rs1, int rs2, int rs3, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rs3(rs3)
    , m_Rm(rm)
{
}

std::string FNMADD_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fnmadd.d %s,%s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3),
            rm);
    }
    else
    {
        std::sprintf(s, "fnmadd.d %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3));
    }

    return std::string(s);
}

// ============================================================================

FNMSUB_D::FNMSUB_D(int rd, int rs1, int rs2, int rs3, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rs3(rs3)
    , m_Rm(rm)
{
}

std::string FNMSUB_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fnmsub.d %s,%s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3),
            rm);
    }
    else
    {
        std::sprintf(s, "fnmsub.d %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            GetFpRegName(m_Rs3));
    }

    return std::string(s);
}

// ============================================================================

FADD_D::FADD_D(int rd, int rs1, int rs2, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rm(rm)
{
}

std::string FADD_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fadd.d %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            rm);
    }
    else
    {
        std::sprintf(s, "fadd.d %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2));
    }

    return std::string(s);
}

// ============================================================================

FSUB_D::FSUB_D(int rd, int rs1, int rs2, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rm(rm)
{
}

std::string FSUB_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fsub.d %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            rm);
    }
    else
    {
        std::sprintf(s, "fsub.d %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2));
    }

    return std::string(s);
}

// ============================================================================

FMUL_D::FMUL_D(int rd, int rs1, int rs2, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rm(rm)
{
}

std::string FMUL_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fmul.d %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            rm);
    }
    else
    {
        std::sprintf(s, "fmul.d %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2));
    }

    return std::string(s);
}

// ============================================================================

FDIV_D::FDIV_D(int rd, int rs1, int rs2, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Rm(rm)
{
}

std::string FDIV_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fdiv.d %s,%s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2),
            rm);
    }
    else
    {
        std::sprintf(s, "fdiv.d %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            GetFpRegName(m_Rs2));
    }

    return std::string(s);
}

// ============================================================================

FSQRT_D::FSQRT_D(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FSQRT_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fsqrt.d %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            rm);
    }
    else
    {
        std::sprintf(s, "fsqrt.d %s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

FSGNJ_D::FSGNJ_D(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FSGNJ_D::ToString() const
{
    char s[80];
    std::sprintf(s, "fsgnj.d %s,%s,%s",
        GetFpRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FSGNJN_D::FSGNJN_D(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FSGNJN_D::ToString() const
{
    char s[80];
    std::sprintf(s, "fsgnjn.d %s,%s,%s",
        GetFpRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FSGNJX_D::FSGNJX_D(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FSGNJX_D::ToString() const
{
    char s[80];
    std::sprintf(s, "fsgnjx.d %s,%s,%s",
        GetFpRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FMIN_D::FMIN_D(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FMIN_D::ToString() const
{
    char s[80];
    std::sprintf(s, "fmin.d %s,%s,%s",
        GetFpRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FMAX_D::FMAX_D(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FMAX_D::ToString() const
{
    char s[80];
    std::sprintf(s, "fmax.d %s,%s,%s",
        GetFpRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FCVT_S_D::FCVT_S_D(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FCVT_S_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fcvt.s.d %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            rm);
    }
    else
    {
        std::sprintf(s, "fcvt.s.d %s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

FCVT_D_S::FCVT_D_S(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FCVT_D_S::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fcvt.d.s %s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1));
    }
    else
    {
        std::sprintf(s, "fcvt.d.s %s,%s,%s",
            GetFpRegName(m_Rd),
            GetFpRegName(m_Rs1),
            rm);
    }

    return std::string(s);
}

// ============================================================================

FEQ_D::FEQ_D(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FEQ_D::ToString() const
{
    char s[80];
    std::sprintf(s, "feq.d %s,%s,%s",
        GetIntRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FLT_D::FLT_D(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FLT_D::ToString() const
{
    char s[80];
    std::sprintf(s, "flt.d %s,%s,%s",
        GetIntRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FLE_D::FLE_D(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string FLE_D::ToString() const
{
    char s[80];
    std::sprintf(s, "fle.d %s,%s,%s",
        GetIntRegName(m_Rd),
        GetFpRegName(m_Rs1),
        GetFpRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FCLASS_D::FCLASS_D(int rd, int rs1)
    : m_Rd(rd)
    , m_Rs1(rs1)
{
}

std::string FCLASS_D::ToString() const
{
    char s[80];
    std::sprintf(s, "fclass.d %s,%s",
        GetIntRegName(m_Rd),
        GetFpRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

FCVT_W_D::FCVT_W_D(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FCVT_W_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fcvt.w.d %s,%s,%s",
            GetIntRegName(m_Rd),
            GetFpRegName(m_Rs1),
            rm);
    }
    else
    {
        std::sprintf(s, "fcvt.w.d %s,%s",
            GetIntRegName(m_Rd),
            GetFpRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

FCVT_WU_D::FCVT_WU_D(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FCVT_WU_D::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fcvt.wu.d %s,%s,%s",
            GetIntRegName(m_Rd),
            GetFpRegName(m_Rs1),
            rm);
    }
    else
    {
        std::sprintf(s, "fcvt.wu.d %s,%s",
            GetIntRegName(m_Rd),
            GetFpRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

FCVT_D_W::FCVT_D_W(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FCVT_D_W::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fcvt.d.w %s,%s",
            GetFpRegName(m_Rd),
            GetIntRegName(m_Rs1));
    }
    else
    {
        std::sprintf(s, "fcvt.d.w %s,%s,%s",
            GetFpRegName(m_Rd),
            GetIntRegName(m_Rs1),
            rm);
    }

    return std::string(s);
}

// ============================================================================

FCVT_D_WU::FCVT_D_WU(int rd, int rs1, int rm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rm(rm)
{
}

std::string FCVT_D_WU::ToString() const
{
    char s[80];

    const auto rm = GetRoundingModeName(m_Rm);
    if (rm)
    {
        std::sprintf(s, "fcvt.d.wu %s,%s",
            GetFpRegName(m_Rd),
            GetIntRegName(m_Rs1));
    }
    else
    {
        std::sprintf(s, "fcvt.d.wu %s,%s,%s",
            GetFpRegName(m_Rd),
            GetIntRegName(m_Rs1),
            rm);
    }

    return std::string(s);
}

}}
