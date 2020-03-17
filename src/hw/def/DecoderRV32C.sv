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

package DecoderRV32C;

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

import OpTypes::*;
import RafiTypes::*;

function automatic word_t SignExtend6(logic [5:0] val);
    if (val[5]) begin
        return {26'b11_1111_1111_1111_1111_1111_1111, val};
    end
    else begin
        return {26'b00_0000_0000_0000_0000_0000_0000, val};
    end
endfunction

function automatic word_t SignExtend9(logic [8:0] val);
    if (val[8]) begin
        return {23'b111_1111_1111_1111_1111_1111, val};
    end
    else begin
        return {23'b000_0000_0000_0000_0000_0000, val};
    end
endfunction

function automatic word_t SignExtend10(logic [9:0] val);
    if (val[9]) begin
        return {22'b11_1111_1111_1111_1111_1111, val};
    end
    else begin
        return {22'b00_0000_0000_0000_0000_0000, val};
    end
endfunction

function automatic word_t SignExtend12(logic [11:0] val);
    if (val[11]) begin
        return {20'b1111_1111_1111_1111_1111, val};
    end
    else begin
        return {20'b0000_0000_0000_0000_0000, val};
    end
endfunction

function automatic word_t SignExtend18(logic [17:0] val);
    if (val[17]) begin
        return {14'b11_1111_1111_1111, val};
    end
    else begin
        return {14'b00_0000_0000_0000, val};
    end
endfunction

function automatic Op DecodeRV32C_Quadrant0(uint16_t insn);
    Op op;

    logic [2:0] funct3  = insn[15:13];
    reg_addr_t rd       = {2'b01, insn[4:2]};
    reg_addr_t rs1      = {2'b01, insn[9:7]};
    reg_addr_t rs2      = {2'b01, insn[4:2]};
    uint32_t uimm4   = {25'h0, insn[5], insn[12:10], insn[6], 2'h0};
    uint32_t uimm8   = {24'h0, insn[6:5], insn[12:10], 3'h0};
    uint32_t nzuimm  = {22'h0, insn[10:7], insn[12:11], insn[5], insn[6], 2'h0}; // for C.ADDI4SPN

    op.unit = '0;
    op.command = '0;
    op.aluCommand = '0;
    op.aluSrcType1 = '0;
    op.aluSrcType2 = '0;
    op.intRegWriteSrcType = '0;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.imm = '0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isWfi = 0;
    op.isUnknown = 0;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.fpRegWriteEnable = 0;
    op.intRegWriteEnable = 0;
    op.rd = rd;
    op.rs1 = rs1;
    op.rs2 = rs2;
    op.rs3 = '0;

    if (funct3 == 3'b000 && insn[12:5] != '0) begin
        // C.ADDI4SPN
        op.aluCommand = AluCommand_Add;
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.imm = nzuimm;
        op.intRegWriteEnable = 1;
        op.rs1 = 2;
    end
    else if (funct3 == 3'b001) begin
        // C.FLD
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Load;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_DoubleWord;
        op.command.mem.storeSrc = StoreSrcType_Fp;
        op.imm = uimm8;
        op.fpRegWriteEnable = 1;
    end
    else if (funct3 == 3'b010) begin
        // C.LW
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Load;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_Word;
        op.command.mem.storeSrc = StoreSrcType_Int;
        op.intRegWriteSrcType = IntRegWriteSrcType_Memory;
        op.imm = uimm4;
        op.intRegWriteEnable = 1;
    end
    else if (funct3 == 3'b011) begin
        // C.FLW
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Load;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_Word;
        op.command.mem.storeSrc = StoreSrcType_Fp;
        op.imm = uimm4;
        op.fpRegWriteEnable = 1;
    end
    else if (funct3 == 3'b101) begin
        // C.FSD
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Store;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_DoubleWord;
        op.command.mem.storeSrc = StoreSrcType_Fp;
        op.imm = uimm8;
    end
    else if (funct3 == 3'b110) begin
        // C.SW
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Store;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_Word;
        op.command.mem.storeSrc = StoreSrcType_Int;
        op.imm = uimm4;
    end
    else if (funct3 == 3'b111) begin
        // C.FSW
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Store;
        op.command.mem.atomic ='0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_FpWord;
        op.command.mem.storeSrc = StoreSrcType_Fp;
        op.imm = uimm4;
    end
    else begin
        op.isUnknown = 1;
    end

    return op;
endfunction

function automatic Op DecodeRV32C_Quadrant1(uint16_t insn);
    Op op;

    logic [2:0] funct3 = insn[15:13];
    logic [1:0] funct2 = insn[11:10];    
    reg_addr_t rd = insn[11:7];

    op.unit = '0;
    op.command = '0;
    op.aluCommand = '0;
    op.aluSrcType1 = '0;
    op.aluSrcType2 = '0;
    op.intRegWriteSrcType = '0;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.imm = '0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isWfi = 0;
    op.isUnknown = 0;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.fpRegWriteEnable = 0;
    op.intRegWriteEnable = 0;
    op.rd = {2'b01, insn[9:7]};
    op.rs1 = {2'b01, insn[9:7]};
    op.rs2 = {2'b01, insn[4:2]};
    op.rs3 = '0;

    if (funct3 == 3'b000) begin
        // C.ADDI (C.NOP if rd == 0)
        op.aluCommand = AluCommand_Add;
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.intRegWriteEnable = 1;
        op.imm = SignExtend6({insn[12], insn[6:2]});
        op.rd = insn[11:7];
        op.rs1 = insn[11:7];
    end
    else if (funct3 == 3'b001) begin
        // C.JAL
        op.unit = ExecuteUnitType_Branch;
        op.command.branch.condition = BranchType_Always;
        op.command.branch.indirect = 0;
        op.imm = SignExtend12({insn[12], insn[8], insn[10:9], insn[6], insn[7], insn[2], insn[11], insn [4:2], 1'b0});
        op.intRegWriteEnable = 1;
        op.intRegWriteSrcType = IntRegWriteSrcType_NextPc;
        op.rd = 1; // x1
    end
    else if (funct3 == 3'b010 && rd != '0) begin
        // C.LI
        op.aluCommand = AluCommand_Add;
        op.aluSrcType1 = AluSrcType1_Zero;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.intRegWriteEnable = 1;
        op.imm = SignExtend6({insn[12], insn[6:2]});
        op.rd = insn[11:7];
        op.rs1 = insn[11:7];
    end
    else if (funct3 == 3'b011 && rd != '0) begin
        // C.LUI (C.ADDI16SP if rd == 2)
        op.aluCommand = AluCommand_Add;
        op.aluSrcType1 = (rd == 5'h2) ? AluSrcType1_Reg : AluSrcType1_Zero;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.intRegWriteEnable = 1;
        op.intRegWriteSrcType = IntRegWriteSrcType_Result;
        op.imm = (rd == 5'h2)
            ? SignExtend10({insn[12], insn[4:3], insn[5], insn[2], insn[6], 4'h0})
            : SignExtend18({insn[12], insn[6:2], 12'h0});
        op.rd = insn[11:7];
        op.rs1 = insn[11:7];
    end
    else if (funct3 == 3'b100 && funct2 == 2'b00) begin
        // C.SRLI
        op.aluCommand = AluCommand_Srl;
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.intRegWriteEnable = 1;
        op.imm = {26'h0, insn[12], insn[6:2]};
    end
    else if (funct3 == 3'b100 && funct2 == 2'b01) begin
        // C.SRAI
        op.aluCommand = AluCommand_Sra;
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.intRegWriteEnable = 1;
        op.imm = {26'h0, insn[12], insn[6:2]};
    end
    else if (funct3 == 3'b100 && funct2 == 2'b10) begin
        // C.ANDI
        op.aluCommand = AluCommand_And;
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.intRegWriteEnable = 1;
        op.imm = SignExtend6({insn[12], insn[6:2]});
    end
    else if (funct3 == 3'b100 && funct2 == 2'b11) begin
        // C.SUB, C.XOR, C.OR, C.AND
        unique case (insn[6:5])
        2'b00:      op.aluCommand = AluCommand_Sub;
        2'b01:      op.aluCommand = AluCommand_Xor;
        2'b10:      op.aluCommand = AluCommand_Or;
        default:    op.aluCommand = AluCommand_And;
        endcase

        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Reg;
        op.intRegWriteEnable = 1;
    end
    else if (funct3 == 3'b101) begin
        // C.J
        op.unit = ExecuteUnitType_Branch;
        op.command.branch.condition = BranchType_Always;
        op.command.branch.indirect = 0;
        op.imm = SignExtend12({insn[12], insn[8], insn[10:9], insn[6], insn[7], insn[2], insn[11], insn [5:3], 1'b0});
    end
    else if (funct3 == 3'b110) begin
        // C.BEQZ
        op.unit = ExecuteUnitType_Branch;
        op.command.branch.condition = BranchType_Equal;
        op.command.branch.indirect = 0;
        op.imm = SignExtend9({insn[12], insn[6:5], insn[2], insn[11:10], insn[4:3], 1'b0});
        op.rs2 = 0;
    end
    else if (funct3 == 3'b111) begin
        // C.BNEZ
        op.unit = ExecuteUnitType_Branch;
        op.command.branch.condition = BranchType_NotEqual;
        op.command.branch.indirect = 0;
        op.imm = SignExtend9({insn[12], insn[6:5], insn[2], insn[11:10], insn[4:3], 1'b0});
        op.rs2 = 0;
    end
    else begin
        op.isUnknown = 1;
    end

    return op;
endfunction

function automatic Op DecodeRV32C_Quadrant2(uint16_t insn);
    Op op;

    logic [2:0] funct3 = insn[15:13];
    logic [1:0] funct2 = insn[11:10];    
    reg_addr_t rd = insn[11:7];
    reg_addr_t rs1 = insn[11:7];
    reg_addr_t rs2 = insn[6:2];

    uint32_t uimm   = {26'h0, insn[12], insn[6:2]};
    uint32_t uimm4  = {24'h0, insn[3:2], insn[12], insn[6:4], 2'h0};
    uint32_t uimm8  = {23'h0, insn[4:2], insn[12], insn[6:5], 3'h0};

    op.unit = '0;
    op.command = '0;
    op.aluCommand = '0;
    op.aluSrcType1 = '0;
    op.aluSrcType2 = '0;
    op.intRegWriteSrcType = '0;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.imm = '0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isWfi = 0;
    op.isUnknown = 0;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.fpRegWriteEnable = 0;
    op.intRegWriteEnable = 0;
    op.rd = rd;
    op.rs1 = rs1;
    op.rs2 = rs2;
    op.rs3 = '0;

    if (funct3 == 3'b000) begin
        // C.SLLI
        op.aluCommand = AluCommand_Sll;
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.intRegWriteEnable = 1;
        op.imm = uimm;
    end
    else if (funct3 == 3'b001) begin
        // C.FLDSP
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Load;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_DoubleWord;
        op.command.mem.storeSrc = StoreSrcType_Fp;
        op.imm = uimm8;
        op.fpRegWriteEnable = 1;
        op.rs1 = 2;
    end
    else if (funct3 == 3'b010) begin
        // C.LWSP
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Load;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_Word;
        op.command.mem.storeSrc = StoreSrcType_Int;
        op.intRegWriteSrcType = IntRegWriteSrcType_Memory;
        op.imm = uimm4;
        op.intRegWriteEnable = 1;
        op.rs1 = 2;
    end
    else if (funct3 == 3'b011) begin
        // C.FLWSP
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Load;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_FpWord;
        op.command.mem.storeSrc = StoreSrcType_Fp;
        op.imm = uimm4;
        op.fpRegWriteEnable = 1;
        op.rs1 = 2;
    end
    else if (funct3 == 3'b100) begin
        if (rs1 == 0 && rs2 == 0 && insn[12]) begin
            // C.EBREAK
            op.isTrap = 1;
            op.trapOpType = TrapOpType_Ebreak;
        end
        else if (rs1 != 0 && rs2 == 0) begin
            // C.JR, C.JALR
            op.unit = ExecuteUnitType_Branch;
            op.command.branch.condition = BranchType_Always;
            op.command.branch.indirect = 1;
            op.intRegWriteEnable = 1;
            op.intRegWriteSrcType = IntRegWriteSrcType_NextPc;
            op.rd = insn[12] ? 1 : 0;
            op.rs2 = 0;
        end
        else if (rs1 != 0 && rs2 != 0) begin
            // C.MV, C.ADD
            op.aluCommand = AluCommand_Add;
            op.aluSrcType1 = insn[12] ? AluSrcType1_Reg : AluSrcType1_Zero;
            op.aluSrcType2 = AluSrcType2_Reg;
            op.intRegWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    else if (funct3 == 3'b101) begin
        // C.FSDSP
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Store;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_DoubleWord;
        op.command.mem.storeSrc = StoreSrcType_Fp;
        op.imm = {23'h0, insn[9:7], insn[12:10], 3'h0};
        op.rs1 = 2;
    end
    else if (funct3 == 3'b110) begin
        // C.SWSP
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Store;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_Word;
        op.command.mem.storeSrc = StoreSrcType_Int;
        op.imm = {24'h0, insn[8:7], insn[12:9], 2'h0};
        op.rs1 = 2;
    end
    else if (funct3 == 3'b111) begin
        // C.FSWSP
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.command = LoadStoreUnitCommand_Store;
        op.command.mem.atomic ='0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType_FpWord;
        op.command.mem.storeSrc = StoreSrcType_Fp;
        op.imm = {24'h0, insn[8:7], insn[12:9], 2'h0};
        op.rs1 = 2;
    end
    else begin
        op.isUnknown = 1;
    end

    return op;
endfunction

function automatic Op DecodeRV32C_Unknown(uint16_t insn);
    Op op;

    op.aluCommand = '0;
    op.aluSrcType1 = '0;
    op.aluSrcType2 = '0;
    op.unit = '0;
    op.command.mulDiv = '0;
    op.intRegWriteSrcType = '0;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.imm = '0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isWfi = 0;
    op.isUnknown = 1;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.fpRegWriteEnable = 0;
    op.intRegWriteEnable = 0;

    return op;
endfunction

function automatic Op DecodeRV32C(uint16_t insn);
    logic [1:0] opcode = insn[1:0];

    if (opcode == 2'b00) begin
        return DecodeRV32C_Quadrant0(insn);
    end
    else if (opcode == 2'b01) begin
        return DecodeRV32C_Quadrant1(insn);
    end
    else if (opcode == 2'b10) begin
        return DecodeRV32C_Quadrant2(insn);
    end
    else begin
        return DecodeRV32C_Unknown(insn);
    end
endfunction

endpackage
