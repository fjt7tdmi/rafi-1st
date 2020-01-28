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

namespace rafi { namespace op64 {

LUI::LUI(int rd, uint32_t imm)
    : m_Rd(rd)
    , m_Imm(imm)
{
}

std::string LUI::ToString() const
{
    char s[80];
    std::sprintf(s, "lui %s,%d", GetIntRegName(m_Rd), m_Imm);

    return std::string(s);
}

// ============================================================================

AUIPC::AUIPC(int rd, uint32_t imm)
    : m_Rd(rd)
    , m_Imm(imm)
{
}

std::string AUIPC::ToString() const
{
    char s[80];
    std::sprintf(s, "auipc %s,%d", GetIntRegName(m_Rd), m_Imm);

    return std::string(s);
}

// ============================================================================

JAL::JAL(int rd, uint32_t imm)
    : m_Rd(rd)
    , m_Imm(imm)
{
}

std::string JAL::ToString() const
{
    char s[80];

    if (m_Rd == 0)
    {
        std::sprintf(s, "j #%d", m_Imm);
    }
    else
    {
        std::sprintf(s, "jal %s,%d", GetIntRegName(m_Rd), m_Imm);
    }

    return std::string(s);
}

// ============================================================================

JALR::JALR(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string JALR::ToString() const
{
    char s[80];

    if (m_Rd == 0)
    {
        std::sprintf(s, "jr %s,%d", GetIntRegName(m_Rs1), m_Imm);
    }
    else
    {
        std::sprintf(s, "jalr %s,%s,%d", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Imm);
    }

    return std::string(s);
}

// ============================================================================

BEQ::BEQ(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string BEQ::ToString() const
{
    return std::string("beq");
}

// ============================================================================

BNE::BNE(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string BNE::ToString() const
{
    char s[80];

    if (m_Rs1 == 0)
    {
        std::sprintf(s, "bnez %s, #%d", GetIntRegName(m_Rs2), m_Imm);
    }
    else if (m_Rs2 == 0)
    {
        std::sprintf(s, "bnez %s, #%d", GetIntRegName(m_Rs1), m_Imm);
    }
    else
    {
        std::sprintf(s, "bne %s,%s,%d", GetIntRegName(m_Rs1), GetIntRegName(m_Rs2), m_Imm);
    }

    return std::string(s);
}

// ============================================================================

BLT::BLT(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string BLT::ToString() const
{
    char s[80];

    if (m_Rs1 == 0)
    {
        std::sprintf(s, "bltz %s, #%d", GetIntRegName(m_Rs2), m_Imm);
    }
    else if (m_Rs2 == 0)
    {
        std::sprintf(s, "bltz %s, #%d", GetIntRegName(m_Rs1), m_Imm);
    }
    else
    {
        std::sprintf(s, "blt %s,%s,%d", GetIntRegName(m_Rs1), GetIntRegName(m_Rs2), m_Imm);
    }

    return std::string(s);
}

// ============================================================================

BGE::BGE(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string BGE::ToString() const
{
    char s[80];

    if (m_Rs1 == 0)
    {
        std::sprintf(s, "bgez %s, #%d", GetIntRegName(m_Rs2), m_Imm);
    }
    else if (m_Rs2 == 0)
    {
        std::sprintf(s, "bgez %s, #%d", GetIntRegName(m_Rs1), m_Imm);
    }
    else
    {
        std::sprintf(s, "bge %s,%s,%d", GetIntRegName(m_Rs1), GetIntRegName(m_Rs2), m_Imm);
    }

    return std::string(s);
}

// ============================================================================

BLTU::BLTU(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string BLTU::ToString() const
{
    char s[80];
    std::sprintf(s, "bltu %s,%s,%d", GetIntRegName(m_Rs1), GetIntRegName(m_Rs2), m_Imm);

    return std::string(s);
}

// ============================================================================

BGEU::BGEU(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string BGEU::ToString() const
{
    char s[80];
    std::sprintf(s, "bgeu %s,%s,%d", GetIntRegName(m_Rs1), GetIntRegName(m_Rs2), m_Imm);

    return std::string(s);
}

// ============================================================================

LB::LB(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string LB::ToString() const
{
    char s[80];
    std::sprintf(s, "lb %s,%d(%s)", GetIntRegName(m_Rd), m_Imm, GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

LH::LH(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string LH::ToString() const
{
    char s[80];
    std::sprintf(s, "lh %s,%d(%s)", GetIntRegName(m_Rd), m_Imm, GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

LW::LW(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string LW::ToString() const
{
    char s[80];
    std::sprintf(s, "lw %s,%d(%s)", GetIntRegName(m_Rd), m_Imm, GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

LD::LD(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string LD::ToString() const
{
    char s[80];
    std::sprintf(s, "ld %s,%d(%s)", GetIntRegName(m_Rd), m_Imm, GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

LBU::LBU(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string LBU::ToString() const
{
    char s[80];
    std::sprintf(s, "lbu %s,%d(%s)", GetIntRegName(m_Rd), m_Imm, GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

LHU::LHU(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string LHU::ToString() const
{
    char s[80];
    std::sprintf(s, "lhu %s,%d(%s)", GetIntRegName(m_Rd), m_Imm, GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

LWU::LWU(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string LWU::ToString() const
{
    char s[80];
    std::sprintf(s, "lwu %s,%d(%s)", GetIntRegName(m_Rd), m_Imm, GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

SB::SB(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string SB::ToString() const
{
    char s[80];
    std::sprintf(s, "sb %s,%d(%s)", GetIntRegName(m_Rs2), m_Imm, GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

SH::SH(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string SH::ToString() const
{
    char s[80];
    std::sprintf(s, "sh %s,%d(%s)", GetIntRegName(m_Rs2), m_Imm, GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

SW::SW(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string SW::ToString() const
{
    char s[80];
    std::sprintf(s, "sw %s,%d(%s)", GetIntRegName(m_Rs2), m_Imm, GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

SD::SD(int rs1, int rs2, uint32_t imm)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
    , m_Imm(imm)
{
}

std::string SD::ToString() const
{
    char s[80];
    std::sprintf(s, "sd %s,%d(%s)", GetIntRegName(m_Rs2), m_Imm, GetIntRegName(m_Rs1));

    return std::string(s);
}

// ============================================================================

ADDI::ADDI(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string ADDI::ToString() const
{
    char s[80];
    std::sprintf(s, "addi %s,%s,%d", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Imm);

    return std::string(s);
}

// ============================================================================

ADDIW::ADDIW(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string ADDIW::ToString() const
{
    char s[80];
    std::sprintf(s, "addiw %s,%s,%d", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Imm);

    return std::string(s);
}

// ============================================================================

SLTI::SLTI(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string SLTI::ToString() const
{
    char s[80];
    std::sprintf(s, "slti %s,%s,%d", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Imm);

    return std::string(s);
}

// ============================================================================

SLTIU::SLTIU(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string SLTIU::ToString() const
{
    char s[80];
    std::sprintf(s, "sltiu %s,%s,%d", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Imm);

    return std::string(s);
}

// ============================================================================

XORI::XORI(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string XORI::ToString() const
{
    char s[80];
    std::sprintf(s, "xori %s,%s,%d", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Imm);

    return std::string(s);
}

// ============================================================================

ORI::ORI(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string ORI::ToString() const
{
    char s[80];
    std::sprintf(s, "ori %s,%s,%d", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Imm);

    return std::string(s);
}

// ============================================================================

ANDI::ANDI(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string ANDI::ToString() const
{
    char s[80];
    std::sprintf(s, "andi %s,%s,%d", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Imm);

    return std::string(s);
}

// ============================================================================

SLLI::SLLI(int rd, int rs1, int shamt)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Shamt(shamt)
{
}

std::string SLLI::ToString() const
{
    char s[80];
    std::sprintf(s, "slli %s,%s,0x%x", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Shamt);

    return std::string(s);
}

// ============================================================================

SLLIW::SLLIW(int rd, int rs1, int shamt)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Shamt(shamt)
{
}

std::string SLLIW::ToString() const
{
    char s[80];
    std::sprintf(s, "slliw %s,%s,0x%x", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Shamt);

    return std::string(s);
}

// ============================================================================

SRLI::SRLI(int rd, int rs1, int shamt)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Shamt(shamt)
{
}

std::string SRLI::ToString() const
{
    char s[80];
    std::sprintf(s, "srli %s,%s,0x%x", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Shamt);

    return std::string(s);
}

// ============================================================================

SRLIW::SRLIW(int rd, int rs1, int shamt)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Shamt(shamt)
{
}

std::string SRLIW::ToString() const
{
    char s[80];
    std::sprintf(s, "srliw %s,%s,0x%x", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Shamt);

    return std::string(s);
}

// ============================================================================

SRAI::SRAI(int rd, int rs1, int shamt)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Shamt(shamt)
{
}

std::string SRAI::ToString() const
{
    char s[80];
    std::sprintf(s, "srai %s,%s,0x%x", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Shamt);

    return std::string(s);
}

// ============================================================================

SRAIW::SRAIW(int rd, int rs1, int shamt)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Shamt(shamt)
{
}

std::string SRAIW::ToString() const
{
    char s[80];
    std::sprintf(s, "sraiw %s,%s,0x%x", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), m_Shamt);

    return std::string(s);
}

// ============================================================================

ADD::ADD(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string ADD::ToString() const
{
    char s[80];
    std::sprintf(s, "add %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

ADDW::ADDW(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string ADDW::ToString() const
{
    char s[80];
    std::sprintf(s, "addw %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

SUB::SUB(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string SUB::ToString() const
{
    char s[80];
    std::sprintf(s, "sub %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

SUBW::SUBW(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string SUBW::ToString() const
{
    char s[80];
    std::sprintf(s, "subw %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

SLL::SLL(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string SLL::ToString() const
{
    char s[80];
    std::sprintf(s, "sll %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

SLLW::SLLW(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string SLLW::ToString() const
{
    char s[80];
    std::sprintf(s, "sllw %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

SLT::SLT(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string SLT::ToString() const
{
    char s[80];
    std::sprintf(s, "slt %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

SLTU::SLTU(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string SLTU::ToString() const
{
    char s[80];
    std::sprintf(s, "sltu %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

XOR::XOR(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string XOR::ToString() const
{
    char s[80];
    std::sprintf(s, "xor %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

SRL::SRL(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string SRL::ToString() const
{
    char s[80];
    std::sprintf(s, "srl %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

SRLW::SRLW(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string SRLW::ToString() const
{
    char s[80];
    std::sprintf(s, "srlw %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

SRA::SRA(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string SRA::ToString() const
{
    char s[80];
    std::sprintf(s, "sra %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

SRAW::SRAW(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string SRAW::ToString() const
{
    char s[80];
    std::sprintf(s, "sraw %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

OR::OR(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string OR::ToString() const
{
    char s[80];
    std::sprintf(s, "or %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

AND::AND(int rd, int rs1, int rs2)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string AND::ToString() const
{
    char s[80];
    std::sprintf(s, "and %s,%s,%s", GetIntRegName(m_Rd), GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

// ============================================================================

FENCE::FENCE(int rd, int rs1, uint32_t fm, uint32_t pred, uint32_t succ)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Fm(fm)
    , m_Pred(pred)
    , m_Succ(succ)
{
}

std::string FENCE::ToString() const
{
    return std::string("fence");
}


// ============================================================================

FENCE_I::FENCE_I(int rd, int rs1, uint32_t imm)
    : m_Rd(rd)
    , m_Rs1(rs1)
    , m_Imm(imm)
{
}

std::string FENCE_I::ToString() const
{
    return std::string("fence.i");
}

// ============================================================================

ECALL::ECALL()
{
}

std::string ECALL::ToString() const
{
    return std::string("ecall");
}

// ============================================================================

EBREAK::EBREAK()
{
}

std::string EBREAK::ToString() const
{
    return std::string("ebreak");
}

// ============================================================================

CSRRW::CSRRW(uint32_t csr, int rd, int rs1)
    : m_Csr(csr)
    , m_Rd(rd)
    , m_Rs1(rs1)
{
}

std::string CSRRW::ToString() const
{
    char s[80];

    if (m_Rd == 0)
    {
        std::sprintf(s, "csrw %s,%s", GetString(static_cast<csr_addr_t>(m_Csr)), GetIntRegName(m_Rs1));
    }
    else
    {
        std::sprintf(s, "csrrw %s,%s,%s", GetIntRegName(m_Rd), GetString(static_cast<csr_addr_t>(m_Csr)), GetIntRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

CSRRS::CSRRS(uint32_t csr, int rd, int rs1)
    : m_Csr(csr)
    , m_Rd(rd)
    , m_Rs1(rs1)
{
}

std::string CSRRS::ToString() const
{
    char s[80];

    if (m_Rs1 == 0)
    {
        std::sprintf(s, "csrr %s,%s", GetIntRegName(m_Rd), GetString(static_cast<csr_addr_t>(m_Csr)));
    }
    else if (m_Rd == 0)
    {
        std::sprintf(s, "csrr %s,%s", GetString(static_cast<csr_addr_t>(m_Csr)), GetIntRegName(m_Rs1));
    }
    else
    {
        std::sprintf(s, "csrrs %s,%s,%s", GetIntRegName(m_Rd), GetString(static_cast<csr_addr_t>(m_Csr)), GetIntRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

CSRRC::CSRRC(uint32_t csr, int rd, int rs1)
    : m_Csr(csr)
    , m_Rd(rd)
    , m_Rs1(rs1)
{
}

std::string CSRRC::ToString() const
{
    char s[80];

    if (m_Rd == 0)
    {
        std::sprintf(s, "csrc %s,%s", GetString(static_cast<csr_addr_t>(m_Csr)), GetIntRegName(m_Rs1));
    }
    else
    {
        std::sprintf(s, "csrrc %s,%s,%s", GetIntRegName(m_Rd), GetString(static_cast<csr_addr_t>(m_Csr)), GetIntRegName(m_Rs1));
    }

    return std::string(s);
}

// ============================================================================

CSRRWI::CSRRWI(uint32_t csr, int rd, uint32_t uimm)
    : m_Csr(csr)
    , m_Rd(rd)
    , m_UImm(uimm)
{
}

std::string CSRRWI::ToString() const
{
    char s[80];

    if (m_Rd == 0)
    {
        std::sprintf(s, "csrwi %s,%d", GetString(static_cast<csr_addr_t>(m_Csr)), m_UImm);
    }
    else
    {
        std::sprintf(s, "csrrwi %s,%s,%d", GetIntRegName(m_Rd), GetString(static_cast<csr_addr_t>(m_Csr)), m_UImm);
    }

    return std::string(s);
}

// ============================================================================

CSRRSI::CSRRSI(uint32_t csr, int rd, uint32_t uimm)
    : m_Csr(csr)
    , m_Rd(rd)
    , m_UImm(uimm)
{
}

std::string CSRRSI::ToString() const
{
    char s[80];

    if (m_Rd == 0)
    {
        std::sprintf(s, "csrsi %s,%d", GetString(static_cast<csr_addr_t>(m_Csr)), m_UImm);
    }
    else
    {
        std::sprintf(s, "csrrsi %s,%s,%d", GetIntRegName(m_Rd), GetString(static_cast<csr_addr_t>(m_Csr)), m_UImm);
    }

    return std::string(s);
}

// ============================================================================

CSRRCI::CSRRCI(uint32_t csr, int rd, uint32_t uimm)
    : m_Csr(csr)
    , m_Rd(rd)
    , m_UImm(uimm)
{
}

std::string CSRRCI::ToString() const
{
    char s[80];

    if (m_Rd == 0)
    {
        std::sprintf(s, "csrci %s,%d", GetString(static_cast<csr_addr_t>(m_Csr)), m_UImm);
    }
    else
    {
        std::sprintf(s, "csrrci %s,%s,%d", GetIntRegName(m_Rd), GetString(static_cast<csr_addr_t>(m_Csr)), m_UImm);
    }

    return std::string(s);
}

// ============================================================================

URET::URET()
{
}

std::string URET::ToString() const
{
    return std::string("uret");
}

// ============================================================================

SRET::SRET()
{
}

std::string SRET::ToString() const
{
    return std::string("sret");
}

// ============================================================================

MRET::MRET()
{
}

std::string MRET::ToString() const
{
    return std::string("mret");
}

// ============================================================================

WFI::WFI()
{
}

std::string WFI::ToString() const
{
    return std::string("wfi");
}

// ============================================================================

SFENCE_VMA::SFENCE_VMA(int rs1, int rs2)
    : m_Rs1(rs1)
    , m_Rs2(rs2)
{
}

std::string SFENCE_VMA::ToString() const
{
    char s[80];
    std::sprintf(s, "sfence.vma %s,%s", GetIntRegName(m_Rs1), GetIntRegName(m_Rs2));

    return std::string(s);
}

}}
