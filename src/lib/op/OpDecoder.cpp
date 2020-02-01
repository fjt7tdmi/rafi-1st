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
        // TODO: impl RV64IMADC
        switch (m_XLEN)
        {
        case XLEN::XLEN32:
            return DecodeRV32(insn);
        case XLEN::XLEN64:
            return DecodeRV64(insn);
        default:
            RAFI_NOT_IMPLEMENTED;
        }
    }

    bool IsCompressedInstruction(uint32_t insn) const
    {
        return (insn & 0b11) != 0b11;
    }

private:
    IOp* DecodeRV32(uint32_t insn) const
    {
        const auto opcode = Pick(insn, 0, 7);
        const auto funct3 = Pick(insn, 12, 3);
        const auto funct7 = Pick(insn, 25, 7);
        const auto funct2 = Pick(insn, 25, 2);

        if (IsCompressedInstruction(insn))
        {
            return DecodeRV32C(static_cast<uint16_t>(insn));
        }
        else if (opcode == 0b0110011 && funct7 == 0b0000001)
        {
            return DecodeRV32M(insn);
        }
        else if (opcode == 0b0101111 && funct3 == 0b010)
        {
            return DecodeRV32A(insn);
        }
        else if ((opcode == 0b0000111 && funct3 == 0b010) ||
                (opcode == 0b0100111 && funct3 == 0b010) ||
                (opcode == 0b1000011 && funct2 == 0b00) ||
                (opcode == 0b1000111 && funct2 == 0b00) ||
                (opcode == 0b1001011 && funct2 == 0b00) ||
                (opcode == 0b1001111 && funct2 == 0b00) ||
                (opcode == 0b1010011 && funct2 == 0b00 && !(funct7 == 0b0100000)))
        {
            return DecodeRV32F(insn);
        }
        else if ((opcode == 0b0000111 && funct3 == 0b011) ||
                (opcode == 0b0100111 && funct3 == 0b011) ||
                (opcode == 0b1000011 && funct2 == 0b01) ||
                (opcode == 0b1000111 && funct2 == 0b01) ||
                (opcode == 0b1001011 && funct2 == 0b01) ||
                (opcode == 0b1001111 && funct2 == 0b01) ||
                (opcode == 0b1010011 && funct2 == 0b01) ||
                (opcode == 0b1010011 && funct7 == 0b0100000))
        {
            return DecodeRV32D(insn);
        }
        else
        {
            return DecodeRV32I(insn);
        }
    }

    IOp* DecodeRV64(uint32_t insn) const
    {
        const auto opcode = Pick(insn, 0, 7);
        const auto funct3 = Pick(insn, 12, 3);
        const auto funct7 = Pick(insn, 25, 7);
        const auto funct2 = Pick(insn, 25, 2);

        if (IsCompressedInstruction(insn))
        {
            return DecodeRV64C(static_cast<uint16_t>(insn));
        }
        else if ((opcode == 0b0110011 && funct7 == 0b0000001) ||
                (opcode == 0b0111011 && funct7 == 0b0000001))
        {
            return DecodeRV64M(insn);
        }
        else if ((opcode == 0b0101111 && funct3 == 0b010) ||
                (opcode == 0b0101111 && funct3 == 0b011))
        {
            return DecodeRV64A(insn);
        }
        else if ((opcode == 0b0000111 && funct3 == 0b010) ||
                (opcode == 0b0100111 && funct3 == 0b010) ||
                (opcode == 0b1000011 && funct2 == 0b00) ||
                (opcode == 0b1000111 && funct2 == 0b00) ||
                (opcode == 0b1001011 && funct2 == 0b00) ||
                (opcode == 0b1001111 && funct2 == 0b00) ||
                (opcode == 0b1010011 && funct2 == 0b00 && !(funct7 == 0b0100000)))
        {
            return DecodeRV64F(insn);
        }
        else if ((opcode == 0b0000111 && funct3 == 0b011) ||
                (opcode == 0b0100111 && funct3 == 0b011) ||
                (opcode == 0b1000011 && funct2 == 0b01) ||
                (opcode == 0b1000111 && funct2 == 0b01) ||
                (opcode == 0b1001011 && funct2 == 0b01) ||
                (opcode == 0b1001111 && funct2 == 0b01) ||
                (opcode == 0b1010011 && funct2 == 0b01) ||
                (opcode == 0b1010011 && funct7 == 0b0100000))
        {
            return DecodeRV64D(insn);
        }
        else
        {
            return DecodeRV64I(insn);
        }
    }

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
        const auto immI = SignExtend(12,
            Pick(insn, 20, 12));
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
            return new op32::LUI(rd, immU);
        case 0b0010111:
            return new op32::AUIPC(rd, immU);
        case 0b1101111:
            return new op32::JAL(rd, SignExtend(20,
                Pick(insn, 31, 1) << 20 |
                Pick(insn, 21, 10) << 1 |
                Pick(insn, 20, 1) << 11 |
                Pick(insn, 12, 8) << 12));
        case 0b1100111:
            if (funct3 == 0)
            {
                return new op32::JALR(rd, rs1, immI);
            }
            else
            {
                return nullptr;
            }
        case 0b1100011:
            if (funct3 == 0)
            {
                return new op32::BEQ(rs1, rs2, immB);
            }
            else if (funct3 == 1)
            {
                return new op32::BNE(rs1, rs2, immB);
            }
            else if (funct3 == 4)
            {
                return new op32::BLT(rs1, rs2, immB);
            }
            else if (funct3 == 5)
            {
                return new op32::BGE(rs1, rs2, immB);
            }
            else if (funct3 == 6)
            {
                return new op32::BLTU(rs1, rs2, immB);
            }
            else if (funct3 == 7)
            {
                return new op32::BGEU(rs1, rs2, immB);
            }
            else
            {
                return nullptr;
            }
        case 0b0000011:
            if (funct3 == 0)
            {
                return new op32::LB(rd, rs1, immI);
            }
            else if (funct3 == 1)
            {
                return new op32::LH(rd, rs1, immI);
            }
            else if (funct3 == 2)
            {
                return new op32::LW(rd, rs1, immI);
            }
            else if (funct3 == 4)
            {
                return new op32::LBU(rd, rs1, immI);
            }
            else if (funct3 == 5)
            {
                return new op32::LHU(rd, rs1, immI);
            }
            else
            {
                return nullptr;
            }
        case 0b0100011:
            if (funct3 == 0)
            {
                return new op32::SB(rs1, rs2, immI);
            }
            else if (funct3 == 1)
            {
                return new op32::SH(rs1, rs2, immI);
            }
            else if (funct3 == 2)
            {
                return new op32::SW(rs1, rs2, immI);
            }
            else
            {
                return nullptr;
            }
        case 0b0010011:
            if (funct3 == 0)
            {
                return new op32::ADDI(rd, rs1, immI);
            }
            else if (funct3 == 2)
            {
                return new op32::SLTI(rd, rs1, immI);
            }
            else if (funct3 == 3)
            {
                return new op32::SLTIU(rd, rs1, immI);
            }
            else if (funct3 == 4)
            {
                return new op32::XORI(rd, rs1, immI);
            }
            else if (funct3 == 6)
            {
                return new op32::ORI(rd, rs1, immI);
            }
            else if (funct3 == 7)
            {
                return new op32::ANDI(rd, rs1, immI);
            }
            else if (funct3 == 1 && funct7 == 0b0000000)
            {
                return new op32::SLLI(rd, rs1, shamt);
            }
            else if (funct3 == 5 && funct7 == 0b0000000)
            {
                return new op32::SRLI(rd, rs1, shamt);
            }
            else if (funct3 == 5 && funct7 == 0b0100000)
            {
                return new op32::SRAI(rd, rs1, shamt);
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
                    return new op32::ADD(rd, rs1, rs2);
                }
                else if (funct3 == 1)
                {
                    return new op32::SLL(rd, rs1, rs2);
                }
                else if (funct3 == 2)
                {
                    return new op32::SLT(rd, rs1, rs2);
                }
                else if (funct3 == 3)
                {
                    return new op32::SLTU(rd, rs1, rs2);
                }
                else if (funct3 == 4)
                {
                    return new op32::XOR(rd, rs1, rs2);
                }
                else if (funct3 == 5)
                {
                    return new op32::SRL(rd, rs1, rs2);
                }
                else if (funct3 == 6)
                {
                    return new op32::OR(rd, rs1, rs2);
                }
                else if (funct3 == 7)
                {
                    return new op32::AND(rd, rs1, rs2);
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
                    return new op32::SUB(rd, rs1, rs2);
                }
                else if (funct3 == 5)
                {
                    return new op32::SRA(rd, rs1, rs2);
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

                return new op32::FENCE(rd, rs1, fm, pred, succ);
            }
            else if (funct3 == 1 && rd == 0 && rs1 == 0 && funct12 == 0)
            {
                return new op32::FENCE_I(rd, rs1, immI);
            }
            else
            {
                return nullptr;
            }
        case 0b1110011:
            if (funct3 == 0 && rd == 0 && funct7 == 0b0001001)
            {
                return new op32::SFENCE_VMA(rs1, rs2);
            }
            else if (funct3 == 0 && rd == 0 && rs1 == 0)
            {
                switch (funct12)
                {
                case 0b000000000000:
                    return new op32::ECALL();
                case 0b000000000001:
                    return new op32::EBREAK();
                case 0b000000000010:
                    return new op32::URET();
                case 0b000100000010:
                    return new op32::SRET();
                case 0b000100000101:
                    return new op32::WFI();
                case 0b001100000010:
                    return new op32::MRET();
                default:
                    return nullptr;
                }
            }
            else if (funct3 == 1)
            {
                return new op32::CSRRW(csr, rd, rs1);
            }
            else if (funct3 == 2)
            {
                return new op32::CSRRS(csr, rd, rs1);
            }
            else if (funct3 == 3)
            {
                return new op32::CSRRC(csr, rd, rs1);
            }
            else if (funct3 == 5)
            {
                return new op32::CSRRWI(csr, rd, rs1);
            }
            else if (funct3 == 6)
            {
                return new op32::CSRRSI(csr, rd, rs1);
            }
            else if (funct3 == 7)
            {
                return new op32::CSRRCI(csr, rd, rs1);
            }
            else
            {
                return nullptr;
            }
        default:
            return nullptr;
        }
    }

    IOp* DecodeRV32M(uint32_t insn) const
    {
        const auto funct3 = Pick(insn, 12, 3);
        const auto rd = static_cast<int>(Pick(insn, 7, 5));
        const auto rs1 = static_cast<int>(Pick(insn, 15, 5));
        const auto rs2 = static_cast<int>(Pick(insn, 20, 5));

        switch (funct3)
        {
        case 0b000:
            return new op32::MUL(rd, rs1, rs2);
        case 0b001:
            return new op32::MULH(rd, rs1, rs2);
        case 0b010:
            return new op32::MULHSU(rd, rs1, rs2);
        case 0b011:
            return new op32::MULHU(rd, rs1, rs2);
        case 0b100:
            return new op32::DIV(rd, rs1, rs2);
        case 0b101:
            return new op32::DIVU(rd, rs1, rs2);
        case 0b110:
            return new op32::REM(rd, rs1, rs2);
        default:
            return new op32::REMU(rd, rs1, rs2);
        }
    }

    IOp* DecodeRV32A(uint32_t insn) const
    {
        const auto funct5 = Pick(insn, 27, 5);
        const auto aq = static_cast<bool>(Pick(insn, 26));
        const auto rl = static_cast<bool>(Pick(insn, 25));

        const auto rd = static_cast<int>(Pick(insn, 7, 5));
        const auto rs1 = static_cast<int>(Pick(insn, 15, 5));
        const auto rs2 = static_cast<int>(Pick(insn, 20, 5));

        if (funct5 == 0b00010 && rs2 == 0b00000)
        {
            return new op32::LR_W(rd, rs1, aq, rl);
        }
        else if (funct5 == 0b00011)
        {
            return new op32::SC_W(rd, rs1, rs2, aq, rl);
        }
        else if (funct5 == 0b00001)
        {
            return new op32::AMOSWAP_W(rd, rs1, rs2, aq, rl);
        }
        else if (funct5 == 0b00000)
        {
            return new op32::AMOADD_W(rd, rs1, rs2, aq, rl);
        }
        else if (funct5 == 0b00100)
        {
            return new op32::AMOXOR_W(rd, rs1, rs2, aq, rl);
        }
        else if (funct5 == 0b01100)
        {
            return new op32::AMOAND_W(rd, rs1, rs2, aq, rl);
        }
        else if (funct5 == 0b01000)
        {
            return new op32::AMOOR_W(rd, rs1, rs2, aq, rl);
        }
        else if (funct5 == 0b10000)
        {
            return new op32::AMOMIN_W(rd, rs1, rs2, aq, rl);
        }
        else if (funct5 == 0b10100)
        {
            return new op32::AMOMAX_W(rd, rs1, rs2, aq, rl);
        }
        else if (funct5 == 0b11000)
        {
            return new op32::AMOMINU_W(rd, rs1, rs2, aq, rl);
        }
        else if (funct5 == 0b11100)
        {
            return new op32::AMOMAXU_W(rd, rs1, rs2, aq, rl);
        }
        else
        {
            return nullptr;
        }
    }

    IOp* DecodeRV32F(uint32_t insn) const
    {
        const auto opcode = Pick(insn, 0, 7);
        const auto funct3 = Pick(insn, 12, 3);
        const auto funct7 = Pick(insn, 25, 7);
        const auto funct2 = Pick(insn, 25, 2);
        const auto rd = Pick(insn, 7, 5);
        const auto rs1 = Pick(insn, 15, 5);
        const auto rs2 = Pick(insn, 20, 5);
        const auto rs3 = Pick(insn, 27, 5);
        const auto rm = Pick(insn, 12, 3);

        const auto immI = SignExtend(12,
            Pick(insn, 20, 12));
        const auto immS = SignExtend(12,
            Pick(insn, 25, 7) << 5 |
            Pick(insn, 7, 5));

        switch (opcode)
        {
        case 0b0000111:
            switch (funct3)
            {
            case 0b010:
                return new op32::FLW(rd, rs1, immI);
            default:
                return nullptr;
            }
        case 0b0100111:
            switch (funct3)
            {
            case 0b010:
                return new op32::FSW(rd, rs1, immS);
            default:
                return nullptr;
            }
        case 0b1000011:
            return new op32::FMADD_S(rd, rs1, rs2, rs3, rm);
        case 0b1000111:
            return new op32::FMSUB_S(rd, rs1, rs2, rs3, rm);
        case 0b1001011:
            return new op32::FNMSUB_S(rd, rs1, rs2, rs3, rm);
        case 0b1001111:
            return new op32::FNMADD_S(rd, rs1, rs2, rs3, rm);
        case 0b1010011:
            switch (funct7)
            {
            case 0b0000000:
                return new op32::FADD_S(rd, rs1, rs2, rm);
            case 0b0000100:
                return new op32::FSUB_S(rd, rs1, rs2, rm);
            case 0b0001000:
                return new op32::FMUL_S(rd, rs1, rs2, rm);
            case 0b0001100:
                return new op32::FDIV_S(rd, rs1, rs2, rm);
            case 0b0101100:
                switch (rs2)
                {
                case 0b00000:
                    return new op32::FSQRT_S(rd, rs1, rm);
                default:
                    return nullptr;
                }
            case 0b0010000:
                switch (funct3)
                {
                case 0b000:
                    return new op32::FSGNJ_S(rd, rs1, rs2);
                case 0b001:
                    return new op32::FSGNJN_S(rd, rs1, rs2);
                case 0b010:
                    return new op32::FSGNJX_S(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b0010100:
                switch (funct3)
                {
                case 0b000:
                    return new op32::FMIN_S(rd, rs1, rs2);
                case 0b001:
                    return new op32::FMAX_S(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1100000:
                switch (rs2)
                {
                case 0b00000:
                    return new op32::FCVT_W_S(rd, rs1, rs2);
                case 0b00001:
                    return new op32::FCVT_WU_S(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1110000:
                if (rs2 == 0b00000 && funct3 == 0b000)
                {
                    return new op32::FMV_X_W(rd, rs1);
                }
                else if (rs2 == 0b00000 && funct3 == 0b001)
                {
                    return new op32::FCLASS_S(rd, rs1);
                }
                else
                {
                    return nullptr;
                }
            case 0b1010000:
                switch (funct3)
                {
                case 0b000:
                    return new op32::FLE_S(rd, rs1, rs2);
                case 0b001:
                    return new op32::FLT_S(rd, rs1, rs2);
                case 0b010:
                    return new op32::FEQ_S(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1101000:
                switch (rs2)
                {
                case 0b00000:
                    return new op32::FCVT_S_W(rd, rs1, rs2);
                case 0b00001:
                    return new op32::FCVT_S_WU(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1111000:
                if (rs2 == 0b00000 && funct3 == 0b000)
                {
                    return new op32::FMV_W_X(rd, rs1);
                }
                else
                {
                    return nullptr;
                }
            default:
                return nullptr;
            }
        default:
            return nullptr;
        }
    }

    IOp* DecodeRV32D(uint32_t insn) const
    {
        const auto opcode = Pick(insn, 0, 7);
        const auto funct3 = Pick(insn, 12, 3);
        const auto funct7 = Pick(insn, 25, 7);
        const auto funct2 = Pick(insn, 25, 2);
        const auto rd = Pick(insn, 7, 5);
        const auto rs1 = Pick(insn, 15, 5);
        const auto rs2 = Pick(insn, 20, 5);
        const auto rs3 = Pick(insn, 27, 5);
        const auto rm = Pick(insn, 12, 3);

        const auto immI = SignExtend(12,
            Pick(insn, 20, 12));
        const auto immS = SignExtend(12,
            Pick(insn, 25, 7) << 5 |
            Pick(insn, 7, 5));

        switch (opcode)
        {
        case 0b0000111:
            switch (funct3)
            {
            case 0b011:
                return new op32::FLD(rd, rs1, immI);
            default:
                return nullptr;
            }
        case 0b0100111:
            switch (funct3)
            {
            case 0b011:
                return new op32::FSD(rd, rs1, immS);
            default:
                return nullptr;
            }
        case 0b1000011:
            return new op32::FMADD_D(rd, rs1, rs2, rs3, rm);
        case 0b1000111:
            return new op32::FMSUB_D(rd, rs1, rs2, rs3, rm);
        case 0b1001011:
            return new op32::FNMSUB_D(rd, rs1, rs2, rs3, rm);
        case 0b1001111:
            return new op32::FNMADD_D(rd, rs1, rs2, rs3, rm);
        case 0b1010011:
            switch (funct7)
            {
            case 0b0000001:
                return new op32::FADD_D(rd, rs1, rs2, rm);
            case 0b0000101:
                return new op32::FSUB_D(rd, rs1, rs2, rm);
            case 0b0001001:
                return new op32::FMUL_D(rd, rs1, rs2, rm);
            case 0b0001101:
                return new op32::FDIV_D(rd, rs1, rs2, rm);
            case 0b0101101:
                switch (rs2)
                {
                case 0b00000:
                    return new op32::FSQRT_D(rd, rs1, rm);
                default:
                    return nullptr;
                }
            case 0b0010001:
                switch (funct3)
                {
                case 0b000:
                    return new op32::FSGNJ_D(rd, rs1, rs2);
                case 0b001:
                    return new op32::FSGNJN_D(rd, rs1, rs2);
                case 0b010:
                    return new op32::FSGNJX_D(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b0010101:
                switch (funct3)
                {
                case 0b000:
                    return new op32::FMIN_D(rd, rs1, rs2);
                case 0b001:
                    return new op32::FMAX_D(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b0100000:
                switch (rs2)
                {
                case 0b00001:
                    return new op32::FCVT_S_D(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b0100001:
                switch (rs2)
                {
                case 0b00000:
                    return new op32::FCVT_D_S(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1010001:
                switch (funct3)
                {
                case 0b000:
                    return new op32::FLE_D(rd, rs1, rs2);
                case 0b001:
                    return new op32::FLT_D(rd, rs1, rs2);
                case 0b010:
                    return new op32::FEQ_D(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1110001:
                if (rs2 == 0b00000 && funct3 == 0b001)
                {
                    return new op32::FCLASS_D(rd, rs1);
                }
                else
                {
                    return nullptr;
                }
            case 0b1100001:
                switch (rs2)
                {
                case 0b00000:
                    return new op32::FCVT_W_D(rd, rs1, rs2);
                case 0b00001:
                    return new op32::FCVT_WU_D(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1101001:
                switch (rs2)
                {
                case 0b00000:
                    return new op32::FCVT_D_W(rd, rs1, rs2);
                case 0b00001:
                    return new op32::FCVT_D_WU(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            default:
                return nullptr;
            }
        default:
            return nullptr;
        }
    }

    IOp* DecodeRV32C(uint16_t insn) const
    {
        const auto opcode = Pick(insn, 0, 2);

        switch (opcode)
        {
        case 0b00:
            return DecodeRV32C_Quadrant0(insn);
        case 0b01:
            return DecodeRV32C_Quadrant1(insn);
        case 0b10:
            return DecodeRV32C_Quadrant2(insn);
        default:
            return nullptr;
        }
    }

    IOp* DecodeRV32C_Quadrant0(uint16_t insn) const
    {
        const auto funct3 = Pick(insn, 13, 3);

        const auto rd = Pick(insn, 2, 3) + 8;
        const auto rs1 = Pick(insn, 7, 3) + 8;
        const auto rs2 = Pick(insn, 2, 3) + 8;

        const auto uimm4 = ZeroExtend(7,
            Pick(insn, 10, 3) << 3 |
            Pick(insn, 6) << 2 |
            Pick(insn, 5) << 6);
        const auto uimm8 = ZeroExtend(8,
            Pick(insn, 10, 3) << 3 |
            Pick(insn, 5, 2) << 6);

        if (funct3 == 0b000 && Pick(insn, 5, 8) != 0)
        {
            const auto imm = ZeroExtend(10,
                Pick(insn, 11, 2) << 4 |
                Pick(insn, 7, 4) << 6 |
                Pick(insn, 6) << 2 |
                Pick(insn, 5) << 3);
            
            // C.ADDI4SPN
            return new op32::ADDI(2, 2, imm);
        }
        else if (funct3 == 0b001)
        {
            // C.FLD
            return new op32::FLD(rd, rs1, uimm8);
        }
        else if (funct3 == 0b010)
        {
            // C.LW
            return new op32::LW(rd, rs1, uimm4);
        }
        else if (funct3 == 0b011)
        {
            // C.FLW
            return new op32::FLW(rd, rs1, uimm4);
        }
        else if (funct3 == 0b101)
        {
            // C.FSD
            return new op32::FSD(rd, rs1, uimm8);
        }
        else if (funct3 == 0b110)
        {
            // C.SW
            return new op32::SW(rd, rs1, uimm4);
        }
        else if (funct3 == 0b111)
        {
            // C.FSW
            return new op32::FSW(rd, rs1, uimm4);
        }
        else
        {
            return nullptr;
        }
    }

    IOp* DecodeRV32C_Quadrant1(uint16_t insn) const
    {
        const auto funct4 = Pick(insn, 12, 4);
        const auto funct3 = Pick(insn, 13, 3);
        const auto funct2_rs1 = Pick(insn, 10, 2);
        const auto funct2_rs2 = Pick(insn, 5, 2);

        const auto rd = Pick(insn, 7, 5);
        const auto rs1 = Pick(insn, 7, 5);
        const auto rd_alu = Pick(insn, 7, 3) + 8;
        const auto rs1_alu = Pick(insn, 7, 3) + 8;
        const auto rs2_alu = Pick(insn, 2, 3) + 8;

        const auto imm = SignExtend(6,
            Pick(insn, 12, 1) << 5 |
            Pick(insn, 2, 5));
        const auto uimm = SignExtend(6,
            Pick(insn, 12, 1) << 5 |
            Pick(insn, 2, 5));
        const auto imm_j = SignExtend(12,
            Pick(insn, 12, 1) << 11 |
            Pick(insn, 11, 1) << 4 |
            Pick(insn, 9, 2) << 8 |
            Pick(insn, 8, 1) << 10 |
            Pick(insn, 7, 1) << 6 |
            Pick(insn, 6, 1) << 7 |
            Pick(insn, 3, 3) << 1 |
            Pick(insn, 2, 1) << 5);
        const auto imm_addi16sp = SignExtend(10,
            Pick(insn, 12) << 9 |
            Pick(insn, 6) << 4 |
            Pick(insn, 5) << 6 |
            Pick(insn, 3, 2) << 7 |
            Pick(insn, 2) << 5);
        const auto imm_lui = SignExtend(18,
            Pick(insn, 12) << 17 |
            Pick(insn, 2, 5) << 12);
        const auto imm_b = SignExtend(9,
            Pick(insn, 12, 1) << 8 |
            Pick(insn, 10, 2) << 3 |
            Pick(insn, 5, 2) << 6 |
            Pick(insn, 3, 2) << 1 |
            Pick(insn, 2, 1) << 5);

        if (funct3 == 0b000 && rd == 0)
        {            
            return new op32::NOP();
        }
        else if (funct3 == 0b000)
        {
            // C.ADDI
            return new op32::ADDI(rd, rs1, imm);
        }
        else if (funct3 == 0b001)
        {
            // C.JAL
            return new op32::JAL(1, imm_j);
        }
        else if (funct3 == 0b010 && rd != 0)
        {
            // C.LI
            return new op32::ADDI(rd, 0, imm);
        }
        else if (funct3 == 0b011 && rd == 2)
        {
            // C.ADDI16SP
            return new op32::ADDI(2, 2, imm_addi16sp);
        }
        else if (funct3 == 0b011 && rd != 0 && rd != 2)
        {
            // C.LUI
            return new op32::LUI(rd, imm_lui);
        }
        else if (funct3 == 0b100 && funct2_rs1 == 0b00 && uimm != 0)
        {
            // C.SRLI
            return new op32::SRLI(rd_alu, rs1_alu, uimm);
        }
        else if (funct3 == 0b100 && funct2_rs1 == 0b00 && uimm == 0)
        {
            // C.SRLI64
            return new op32::NOP();
        }
        else if (funct3 == 0b100 && funct2_rs1 == 0b01 && uimm != 0)
        {
            // C.SRAI
            return new op32::SRAI(rd_alu, rs1_alu, uimm);
        }
        else if (funct3 == 0b100 && funct2_rs1 == 0b01 && uimm == 0)
        {
            // C.SRAI64
            return new op32::NOP();
        }
        else if (funct3 == 0b100 && funct2_rs1 == 0b10)
        {
            // C.ANDI
            return new op32::ANDI(rd_alu, rs1_alu, imm);
        }
        else if (funct4 == 0b1000 && funct2_rs1 == 0b11 && funct2_rs2 == 0b00)
        {
            // C.SUB
            return new op32::SUB(rd_alu, rs1_alu, rs2_alu);
        }
        else if (funct4 == 0b1000 && funct2_rs1 == 0b11 && funct2_rs2 == 0b01)
        {
            // C.XOR
            return new op32::XOR(rd_alu, rs1_alu, rs2_alu);
        }
        else if (funct4 == 0b1000 && funct2_rs1 == 0b11 && funct2_rs2 == 0b10)
        {
            // C.OR
            return new op32::OR(rd_alu, rs1_alu, rs2_alu);
        }
        else if (funct4 == 0b1000 && funct2_rs1 == 0b11 && funct2_rs2 == 0b11)
        {
            // C.AND
            return new op32::AND(rd_alu, rs1_alu, rs2_alu);
        }
        else if (funct3 == 0b101)
        {
            // C.J
            return new op32::JAL(0, imm_j);
        }
        else if (funct3 == 0b110)
        {
            // C.BEQZ
            return new op32::BEQ(rs1_alu, 0, imm_b);
        }
        else if (funct3 == 0b111)
        {
            // C.BNEZ
            return new op32::BNE(rs1_alu, 0, imm_b);
        }
        else
        {
            return nullptr;
        }
    }

    IOp* DecodeRV32C_Quadrant2(uint16_t insn) const
    {
        const auto funct4 = Pick(insn, 12, 4);
        const auto funct3 = Pick(insn, 13, 3);
        const auto rd = Pick(insn, 7, 5);
        const auto rs1 = Pick(insn, 7, 5);
        const auto rs2 = Pick(insn, 2, 5);

        const auto shamt = ZeroExtend(6,
            Pick(insn, 12, 1) << 5 |
            Pick(insn, 2, 5));
        const auto uimm_load4 = ZeroExtend(8,
            Pick(insn, 12) << 5 |
            Pick(insn, 4, 3) << 2 |
            Pick(insn, 2, 2) << 6);
        const auto uimm_load8 = ZeroExtend(9,
            Pick(insn, 12) << 5 |
            Pick(insn, 5, 2) << 3 |
            Pick(insn, 2, 3) << 6);
        const auto uimm_store4 = ZeroExtend(8,
            Pick(insn, 9, 4) << 2 |
            Pick(insn, 7, 2) << 6);
        const auto uimm_store8 = ZeroExtend(9,
            Pick(insn, 10, 3) << 3 |
            Pick(insn, 7, 3) << 6);

        if (funct3 == 0b000 && shamt != 0)
        {
            // C.SLLI
            return new op32::SLLI(rd, rs1, shamt);
        }
        else if (funct3 == 0b000 && shamt == 0)
        {
            // C.SLLI64
            return new op32::NOP();
        }
        else if (funct3 == 0b001)
        {
            // C.FLDSP
            return new op32::FLD(rd, 2, uimm_load8);
        }
        else if (funct3 == 0b010 && rd != 0)
        {
            // C.LWSP
            return new op32::LW(rd, 2, uimm_load4);
        }
        else if (funct3 == 0b011)
        {
            // C.FLWSP
            return new op32::FLW(rd, 2, uimm_load4);
        }
        else if (funct4 == 0b1000 && rs1 != 0 && rs2 == 0)
        {
            // C.JR
            return new op32::JALR(0, rs1, 0);
        }
        else if (funct4 == 0b1000 && rd != 0 && rs2 != 0)
        {
            // C.MV
            return new op32::ADD(rd, 0, rs2);
        }
        else if (funct4 == 0b1001 && rd == 0 && rs2 == 0)
        {
            // C.EBREAK
            return new op32::EBREAK();
        }
        else if (funct4 == 0b1001 && rs1 != 0 && rs2 == 0)
        {
            // C.JALR
            return new op32::JALR(1, rs1, 0);
        }
        else if (funct4 == 0b1001 && rd != 0 && rs2 != 0)
        {
            // C.ADD
            return new op32::ADD(rd, rs1, rs2);
        }
        else if (funct3 == 0b101)
        {
            // C.FSDSP
            return new op32::FSD(2, rs2, uimm_store8);
        }
        else if (funct3 == 0b110)
        {
            // C.SWSP
            return new op32::SW(2, rs2, uimm_store4);
        }
        else if (funct3 == 0b111)
        {
            // C.FSWSP
            return new op32::FSW(2, rs2, uimm_store4);
        }
        else
        {
            return nullptr;
        }
    }

    IOp* DecodeRV64I(uint32_t insn) const
    {
        const auto opcode = Pick(insn, 0, 7);
        const auto funct3 = Pick(insn, 12, 3);
        const auto funct7 = Pick(insn, 25, 7);
        const auto funct6 = Pick(insn, 26, 6);
        const auto funct12 = Pick(insn, 20, 12);
        const auto csr = Pick(insn, 20, 12);

        const auto rd = static_cast<int>(Pick(insn, 7, 5));
        const auto rs1 = static_cast<int>(Pick(insn, 15, 5));
        const auto rs2 = static_cast<int>(Pick(insn, 20, 5));
        const auto shamt5 = static_cast<int>(Pick(insn, 20, 5));
        const auto shamt6 = static_cast<int>(Pick(insn, 20, 6));

        const auto immU = Pick(insn, 12, 20);
        const auto immI = SignExtend(12,
            Pick(insn, 20, 12));
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
            return new op64::LUI(rd, immU);
        case 0b0010111:
            return new op64::AUIPC(rd, immU);
        case 0b1101111:
            return new op64::JAL(rd, SignExtend(20,
                Pick(insn, 31, 1) << 20 |
                Pick(insn, 21, 10) << 1 |
                Pick(insn, 20, 1) << 11 |
                Pick(insn, 12, 8) << 12));
        case 0b1100111:
            switch (funct3)
            {
            case 0:
                return new op64::JALR(rd, rs1, immI);
            default:
                return nullptr;
            }
        case 0b1100011:
            switch (funct3)
            {
            case 0:
                return new op64::BEQ(rs1, rs2, immB);
            case 1:
                return new op64::BNE(rs1, rs2, immB);
            case 4:
                return new op64::BLT(rs1, rs2, immB);
            case 5:
                return new op64::BGE(rs1, rs2, immB);
            case 6:
                return new op64::BLTU(rs1, rs2, immB);
            case 7:
                return new op64::BGEU(rs1, rs2, immB);
            default:
                return nullptr;
            }
        case 0b0000011:
            switch (funct3)
            {
            case 0:
                return new op64::LB(rd, rs1, immI);
            case 1:
                return new op64::LH(rd, rs1, immI);
            case 2:
                return new op64::LW(rd, rs1, immI);
            case 3:
                return new op64::LD(rd, rs1, immI);
            case 4:
                return new op64::LBU(rd, rs1, immI);
            case 5:
                return new op64::LHU(rd, rs1, immI);
            case 6:
                return new op64::LWU(rd, rs1, immI);
            default:
                return nullptr;
            }
        case 0b0100011:
            switch (funct3)
            {
            case 0:
                return new op64::SB(rs1, rs2, immI);
            case 1:
                return new op64::SH(rs1, rs2, immI);
            case 2:
                return new op64::SW(rs1, rs2, immI);
            case 3:
                return new op64::SD(rs1, rs2, immI);
            default:
                return nullptr;
            }
        case 0b0010011:
            if (funct3 == 0)
            {
                return new op64::ADDI(rd, rs1, immI);
            }
            else if (funct3 == 2)
            {
                return new op64::SLTI(rd, rs1, immI);
            }
            else if (funct3 == 3)
            {
                return new op64::SLTIU(rd, rs1, immI);
            }
            else if (funct3 == 4)
            {
                return new op64::XORI(rd, rs1, immI);
            }
            else if (funct3 == 6)
            {
                return new op64::ORI(rd, rs1, immI);
            }
            else if (funct3 == 7)
            {
                return new op64::ANDI(rd, rs1, immI);
            }
            else if (funct3 == 1 && funct6 == 0b000000)
            {
                return new op64::SLLI(rd, rs1, shamt6);
            }
            else if (funct3 == 5 && funct6 == 0b000000)
            {
                return new op64::SRLI(rd, rs1, shamt6);
            }
            else if (funct3 == 5 && funct6 == 0b010000)
            {
                return new op64::SRAI(rd, rs1, shamt6);
            }
            else
            {
                return nullptr;
            }
        case 0b0011011:
            if (funct3 == 0)
            {
                return new op64::ADDIW(rd, rs1, immI);
            }
            else if (funct3 == 1 && funct7 == 0b0000000)
            {
                return new op64::SLLI(rd, rs1, shamt5);
            }
            else if (funct3 == 5 && funct7 == 0b0000000)
            {
                return new op64::SRLI(rd, rs1, shamt5);
            }
            else if (funct3 == 5 && funct7 == 0b0100000)
            {
                return new op64::SRAI(rd, rs1, shamt5);
            }
            else
            {
                return nullptr;
            }
         case 0b0110011:
            if (funct7 == 0b0000000)
            {
                switch (funct3)
                {
                case 0:
                    return new op64::ADD(rd, rs1, rs2);
                case 1:
                    return new op64::SLL(rd, rs1, rs2);
                case 2:
                    return new op64::SLT(rd, rs1, rs2);
                case 3:
                    return new op64::SLTU(rd, rs1, rs2);
                case 4:
                    return new op64::XOR(rd, rs1, rs2);
                case 5:
                    return new op64::SRL(rd, rs1, rs2);
                case 6:
                    return new op64::OR(rd, rs1, rs2);
                case 7:
                    return new op64::AND(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            }
            else if (funct7 == 0b0100000)
            {
                switch (funct3)
                {
                case 0:
                    return new op64::SUB(rd, rs1, rs2);
                case 5:
                    return new op64::SRA(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            }
            else
            {
                return nullptr;
            }
        case 0b0111011:
            if (funct7 == 0b0000000)
            {
                switch (funct3)
                {
                case 0:
                    return new op64::ADDW(rd, rs1, rs2);
                case 1:
                    return new op64::SLLW(rd, rs1, rs2);
                case 5:
                    return new op64::SRLW(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            }
            else if (funct7 == 0b0100000)
            {
                switch (funct3)
                {
                case 0:
                    return new op64::SUBW(rd, rs1, rs2);
                case 5:
                    return new op64::SRAW(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            }
            else
            {
                return nullptr;
            }        case 0b0001111:
            if (funct3 == 0 && rd == 0 && rs1 == 0 && Pick(insn, 28, 4) == 0)
            {
                const auto fm = Pick(insn, 28, 4);
                const auto pred = Pick(insn, 24, 4);
                const auto succ = Pick(insn, 20, 4);

                return new op64::FENCE(rd, rs1, fm, pred, succ);
            }
            else if (funct3 == 1 && rd == 0 && rs1 == 0 && funct12 == 0)
            {
                return new op64::FENCE_I(rd, rs1, immI);
            }
            else
            {
                return nullptr;
            }
        case 0b1110011:
            if (funct3 == 0 && rd == 0 && funct7 == 0b0001001)
            {
                return new op64::SFENCE_VMA(rs1, rs2);
            }
            else if (funct3 == 0 && rd == 0 && rs1 == 0)
            {
                switch (funct12)
                {
                case 0b000000000000:
                    return new op64::ECALL();
                case 0b000000000001:
                    return new op64::EBREAK();
                case 0b000000000010:
                    return new op64::URET();
                case 0b000100000010:
                    return new op64::SRET();
                case 0b000100000101:
                    return new op64::WFI();
                case 0b001100000010:
                    return new op64::MRET();
                default:
                    return nullptr;
                }
            }
            else if (funct3 == 1)
            {
                return new op64::CSRRW(csr, rd, rs1);
            }
            else if (funct3 == 2)
            {
                return new op64::CSRRS(csr, rd, rs1);
            }
            else if (funct3 == 3)
            {
                return new op64::CSRRC(csr, rd, rs1);
            }
            else if (funct3 == 5)
            {
                return new op64::CSRRWI(csr, rd, rs1);
            }
            else if (funct3 == 6)
            {
                return new op64::CSRRSI(csr, rd, rs1);
            }
            else if (funct3 == 7)
            {
                return new op64::CSRRCI(csr, rd, rs1);
            }
            else
            {
                return nullptr;
            }
        default:
            return nullptr;
        }
    }

    IOp* DecodeRV64M(uint32_t insn) const
    {
        const auto opcode = Pick(insn, 0, 7);
        const auto funct3 = Pick(insn, 12, 3);
        const auto rd = static_cast<int>(Pick(insn, 7, 5));
        const auto rs1 = static_cast<int>(Pick(insn, 15, 5));
        const auto rs2 = static_cast<int>(Pick(insn, 20, 5));

        switch (opcode)
        {
        case 0b0110011:
            switch (funct3)
            {
            case 0b000:
                return new op64::MUL(rd, rs1, rs2);
            case 0b001:
                return new op64::MULH(rd, rs1, rs2);
            case 0b010:
                return new op64::MULHSU(rd, rs1, rs2);
            case 0b011:
                return new op64::MULHU(rd, rs1, rs2);
            case 0b100:
                return new op64::DIV(rd, rs1, rs2);
            case 0b101:
                return new op64::DIVU(rd, rs1, rs2);
            case 0b110:
                return new op64::REM(rd, rs1, rs2);
            default:
                return new op64::REMU(rd, rs1, rs2);
            }
        case 0b0111011:
            switch (funct3)
            {
            case 0b000:
                return new op64::MULW(rd, rs1, rs2);
            case 0b100:
                return new op64::DIVW(rd, rs1, rs2);
            case 0b101:
                return new op64::DIVUW(rd, rs1, rs2);
            case 0b110:
                return new op64::REMW(rd, rs1, rs2);
            case 0b111:
                return new op64::REMUW(rd, rs1, rs2);
            default:
                return nullptr;
            }        
        default:
            return nullptr;
        }
    }

    IOp* DecodeRV64A(uint32_t insn) const
    {
        const auto funct5 = Pick(insn, 27, 5);
        const auto funct3 = Pick(insn, 12, 3);
        const auto aq = static_cast<bool>(Pick(insn, 26));
        const auto rl = static_cast<bool>(Pick(insn, 25));

        const auto rd = static_cast<int>(Pick(insn, 7, 5));
        const auto rs1 = static_cast<int>(Pick(insn, 15, 5));
        const auto rs2 = static_cast<int>(Pick(insn, 20, 5));

        switch (funct3)
        {
        case 0b010:
            if (funct5 == 0b00010 && rs2 == 0b00000)
            {
                return new op64::LR_W(rd, rs1, aq, rl);
            }
            else if (funct5 == 0b00011)
            {
                return new op64::SC_W(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b00001)
            {
                return new op64::AMOSWAP_W(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b00000)
            {
                return new op64::AMOADD_W(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b00100)
            {
                return new op64::AMOXOR_W(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b01100)
            {
                return new op64::AMOAND_W(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b01000)
            {
                return new op64::AMOOR_W(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b10000)
            {
                return new op64::AMOMIN_W(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b10100)
            {
                return new op64::AMOMAX_W(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b11000)
            {
                return new op64::AMOMINU_W(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b11100)
            {
                return new op64::AMOMAXU_W(rd, rs1, rs2, aq, rl);
            }
            else
            {
                return nullptr;
            }
        case 0b011:
            if (funct5 == 0b00010 && rs2 == 0b00000)
            {
                return new op64::LR_D(rd, rs1, aq, rl);
            }
            else if (funct5 == 0b00011)
            {
                return new op64::SC_D(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b00001)
            {
                return new op64::AMOSWAP_D(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b00000)
            {
                return new op64::AMOADD_D(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b00100)
            {
                return new op64::AMOXOR_D(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b01100)
            {
                return new op64::AMOAND_D(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b01000)
            {
                return new op64::AMOOR_D(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b10000)
            {
                return new op64::AMOMIN_D(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b10100)
            {
                return new op64::AMOMAX_D(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b11000)
            {
                return new op64::AMOMINU_D(rd, rs1, rs2, aq, rl);
            }
            else if (funct5 == 0b11100)
            {
                return new op64::AMOMAXU_D(rd, rs1, rs2, aq, rl);
            }
            else
            {
                return nullptr;
            }
        default:
            return nullptr;
        }
    }

    IOp* DecodeRV64F(uint32_t insn) const
    {
        const auto opcode = Pick(insn, 0, 7);
        const auto funct3 = Pick(insn, 12, 3);
        const auto funct7 = Pick(insn, 25, 7);
        const auto funct2 = Pick(insn, 25, 2);
        const auto rd = Pick(insn, 7, 5);
        const auto rs1 = Pick(insn, 15, 5);
        const auto rs2 = Pick(insn, 20, 5);
        const auto rs3 = Pick(insn, 27, 5);
        const auto rm = Pick(insn, 12, 3);

        const auto immI = SignExtend(12,
            Pick(insn, 20, 12));
        const auto immS = SignExtend(12,
            Pick(insn, 25, 7) << 5 |
            Pick(insn, 7, 5));

        switch (opcode)
        {
        case 0b0000111:
            switch (funct3)
            {
            case 0b010:
                return new op64::FLW(rd, rs1, immI);
            default:
                return nullptr;
            }
        case 0b0100111:
            switch (funct3)
            {
            case 0b010:
                return new op64::FSW(rd, rs1, immS);
            default:
                return nullptr;
            }
        case 0b1000011:
            return new op64::FMADD_S(rd, rs1, rs2, rs3, rm);
        case 0b1000111:
            return new op64::FMSUB_S(rd, rs1, rs2, rs3, rm);
        case 0b1001011:
            return new op64::FNMSUB_S(rd, rs1, rs2, rs3, rm);
        case 0b1001111:
            return new op64::FNMADD_S(rd, rs1, rs2, rs3, rm);
        case 0b1010011:
            switch (funct7)
            {
            case 0b0000000:
                return new op64::FADD_S(rd, rs1, rs2, rm);
            case 0b0000100:
                return new op64::FSUB_S(rd, rs1, rs2, rm);
            case 0b0001000:
                return new op64::FMUL_S(rd, rs1, rs2, rm);
            case 0b0001100:
                return new op64::FDIV_S(rd, rs1, rs2, rm);
            case 0b0101100:
                switch (rs2)
                {
                case 0b00000:
                    return new op64::FSQRT_S(rd, rs1, rm);
                default:
                    return nullptr;
                }
            case 0b0010000:
                switch (funct3)
                {
                case 0b000:
                    return new op64::FSGNJ_S(rd, rs1, rs2);
                case 0b001:
                    return new op64::FSGNJN_S(rd, rs1, rs2);
                case 0b010:
                    return new op64::FSGNJX_S(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b0010100:
                switch (funct3)
                {
                case 0b000:
                    return new op64::FMIN_S(rd, rs1, rs2);
                case 0b001:
                    return new op64::FMAX_S(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1100000:
                switch (rs2)
                {
                case 0b00000:
                    return new op64::FCVT_W_S(rd, rs1, rs2);
                case 0b00001:
                    return new op64::FCVT_WU_S(rd, rs1, rs2);
                case 0b00010:
                    return new op64::FCVT_L_S(rd, rs1, rs2);
                case 0b00011:
                    return new op64::FCVT_LU_S(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1110000:
                if (rs2 == 0b00000 && funct3 == 0b000)
                {
                    return new op64::FMV_X_W(rd, rs1);
                }
                else if (rs2 == 0b00000 && funct3 == 0b001)
                {
                    return new op64::FCLASS_S(rd, rs1);
                }
                else
                {
                    return nullptr;
                }
            case 0b1010000:
                switch (funct3)
                {
                case 0b000:
                    return new op64::FLE_S(rd, rs1, rs2);
                case 0b001:
                    return new op64::FLT_S(rd, rs1, rs2);
                case 0b010:
                    return new op64::FEQ_S(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1101000:
                switch (rs2)
                {
                case 0b00000:
                    return new op64::FCVT_S_W(rd, rs1, rs2);
                case 0b00001:
                    return new op64::FCVT_S_WU(rd, rs1, rs2);
                case 0b00010:
                    return new op64::FCVT_S_L(rd, rs1, rs2);
                case 0b00011:
                    return new op64::FCVT_S_LU(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1111000:
                if (rs2 == 0b00000 && funct3 == 0b000)
                {
                    return new op64::FMV_W_X(rd, rs1);
                }
                else
                {
                    return nullptr;
                }
            default:
                return nullptr;
            }
        default:
            return nullptr;
        }
    }

    IOp* DecodeRV64D(uint32_t insn) const
    {
        const auto opcode = Pick(insn, 0, 7);
        const auto funct3 = Pick(insn, 12, 3);
        const auto funct7 = Pick(insn, 25, 7);
        const auto funct2 = Pick(insn, 25, 2);
        const auto rd = Pick(insn, 7, 5);
        const auto rs1 = Pick(insn, 15, 5);
        const auto rs2 = Pick(insn, 20, 5);
        const auto rs3 = Pick(insn, 27, 5);
        const auto rm = Pick(insn, 12, 3);

        const auto immI = SignExtend(12,
            Pick(insn, 20, 12));
        const auto immS = SignExtend(12,
            Pick(insn, 25, 7) << 5 |
            Pick(insn, 7, 5));

        switch (opcode)
        {
        case 0b0000111:
            switch (funct3)
            {
            case 0b011:
                return new op64::FLD(rd, rs1, immI);
            default:
                return nullptr;
            }
        case 0b0100111:
            switch (funct3)
            {
            case 0b011:
                return new op64::FSD(rd, rs1, immS);
            default:
                return nullptr;
            }
        case 0b1000011:
            return new op64::FMADD_D(rd, rs1, rs2, rs3, rm);
        case 0b1000111:
            return new op64::FMSUB_D(rd, rs1, rs2, rs3, rm);
        case 0b1001011:
            return new op64::FNMSUB_D(rd, rs1, rs2, rs3, rm);
        case 0b1001111:
            return new op64::FNMADD_D(rd, rs1, rs2, rs3, rm);
        case 0b1010011:
            switch (funct7)
            {
            case 0b0000001:
                return new op64::FADD_D(rd, rs1, rs2, rm);
            case 0b0000101:
                return new op64::FSUB_D(rd, rs1, rs2, rm);
            case 0b0001001:
                return new op64::FMUL_D(rd, rs1, rs2, rm);
            case 0b0001101:
                return new op64::FDIV_D(rd, rs1, rs2, rm);
            case 0b0101101:
                switch (rs2)
                {
                case 0b00000:
                    return new op64::FSQRT_D(rd, rs1, rm);
                default:
                    return nullptr;
                }
            case 0b0010001:
                switch (funct3)
                {
                case 0b000:
                    return new op64::FSGNJ_D(rd, rs1, rs2);
                case 0b001:
                    return new op64::FSGNJN_D(rd, rs1, rs2);
                case 0b010:
                    return new op64::FSGNJX_D(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b0010101:
                switch (funct3)
                {
                case 0b000:
                    return new op64::FMIN_D(rd, rs1, rs2);
                case 0b001:
                    return new op64::FMAX_D(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b0100000:
                switch (rs2)
                {
                case 0b00001:
                    return new op64::FCVT_S_D(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b0100001:
                switch (rs2)
                {
                case 0b00000:
                    return new op64::FCVT_D_S(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1010001:
                switch (funct3)
                {
                case 0b000:
                    return new op64::FLE_D(rd, rs1, rs2);
                case 0b001:
                    return new op64::FLT_D(rd, rs1, rs2);
                case 0b010:
                    return new op64::FEQ_D(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1110001:
                if (rs2 == 0b00000 && rm == 0b000)
                {
                    return new op64::FMV_X_D(rd, rs1);
                }
                else if (rs2 == 0b00000 && funct3 == 0b001)
                {
                    return new op64::FCLASS_D(rd, rs1);
                }
                else
                {
                    return nullptr;
                }
            case 0b1100001:
                switch (rs2)
                {
                case 0b00000:
                    return new op64::FCVT_W_D(rd, rs1, rs2);
                case 0b00001:
                    return new op64::FCVT_WU_D(rd, rs1, rs2);
                case 0b00010:
                    return new op64::FCVT_L_D(rd, rs1, rs2);
                case 0b00011:
                    return new op64::FCVT_LU_D(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1101001:
                switch (rs2)
                {
                case 0b00000:
                    return new op64::FCVT_D_W(rd, rs1, rs2);
                case 0b00001:
                    return new op64::FCVT_D_WU(rd, rs1, rs2);
                case 0b00010:
                    return new op64::FCVT_D_L(rd, rs1, rs2);
                case 0b00011:
                    return new op64::FCVT_D_LU(rd, rs1, rs2);
                default:
                    return nullptr;
                }
            case 0b1111001:
                if (rs2 == 0b00000 && rm == 0b000)
                {
                    return new op64::FMV_D_X(rd, rs1);
                }
                else
                {
                    return nullptr;
                }
            default:
                return nullptr;
            }
        default:
            return nullptr;
        }
    }

    IOp* DecodeRV64C(uint16_t insn) const
    {
        const auto opcode = Pick(insn, 0, 2);

        switch (opcode)
        {
        case 0b00:
            return DecodeRV64C_Quadrant0(insn);
        case 0b01:
            return DecodeRV64C_Quadrant1(insn);
        case 0b10:
            return DecodeRV64C_Quadrant2(insn);
        default:
            return nullptr;
        }
    }

    IOp* DecodeRV64C_Quadrant0(uint16_t insn) const
    {
        const auto funct3 = Pick(insn, 13, 3);

        const auto rd = Pick(insn, 2, 3) + 8;
        const auto rs1 = Pick(insn, 7, 3) + 8;
        const auto rs2 = Pick(insn, 2, 3) + 8;

        const auto uimm4 = ZeroExtend(7,
            Pick(insn, 10, 3) << 3 |
            Pick(insn, 6) << 2 |
            Pick(insn, 5) << 6);
        const auto uimm8 = ZeroExtend(8,
            Pick(insn, 10, 3) << 3 |
            Pick(insn, 5, 2) << 6);

        if (funct3 == 0b000 && Pick(insn, 5, 8) != 0)
        {
            const auto imm = ZeroExtend(10,
                Pick(insn, 11, 2) << 4 |
                Pick(insn, 7, 4) << 6 |
                Pick(insn, 6) << 2 |
                Pick(insn, 5) << 3);
            
            // C.ADDI4SPN
            return new op64::ADDI(2, 2, imm);
        }
        else if (funct3 == 0b001)
        {
            // C.FLD
            return new op64::FLD(rd, rs1, uimm8);
        }
        else if (funct3 == 0b010)
        {
            // C.LW
            return new op64::LW(rd, rs1, uimm4);
        }
        else if (funct3 == 0b011)
        {
            // C.LD
            return new op64::LD(rd, rs1, uimm8);
        }
        else if (funct3 == 0b101)
        {
            // C.FSD
            return new op64::FSD(rd, rs1, uimm8);
        }
        else if (funct3 == 0b110)
        {
            // C.SW
            return new op64::SW(rd, rs1, uimm4);
        }
        else if (funct3 == 0b111)
        {
            // C.SD
            return new op64::SD(rd, rs1, uimm8);
        }
        else
        {
            return nullptr;
        }
    }

    IOp* DecodeRV64C_Quadrant1(uint16_t insn) const
    {
        const auto funct4 = Pick(insn, 12, 4);
        const auto funct3 = Pick(insn, 13, 3);
        const auto funct2_rs1 = Pick(insn, 10, 2);
        const auto funct2_rs2 = Pick(insn, 5, 2);

        const auto rd = Pick(insn, 7, 5);
        const auto rs1 = Pick(insn, 7, 5);
        const auto rd_alu = Pick(insn, 7, 3) + 8;
        const auto rs1_alu = Pick(insn, 7, 3) + 8;
        const auto rs2_alu = Pick(insn, 2, 3) + 8;

        const auto imm = SignExtend(6,
            Pick(insn, 12, 1) << 5 |
            Pick(insn, 2, 5));
        const auto uimm = SignExtend(6,
            Pick(insn, 12, 1) << 5 |
            Pick(insn, 2, 5));
        const auto imm_j = SignExtend(12,
            Pick(insn, 12, 1) << 11 |
            Pick(insn, 11, 1) << 4 |
            Pick(insn, 9, 2) << 8 |
            Pick(insn, 8, 1) << 10 |
            Pick(insn, 7, 1) << 6 |
            Pick(insn, 6, 1) << 7 |
            Pick(insn, 3, 3) << 1 |
            Pick(insn, 2, 1) << 5);
        const auto imm_addi16sp = SignExtend(10,
            Pick(insn, 12) << 9 |
            Pick(insn, 6) << 4 |
            Pick(insn, 5) << 6 |
            Pick(insn, 3, 2) << 7 |
            Pick(insn, 2) << 5);
        const auto imm_lui = SignExtend(18,
            Pick(insn, 12) << 17 |
            Pick(insn, 2, 5) << 12);
        const auto imm_b = SignExtend(9,
            Pick(insn, 12, 1) << 8 |
            Pick(insn, 10, 2) << 3 |
            Pick(insn, 5, 2) << 6 |
            Pick(insn, 3, 2) << 1 |
            Pick(insn, 2, 1) << 5);

        if (funct3 == 0b000 && rd == 0)
        {            
            return new op64::NOP();
        }
        else if (funct3 == 0b000)
        {
            // C.ADDI
            return new op64::ADDI(rd, rs1, imm);
        }
        else if (funct3 == 0b001)
        {
            // C.ADDIW
            return new op64::ADDIW(rd, rs1, imm);
        }
        else if (funct3 == 0b010 && rd != 0)
        {
            // C.LI
            return new op64::ADDI(rd, 0, imm);
        }
        else if (funct3 == 0b011 && rd == 2)
        {
            // C.ADDI16SP
            return new op64::ADDI(2, 2, imm_addi16sp);
        }
        else if (funct3 == 0b011 && rd != 0 && rd != 2)
        {
            // C.LUI
            return new op64::LUI(rd, imm_lui);
        }
        else if (funct3 == 0b100 && funct2_rs1 == 0b00 && uimm != 0)
        {
            // C.SRLI
            return new op64::SRLI(rd_alu, rs1_alu, uimm);
        }
        else if (funct3 == 0b100 && funct2_rs1 == 0b00 && uimm == 0)
        {
            // C.SRLI64
            return new op64::SRLI(rd_alu, rs1_alu, 64);
        }
        else if (funct3 == 0b100 && funct2_rs1 == 0b01 && uimm != 0)
        {
            // C.SRAI
            return new op64::SRAI(rd_alu, rs1_alu, uimm);
        }
        else if (funct3 == 0b100 && funct2_rs1 == 0b01 && uimm == 0)
        {
            // C.SRAI64
            return new op64::SRAI(rd_alu, rs1_alu, 64);
        }
        else if (funct3 == 0b100 && funct2_rs1 == 0b10)
        {
            // C.ANDI
            return new op64::ANDI(rd_alu, rs1_alu, imm);
        }
        else if (funct4 == 0b1000 && funct2_rs1 == 0b11 && funct2_rs2 == 0b00)
        {
            // C.SUB
            return new op64::SUB(rd_alu, rs1_alu, rs2_alu);
        }
        else if (funct4 == 0b1000 && funct2_rs1 == 0b11 && funct2_rs2 == 0b01)
        {
            // C.XOR
            return new op64::XOR(rd_alu, rs1_alu, rs2_alu);
        }
        else if (funct4 == 0b1000 && funct2_rs1 == 0b11 && funct2_rs2 == 0b10)
        {
            // C.OR
            return new op64::OR(rd_alu, rs1_alu, rs2_alu);
        }
        else if (funct4 == 0b1000 && funct2_rs1 == 0b11 && funct2_rs2 == 0b11)
        {
            // C.AND
            return new op64::AND(rd_alu, rs1_alu, rs2_alu);
        }
        else if (funct4 == 0b1001 && funct2_rs1 == 0b11 && funct2_rs2 == 0b00)
        {
            // C.SUBW
            return new op64::SUBW(rd_alu, rs1_alu, rs2_alu);
        }
        else if (funct4 == 0b1001 && funct2_rs1 == 0b11 && funct2_rs2 == 0b01)
        {
            // C.ADDW
            return new op64::ADDW(rd_alu, rs1_alu, rs2_alu);
        }
        else if (funct3 == 0b101)
        {
            // C.J
            return new op64::JAL(0, imm_j);
        }
        else if (funct3 == 0b110)
        {
            // C.BEQZ
            return new op64::BEQ(rs1_alu, 0, imm_b);
        }
        else if (funct3 == 0b111)
        {
            // C.BNEZ
            return new op64::BNE(rs1_alu, 0, imm_b);
        }
        else
        {
            return nullptr;
        }
    }

    IOp* DecodeRV64C_Quadrant2(uint16_t insn) const
    {
        const auto funct4 = Pick(insn, 12, 4);
        const auto funct3 = Pick(insn, 13, 3);
        const auto rd = Pick(insn, 7, 5);
        const auto rs1 = Pick(insn, 7, 5);
        const auto rs2 = Pick(insn, 2, 5);

        const auto shamt = ZeroExtend(6,
            Pick(insn, 12, 1) << 5 |
            Pick(insn, 2, 5));
        const auto uimm_load4 = ZeroExtend(8,
            Pick(insn, 12) << 5 |
            Pick(insn, 4, 3) << 2 |
            Pick(insn, 2, 2) << 6);
        const auto uimm_load8 = ZeroExtend(9,
            Pick(insn, 12) << 5 |
            Pick(insn, 5, 2) << 3 |
            Pick(insn, 2, 3) << 6);
        const auto uimm_store4 = ZeroExtend(8,
            Pick(insn, 9, 4) << 2 |
            Pick(insn, 7, 2) << 6);
        const auto uimm_store8 = ZeroExtend(9,
            Pick(insn, 10, 3) << 3 |
            Pick(insn, 7, 3) << 6);

        if (funct3 == 0b000 && shamt != 0)
        {
            // C.SLLI
            return new op64::SLLI(rd, rs1, shamt);
        }
        else if (funct3 == 0b000 && shamt == 0)
        {
            // C.SLLI64
            return new op64::SLLI(rd, rs1, 64);
        }
        else if (funct3 == 0b001)
        {
            // C.FLDSP
            return new op64::FLD(rd, 2, uimm_load8);
        }
        else if (funct3 == 0b010 && rd != 0)
        {
            // C.LWSP
            return new op64::LW(rd, 2, uimm_load4);
        }
        else if (funct3 == 0b011)
        {
            // C.LDSP
            return new op64::LD(rd, 2, uimm_load8);
        }
        else if (funct4 == 0b1000 && rs1 != 0 && rs2 == 0)
        {
            // C.JR
            return new op64::JALR(0, rs1, 0);
        }
        else if (funct4 == 0b1000 && rd != 0 && rs2 != 0)
        {
            // C.MV
            return new op64::ADD(rd, 0, rs2);
        }
        else if (funct4 == 0b1001 && rd == 0 && rs2 == 0)
        {
            // C.EBREAK
            return new op64::EBREAK();
        }
        else if (funct4 == 0b1001 && rs1 != 0 && rs2 == 0)
        {
            // C.JALR
            return new op64::JALR(1, rs1, 0);
        }
        else if (funct4 == 0b1001 && rd != 0 && rs2 != 0)
        {
            // C.ADD
            return new op64::ADD(rd, rs1, rs2);
        }
        else if (funct3 == 0b101)
        {
            // C.FSDSP
            return new op64::FSD(2, rs2, uimm_store8);
        }
        else if (funct3 == 0b110)
        {
            // C.SWSP
            return new op64::SW(2, rs2, uimm_store4);
        }
        else if (funct3 == 0b111)
        {
            // C.SDSP
            return new op64::SD(2, rs2, uimm_store8);
        }
        else
        {
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
