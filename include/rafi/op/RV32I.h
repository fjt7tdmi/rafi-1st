/*
 * Copyright 2018 Akifumi Fujita
 *
 * Licensed under the Apache License, Version 2.0(the "License");
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

#include <rafi/op/OpCommon.h>

namespace rafi { namespace rv32i {

class LUI final : public IOp
{
public:
    LUI(int rd, uint32_t imm);

    virtual ~LUI() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    uint32_t m_Imm;
};

class AUIPC final : public IOp
{
public:
    AUIPC(int rd, uint32_t imm);

    virtual ~AUIPC() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    uint32_t m_Imm;
};

class JAL final : public IOp
{
public:
    JAL(int rd, uint32_t imm);

    virtual ~JAL() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    uint32_t m_Imm;
};

class JALR final : public IOp
{
public:
    JALR(int rd, int rs1, uint32_t imm);

    virtual ~JALR() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class BEQ final : public IOp
{
public:
    BEQ(int rs1, int rs2, uint32_t imm);

    virtual ~BEQ() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
    uint32_t m_Imm;
};

class BNE final : public IOp
{
public:
    BNE(int rs1, int rs2, uint32_t imm);
    
    virtual ~BNE() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
    uint32_t m_Imm;
};

class BLT final : public IOp
{
public:
    BLT(int rs1, int rs2, uint32_t imm);
    
    virtual ~BLT() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
    uint32_t m_Imm;
};

class BGE final : public IOp
{
public:
    BGE(int rs1, int rs2, uint32_t imm);

    virtual ~BGE() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
    uint32_t m_Imm;
};

class BLTU final : public IOp
{
public:
    BLTU(int rs1, int rs2, uint32_t imm);
    
    virtual ~BLTU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
    uint32_t m_Imm;
};

class BGEU final : public IOp
{
public:
    BGEU(int rs1, int rs2, uint32_t imm);

    virtual ~BGEU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
    uint32_t m_Imm;
};

class LB final : public IOp
{
public:
    LB(int rd, int rs1, uint32_t imm);
    
    virtual ~LB() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class LH final : public IOp
{
public:
    LH(int rd, int rs1, uint32_t imm);
    
    virtual ~LH() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class LW final : public IOp
{
public:
    LW(int rd, int rs1, uint32_t imm);
    
    virtual ~LW() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class LBU final : public IOp
{
public:
    LBU(int rd, int rs1, uint32_t imm);
    
    virtual ~LBU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class LHU final : public IOp
{
public:
    LHU(int rd, int rs1, uint32_t imm);

    virtual ~LHU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class SB final : public IOp
{
public:
    SB(int rs1, int rs2, uint32_t imm);

    virtual ~SB() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
    uint32_t m_Imm;
};

class SH final : public IOp
{
public:
    SH(int rs1, int rs2, uint32_t imm);

    virtual ~SH() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
    uint32_t m_Imm;
};

class SW final : public IOp
{
public:
    SW(int rs1, int rs2, uint32_t imm);

    virtual ~SW() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
    uint32_t m_Imm;
};

class ADDI final : public IOp
{
public:
    ADDI(int rd, int rs1, uint32_t imm);

    virtual ~ADDI() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class SLTI final : public IOp
{
public:
    SLTI(int rd, int rs1, uint32_t imm);

    virtual ~SLTI() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class SLTIU final : public IOp
{
public:
    SLTIU(int rd, int rs1, uint32_t imm);

    virtual ~SLTIU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class XORI final : public IOp
{
public:
    XORI(int rd, int rs1, uint32_t imm);

    virtual ~XORI() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class ORI final : public IOp
{
public:
    ORI(int rd, int rs1, uint32_t imm);

    virtual ~ORI() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class ANDI final : public IOp
{
public:
    ANDI(int rd, int rs1, uint32_t imm);

    virtual ~ANDI() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class SLLI final : public IOp
{
public:
    SLLI(int rd, int rs1, int shamt);

    virtual ~SLLI() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Shamt;
};

class SRLI final : public IOp
{
public:
    SRLI(int rd, int rs1, int shamt);

    virtual ~SRLI() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Shamt;
};

class SRAI final : public IOp
{
public:
    SRAI(int rd, int rs1, int shamt);

    virtual ~SRAI() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Shamt;
};

class ADD final : public IOp
{
public:
    ADD(int rd, int rs1, int rs2);

    virtual ~ADD() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class SUB final : public IOp
{
public:
    SUB(int rd, int rs1, int rs2);

    virtual ~SUB() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class SLL final : public IOp
{
public:
    SLL(int rd, int rs1, int rs2);

    virtual ~SLL() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class SLT final : public IOp
{
public:
    SLT(int rd, int rs1, int rs2);

    virtual ~SLT() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class SLTU final : public IOp
{
public:
    SLTU(int rd, int rs1, int rs2);

    virtual ~SLTU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class XOR final : public IOp
{
public:
    XOR(int rd, int rs1, int rs2);

    virtual ~XOR() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class SRL final : public IOp
{
public:
    SRL(int rd, int rs1, int rs2);

    virtual ~SRL() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class SRA final : public IOp
{
public:
    SRA(int rd, int rs1, int rs2);

    virtual ~SRA() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class OR final : public IOp
{
public:
    OR(int rd, int rs1, int rs2);
    
    virtual ~OR() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class AND final : public IOp
{
public:
    AND(int rd, int rs1, int rs2);

    virtual ~AND() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FENCE final : public IOp
{
public:
    FENCE(int rd, int rs1, uint32_t fm, uint32_t pred, uint32_t succ);

    virtual ~FENCE() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Fm;
    uint32_t m_Pred;
    uint32_t m_Succ;
};

class FENCE_I final : public IOp
{
public:
    FENCE_I(int rd, int rs1, uint32_t imm);

    virtual ~FENCE_I() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class ECALL final : public IOp
{
public:
    ECALL();

    virtual ~ECALL() override = default;
    virtual std::string ToString() const override;
};

class EBREAK final : public IOp
{
public:
    EBREAK();

    virtual ~EBREAK() override = default;
    virtual std::string ToString() const override;
};

class CSRRW final : public IOp
{
public:
    CSRRW(uint32_t csr, int rd, int rs1);

    virtual ~CSRRW() override = default;
    virtual std::string ToString() const override;

private:
    uint32_t m_Csr;
    int m_Rd;
    int m_Rs1;
};

class CSRRS final : public IOp
{
public:
    CSRRS(uint32_t csr, int rd, int rs1);

    virtual ~CSRRS() override = default;
    virtual std::string ToString() const override;

private:
    uint32_t m_Csr;
    int m_Rd;
    int m_Rs1;
};

class CSRRC final : public IOp
{
public:
    CSRRC(uint32_t csr, int rd, int rs1);

    virtual ~CSRRC() override = default;
    virtual std::string ToString() const override;

private:
    uint32_t m_Csr;
    int m_Rd;
    int m_Rs1;
};

class CSRRWI final : public IOp
{
public:
    CSRRWI(uint32_t csr, int rd, uint32_t uimm);
    
    virtual ~CSRRWI() override = default;
    virtual std::string ToString() const override;

private:
    uint32_t m_Csr;
    int m_Rd;
    uint32_t m_UImm;
};

class CSRRSI final : public IOp
{
public:
    CSRRSI(uint32_t csr, int rd, uint32_t uimm);

    virtual ~CSRRSI() override = default;
    virtual std::string ToString() const override;

private:
    uint32_t m_Csr;
    int m_Rd;
    uint32_t m_UImm;
};

class CSRRCI final : public IOp
{
public:
    CSRRCI(uint32_t csr, int rd, uint32_t uimm);

    virtual ~CSRRCI() override = default;
    virtual std::string ToString() const override;

private:
    uint32_t m_Csr;
    int m_Rd;
    uint32_t m_UImm;
};

class URET final : public IOp
{
public:
    URET();

    virtual ~URET() override = default;
    virtual std::string ToString() const override;
};

class SRET final : public IOp
{
public:
    SRET();

    virtual ~SRET() override = default;
    virtual std::string ToString() const override;
};

class MRET final : public IOp
{
public:
    MRET();

    virtual ~MRET() override = default;
    virtual std::string ToString() const override;
};

class WFI final : public IOp
{
public:
    WFI();

    virtual ~WFI() override = default;
    virtual std::string ToString() const override;
};

class SFENCE_VMA final : public IOp
{
public:
    SFENCE_VMA(int rs1, int rs2);

    virtual ~SFENCE_VMA() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
};

}}
