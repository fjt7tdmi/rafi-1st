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

namespace {

inline uint32_t Pick(uint32_t insn, int lsb, int width = 1)
{
    assert(0 <= lsb && lsb < 32);
    assert(1 <= width && width < 32);
    return (insn >> lsb) & ((1 << width) - 1);
}

}

namespace rafi {

class OpDecoderImpl
{
public:
    OpDecoderImpl(XLEN xlen)
        : m_XLEN(xlen)
    {
    }

    IOp* Decode(uint32_t insn) const
    {
        // TODO: impl RV32MADC
        // TODO: impl RV64IMADC
        return DecodeRV32I(insn);
    }

private:
    IOp* DecodeRV32I(uint32_t insn) const
    {
        const auto opcode = Pick(insn, 0, 7);
        const auto funct3 = Pick(insn, 12, 3);
        const auto funct7 = Pick(insn, 25, 7);
        const auto funct12 = Pick(insn, 20, 12);
        const auto csr = Pick(insn, 20, 12);

        const auto rd = static_cast<int>(Pick(insn, 7, 5));
        const auto rs1 = static_cast<int>(Pick(insn, 15, 5));
        const auto rs2 = static_cast<int>(Pick(insn, 20, 5));
        const auto shamt = static_cast<int>(Pick(insn, 20, 5));

        const auto immU = Pick(insn, 12, 20);
        const auto immI = Pick(insn, 20, 12);
        const auto immB = SignExtend(13,
            Pick(insn, 31, 1) << 12 |
            Pick(insn, 25, 6) << 5 |
            Pick(insn, 8, 4) << 1 |
            Pick(insn, 7, 1) << 11);
        const auto immS = SignExtend(12,
            Pick(insn, 25, 7) << 5 |
            Pick(insn, 7, 5));

        switch (opcode)
        {
        case 0b0110111:
            return new rv32i::LUI(rd, immU);
        case 0b0010111:
            return new rv32i::AUIPC(rd, immU);
        case 0b1101111:
            return new rv32i::JAL(rd, SignExtend(20,
                Pick(insn, 31, 1) << 20 |
                Pick(insn, 21, 10) << 1 |
                Pick(insn, 20, 1) << 11 |
                Pick(insn, 12, 8) << 12));
        case 0b1100111:
            if (funct3 == 0)
            {
                return new rv32i::JALR(rd, rs1, immI);
            }
            else
            {
                return nullptr;
            }
        case 0b1100011:
            if (funct3 == 0)
            {
                return new rv32i::BEQ(rs1, rs2, immB);
            }
            else if (funct3 == 1)
            {
                return new rv32i::BNE(rs1, rs2, immB);
            }
            else if (funct3 == 4)
            {
                return new rv32i::BLT(rs1, rs2, immB);
            }
            else if (funct3 == 5)
            {
                return new rv32i::BGE(rs1, rs2, immB);
            }
            else if (funct3 == 6)
            {
                return new rv32i::BLTU(rs1, rs2, immB);
            }
            else if (funct3 == 7)
            {
                return new rv32i::BGEU(rs1, rs2, immB);
            }
            else
            {
                return nullptr;
            }
        case 0b0000011:
            if (funct3 == 0)
            {
                return new rv32i::LB(rd, rs1, immI);
            }
            else if (funct3 == 1)
            {
                return new rv32i::LH(rd, rs1, immI);
            }
            else if (funct3 == 2)
            {
                return new rv32i::LW(rd, rs1, immI);
            }
            else if (funct3 == 4)
            {
                return new rv32i::LBU(rd, rs1, immI);
            }
            else if (funct3 == 5)
            {
                return new rv32i::LHU(rd, rs1, immI);
            }
            else
            {
                return nullptr;
            }
        case 0b0100011:
            if (funct3 == 0)
            {
                return new rv32i::SB(rs1, rs2, immI);
            }
            else if (funct3 == 1)
            {
                return new rv32i::SH(rs1, rs2, immI);
            }
            else if (funct3 == 2)
            {
                return new rv32i::SW(rs1, rs2, immI);
            }
            else
            {
                return nullptr;
            }
        case 0b0010011:
            if (funct3 == 0)
            {
                return new rv32i::ADDI(rd, rs1, immI);
            }
            else if (funct3 == 2)
            {
                return new rv32i::SLTI(rd, rs1, immI);
            }
            else if (funct3 == 3)
            {
                return new rv32i::SLTIU(rd, rs1, immI);
            }
            else if (funct3 == 4)
            {
                return new rv32i::XORI(rd, rs1, immI);
            }
            else if (funct3 == 6)
            {
                return new rv32i::ORI(rd, rs1, immI);
            }
            else if (funct3 == 7)
            {
                return new rv32i::ANDI(rd, rs1, immI);
            }
            else if (funct3 == 1 && funct7 == 0b0000000)
            {
                return new rv32i::SLLI(rd, rs1, shamt);
            }
            else if (funct3 == 5 && funct7 == 0b0000000)
            {
                return new rv32i::SRLI(rd, rs1, shamt);
            }
            else if (funct3 == 5 && funct7 == 0b0100000)
            {
                return new rv32i::SRAI(rd, rs1, shamt);
            }
            else
            {
                return nullptr;
            }
        case 0b0110011:
            if (funct7 == 0b0000000)
            {
                if (funct3 == 0)
                {
                    return new rv32i::ADD(rd, rs1, rs2);
                }
                else if (funct3 == 1)
                {
                    return new rv32i::SLL(rd, rs1, rs2);
                }
                else if (funct3 == 2)
                {
                    return new rv32i::SLT(rd, rs1, rs2);
                }
                else if (funct3 == 3)
                {
                    return new rv32i::SLTU(rd, rs1, rs2);
                }
                else if (funct3 == 4)
                {
                    return new rv32i::XOR(rd, rs1, rs2);
                }
                else if (funct3 == 5)
                {
                    return new rv32i::SRL(rd, rs1, rs2);
                }
                else if (funct3 == 6)
                {
                    return new rv32i::OR(rd, rs1, rs2);
                }
                else if (funct3 == 7)
                {
                    return new rv32i::AND(rd, rs1, rs2);
                }
                else
                {
                    return nullptr;
                }
            }
            else if (funct7 == 0b0100000)
            {
                if (funct3 == 0)
                {
                    return new rv32i::SUB(rd, rs1, rs2);
                }
                else if (funct3 == 5)
                {
                    return new rv32i::SRA(rd, rs1, rs2);
                }
                else
                {
                    return nullptr;
                }
            }
            else
            {
                return nullptr;
            }
        case 0b0001111:
            if (funct3 == 0 && rd == 0 && rs1 == 0 && Pick(insn, 28, 4) == 0)
            {
                const auto fm = Pick(insn, 28, 4);
                const auto pred = Pick(insn, 24, 4);
                const auto succ = Pick(insn, 20, 4);

                return new rv32i::FENCE(rd, rs1, fm, pred, succ);
            }
            else if (funct3 == 1 && rd == 0 && rs1 == 0 && funct12 == 0)
            {
                return new rv32i::FENCE_I(rd, rs1, immI);
            }
            else
            {
                return nullptr;
            }
        case 0b1110011:
            if (funct3 == 0 && rd == 0 && funct7 == 0b0001001)
            {
                return new rv32i::SFENCE_VMA(rs1, rs2);
            }
            else if (funct3 == 0 && rd == 0 && rs1 == 0)
            {
                switch (funct12)
                {
                case 0b000000000000:
                    return new rv32i::ECALL();
                case 0b000000000001:
                    return new rv32i::EBREAK();
                case 0b000000000010:
                    return new rv32i::URET();
                case 0b000100000010:
                    return new rv32i::SRET();
                case 0b000100000101:
                    return new rv32i::WFI();
                case 0b001100000010:
                    return new rv32i::MRET();
                default:
                    return nullptr;
                }
            }
            else if (funct3 == 1)
            {
                return new rv32i::CSRRW(csr, rd, rs1);
            }
            else if (funct3 == 2)
            {
                return new rv32i::CSRRS(csr, rd, rs1);
            }
            else if (funct3 == 3)
            {
                return new rv32i::CSRRC(csr, rd, rs1);
            }
            else if (funct3 == 5)
            {
                return new rv32i::CSRRWI(csr, rd, rs1);
            }
            else if (funct3 == 6)
            {
                return new rv32i::CSRRSI(csr, rd, rs1);
            }
            else if (funct3 == 7)
            {
                return new rv32i::CSRRCI(csr, rd, rs1);
            }
            else
            {
                return nullptr;
            }
        default:
            return nullptr;
        }
    }

private:
    XLEN m_XLEN;
};

OpDecoder::OpDecoder(XLEN xlen)
{
    m_pImpl = new OpDecoderImpl(xlen);
}

OpDecoder::~OpDecoder()
{
    delete m_pImpl;
}

std::unique_ptr<IOp> OpDecoder::Decode(uint32_t insn) const
{
    return std::unique_ptr<IOp>(m_pImpl->Decode(insn));
}

}
