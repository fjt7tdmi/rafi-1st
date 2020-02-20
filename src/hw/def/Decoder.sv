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

package Decoder;

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

import OpTypes::*;
import ProcessorTypes::*;

// Sign extension functions
function automatic word_t sext12(logic [11:0] val);
    if (val[11]) begin
        return {20'b1111_1111_1111_1111_1111, val};
    end
    else begin
        return {20'b0000_0000_0000_0000_0000, val};
    end
endfunction

function automatic word_t sext13(logic [12:0] val);
    if (val[12]) begin
        return {19'b1111_1111_1111_1111_111, val};
    end
    else begin
        return {19'b0000_0000_0000_0000_000, val};
    end
endfunction

function automatic word_t sext21(logic [20:0] val);
    if (val[20]) begin
        return {11'b111_1111_1111, val};
    end
    else begin
        return {11'b000_0000_0000, val};
    end
endfunction

function automatic word_t sext32(logic [31:0] val);
    return val;
endfunction

function automatic word_t zext5(logic [4:0] val);
    return {27'b000_0000_0000_0000_0000_0000_0000, val};
endfunction

// Op util functions
function automatic bit IsValidAluCommand(AluCommand val);
    if (val == AluCommand_Add ||
        val == AluCommand_Sub ||
        val == AluCommand_Sll ||
        val == AluCommand_Slt ||
        val == AluCommand_Sltu ||
        val == AluCommand_Xor ||
        val == AluCommand_Srl ||
        val == AluCommand_Sra ||
        val == AluCommand_Or ||
        val == AluCommand_And) begin
        return 1;
    end
    else begin
        return 0;
    end
endfunction

function automatic bit IsValidBranchType(BranchType val);
    if (val == BranchType_Equal ||
        val == BranchType_NotEqual ||
        val == BranchType_LessThan ||
        val == BranchType_GreaterEqual ||
        val == BranchType_UnsignedLessThan ||
        val == BranchType_UnsignedGreaterEqual ||
        val == BranchType_Always) begin
        return 1;
    end
    else begin
        return 0;
    end
endfunction

function automatic bit IsValidLoadType(LoadStoreType val);
    if (val == LoadStoreType_Byte ||
        val == LoadStoreType_HalfWord ||
        val == LoadStoreType_Word ||
        val == LoadStoreType_UnsignedByte ||
        val == LoadStoreType_UnsignedHalfWord) begin
        return 1;
    end
    else begin
        return 0;
    end
endfunction

function automatic bit IsValidStoreType(LoadStoreType val);
    if (val == LoadStoreType_Byte ||
        val == LoadStoreType_HalfWord ||
        val == LoadStoreType_Word) begin
        return 1;
    end
    else begin
        return 0;
    end
endfunction

// Insn decode functions
function automatic Op DecodeRV32I(insn_t insn);
    Op op;

    logic [11:0] csr = insn[31:20];

    logic [6:0] funct7 = insn[31:25];
    logic [4:0] shamt = insn[24:20];
    logic [4:0] zimm = insn[19:15];
    logic [4:0] rs1 = insn[19:15];
    logic [2:0] funct3 = insn[14:12];
    logic [4:0] rd = insn[11:7];
    logic [6:0] opcode = insn[6:0];

    // default
    op.aluCommand = AluCommand_Add;
    op.aluSrcType1 = AluSrcType1_Zero;
    op.aluSrcType2 = AluSrcType2_Zero;
    op.branchType = BranchType_Always;
    op.fenceType = FenceType_Default;
    op.exUnitType = '0;
    op.fpUnitType = '0;
    op.command = '0;
    op.intRegWriteSrcType = IntRegWriteSrcType_Result;
    op.trapOpType = TrapOpType_Ecall;
    op.trapReturnPrivilege = Privilege_User;
    op.dstRegType = RegType_Int;
    op.imm = '0;
    op.isAtomic = 0;
    op.isBranch = 0;
    op.isFence = 0;
    op.isLoad = 0;
    op.isStore = 0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isUnknown = 0;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.regWriteEnable = 0;

    unique case (opcode)
    7'b0110111: begin
        // lui
        op.aluSrcType2 = AluSrcType2_Imm;
        op.imm = sext32({insn[31:12], 12'b0000_0000_0000});
        op.regWriteEnable = 1;
    end
    7'b0010111: begin
        // auipc
        op.aluSrcType1 = AluSrcType1_Pc;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.imm = sext32({insn[31:12], 12'b0000_0000_0000});
        op.regWriteEnable = 1;
    end
    7'b1101111: begin
        // jal
        op.aluSrcType1 = AluSrcType1_Pc;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.intRegWriteSrcType = IntRegWriteSrcType_NextPc;
        op.imm = sext21({insn[31], insn[19:12], insn[20], insn[30:21], 1'b0});
        op.isBranch = 1;
        op.regWriteEnable = 1;
    end
    7'b1100111: begin
        // jalr
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.intRegWriteSrcType = IntRegWriteSrcType_NextPc;
        op.imm = sext12(insn[31:20]);
        op.isBranch = 1;
        op.regWriteEnable = 1;
    end
    7'b1100011: begin
        // beq, bne, blt, bge, bltu, bgeu
        op.aluSrcType1 = AluSrcType1_Pc;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.imm = sext13({insn[31], insn[7], insn[30:25], insn[11:8], 1'b0});
        op.branchType = BranchType'({1'b0, funct3});
        op.isBranch = 1;
        if (!IsValidBranchType(op.branchType)) begin
            op.isUnknown = 1;
        end
    end
    7'b0000011: begin
        // lb, lh, lw, lbu, lhu
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.exUnitType = ExUnitType_LoadStore;
        op.command.mem.atomic = '0;
        op.command.mem.loadStoreType = LoadStoreType'(funct3);
        op.command.mem.storeSrc = StoreSrcType_Int;
        op.intRegWriteSrcType = IntRegWriteSrcType_Memory;
        op.imm = sext12(insn[31:20]);
        op.isLoad = 1;
        op.regWriteEnable = 1;
        if (!IsValidLoadType(op.command.mem.loadStoreType)) begin
            op.isUnknown = 1;
        end
    end
    7'b0100011: begin
        // sb, sh, sw
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.exUnitType = ExUnitType_LoadStore;
        op.command.mem.atomic = '0;
        op.command.mem.loadStoreType = LoadStoreType'(funct3);
        op.command.mem.storeSrc = StoreSrcType_Int;
        op.imm = sext12({insn[31:25], insn[11:7]});
        op.isStore = 1;
        if (!IsValidStoreType(op.command.mem.loadStoreType)) begin
            op.isUnknown = 1;
        end
    end
    7'b0010011: begin
        if (funct3 == 3'b001) begin
            // slli
            op.aluCommand = AluCommand'({1'b0, funct3});
            op.imm = {27'h0, shamt};
            if (funct7 != '0) begin
                op.isUnknown = 1;
            end
        end
        else if (funct3 == 3'b101) begin
            // srli, srai
            op.aluCommand = AluCommand'({funct7[5], funct3});
            op.imm = {27'h0, shamt};
            if ({funct7[6], funct7[4:0]} != '0) begin
                op.isUnknown = 1;
            end
        end
        else begin
            // addi, slti, sltiu, xori, ori, andi
            op.aluCommand = AluCommand'({1'b0, funct3});
            op.imm = sext12(insn[31:20]);
        end
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.regWriteEnable = 1;
    end
    7'b0110011: begin
        op.aluCommand = AluCommand'({funct7[5], funct3});
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Reg;
        op.regWriteEnable = 1;
        if (!IsValidAluCommand(op.aluCommand)) begin
            op.isUnknown = 1;
        end
    end
    7'b1110011: begin
        if (funct3 == 3'b000 && rd == 5'b00000) begin
            // ecall, ebreak, uret, sret, mret, sfence.vma
            // TODO: Implement WFI
            if (csr == 12'b0000_0000_0000 && rs1 == 5'b00000) begin
                op.isTrap = 1;
                op.trapOpType = TrapOpType_Ecall;
            end
            else if (csr == 12'b0000_0000_0001 && rs1 == 5'b00000) begin
                op.isTrap = 1;
                op.trapOpType = TrapOpType_Ebreak;
            end
            else if (csr == 12'b0000_0000_0010 && rs1 == 5'b00000) begin
                op.isTrapReturn = 1;
                op.trapReturnPrivilege = Privilege_User;
            end
            else if (csr == 12'b0001_0000_0010 && rs1 == 5'b00000) begin
                op.isTrapReturn = 1;
                op.trapReturnPrivilege = Privilege_Supervisor;
            end
            else if (csr == 12'b0011_0000_0010 && rs1 == 5'b00000) begin
                op.isTrapReturn = 1;
                op.trapReturnPrivilege = Privilege_Machine;
            end
            else if (funct7 == 7'b000_1001) begin
                op.exUnitType = ExUnitType_LoadStore;
                op.isFence = 1;
                op.fenceType = FenceType_Vma;
            end
            else begin
                op.isUnknown = 1;
            end
        end
        else if (funct3 == 3'b001) begin
            // csrrw
            op.csrReadEnable = 1;
            op.csrWriteEnable = 1;
            op.regWriteEnable = 1;
            op.intRegWriteSrcType = IntRegWriteSrcType_Csr;
            op.aluCommand = AluCommand_Add;
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Zero;
        end
        else if (funct3 == 3'b010) begin
            // csrrs
            op.csrReadEnable = 1;
            op.csrWriteEnable = 1;
            op.regWriteEnable = 1;
            op.intRegWriteSrcType = IntRegWriteSrcType_Csr;
            op.aluCommand = AluCommand_Or;
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Csr;
        end
        else if (funct3 == 3'b011) begin
            // csrrc
            op.csrReadEnable = 1;
            op.csrWriteEnable = 1;
            op.regWriteEnable = 1;
            op.intRegWriteSrcType = IntRegWriteSrcType_Csr;
            op.aluCommand = AluCommand_Clear2;
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Csr;
        end
        else if (funct3 == 3'b101) begin
            // csrrwi
            op.csrReadEnable = 1;
            op.csrWriteEnable = 1;
            op.regWriteEnable = 1;
            op.intRegWriteSrcType = IntRegWriteSrcType_Csr;
            op.imm = zext5(zimm);
            op.aluCommand = AluCommand_Add;
            op.aluSrcType1 = AluSrcType1_Zero;
            op.aluSrcType2 = AluSrcType2_Imm;
        end
        else if (funct3 == 3'b110) begin
            // csrrsi
            op.csrReadEnable = 1;
            op.csrWriteEnable = (rs1 == 5'b00000) ? 0 : 1;
            op.regWriteEnable = 1;
            op.intRegWriteSrcType = IntRegWriteSrcType_Csr;
            op.imm = zext5(zimm);
            op.aluCommand = AluCommand_Or;
            op.aluSrcType1 = AluSrcType1_Csr;
            op.aluSrcType2 = AluSrcType2_Imm;
        end
        else if (funct3 == 3'b111) begin
            // csrrci
            op.csrReadEnable = 1;
            op.csrWriteEnable = (rs1 == 5'b00000) ? 0 : 1;
            op.regWriteEnable = 1;
            op.intRegWriteSrcType = IntRegWriteSrcType_Csr;
            op.imm = zext5(zimm);
            op.aluCommand = AluCommand_Clear1;
            op.aluSrcType1 = AluSrcType1_Csr;
            op.aluSrcType2 = AluSrcType2_Imm;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b0001111: begin
        if (funct3 == 3'b000 && rd == 5'b00000 && rs1 == 5'b00000 && csr[11:8] == 4'b0000) begin
            // FENCE
            op.exUnitType = ExUnitType_LoadStore;
            op.isFence = 1;
            op.fenceType = FenceType_Default;
        end
        else if (funct3 == 3'b001 && rd == 5'b00000 && rs1 == 5'b00000 && csr == 12'h000) begin
            // FENCE.I
            op.exUnitType = ExUnitType_LoadStore;
            op.isFence = 1;
            op.fenceType = FenceType_I;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    default: begin
        op.isUnknown = 1;
    end
    endcase

    return op;
endfunction

function automatic Op DecodeRV32M(insn_t insn);
    Op op;

    op.aluCommand = '0;
    op.aluSrcType1 = '0;
    op.aluSrcType2 = '0;
    op.branchType = '0;
    op.fenceType = '0;
    op.exUnitType = ExUnitType_MulDiv;
    op.command.mulDiv = MulDivCommand'(insn[14:12]);
    op.fpUnitType = '0;
    op.intRegWriteSrcType = IntRegWriteSrcType_Result;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.dstRegType = RegType_Int;
    op.imm = '0;
    op.isAtomic = 0;
    op.isBranch = 0;
    op.isFence = 0;
    op.isLoad = 0;
    op.isStore = 0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isUnknown = 0;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.regWriteEnable = 1;

    return op;
endfunction

function automatic Op DecodeRV32A(insn_t insn);
    Op op;

    AtomicType atomicType = AtomicType'(insn[31:27]);
    logic [4:0] rs2 = insn[24:20];

    logic isSupportedAtomicOp =
        (atomicType == AtomicType_LoadReserved && rs2 == 5'b00000) ||
        (atomicType == AtomicType_StoreConditional) ||
        (atomicType == AtomicType_Swap) ||
        (atomicType == AtomicType_Add) ||
        (atomicType == AtomicType_Xor) ||
        (atomicType == AtomicType_And) ||
        (atomicType == AtomicType_Or) ||
        (atomicType == AtomicType_Min) ||
        (atomicType == AtomicType_Max) ||
        (atomicType == AtomicType_Minu) ||
        (atomicType == AtomicType_Maxu);

    op.aluCommand = AluCommand_Add;             // for address calculation
    op.aluSrcType1 = AluSrcType1_Reg;           // for address calculation
    op.aluSrcType2 = AluSrcType2_Zero;          // for address calculation
    op.branchType = '0;
    op.fenceType = '0;
    op.exUnitType = ExUnitType_LoadStore;
    op.command.mem.atomic = atomicType;
    op.command.mem.loadStoreType = LoadStoreType_UnsignedWord;
    op.command.mem.storeSrc = '0;
    op.fpUnitType = '0;
    op.intRegWriteSrcType = IntRegWriteSrcType_Memory;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.dstRegType = RegType_Int;
    op.imm = '0;
    op.isAtomic = 1;
    op.isBranch = 0;
    op.isFence = 0;
    op.isLoad = 0;
    op.isStore = 0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isUnknown = !isSupportedAtomicOp;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.regWriteEnable = 1;

    return op;
endfunction

function automatic Op DecodeRV32F(insn_t insn);
    logic [6:0] funct7  = insn[31:25];
    logic [1:0] funct2  = insn[26:25];
    logic [4:0] rs2     = insn[24:20];
    logic [2:0] funct3  = insn[14:12];
    logic [2:0] rm      = insn[14:12];
    logic [6:0] opcode  = insn[6:0];

    Op op;

    op.aluCommand = '0;
    op.aluSrcType1 = '0;
    op.aluSrcType2 = '0;
    op.branchType = '0;
    op.fenceType = '0;
    op.fpUnitType = '0;
    op.exUnitType = ExUnitType_Fp32;
    op.command = '0;
    op.intRegWriteSrcType = '0;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.dstRegType = '0;
    op.imm = '0;
    op.isAtomic = 0;
    op.isBranch = 0;
    op.isFence = 0;
    op.isLoad = 0;
    op.isStore = 0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isUnknown = '0;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.regWriteEnable = 0;

    unique case (opcode)
    7'b0000111: begin
        if (funct3 == 3'b010) begin
            // FLW
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Imm;
            op.exUnitType = ExUnitType_LoadStore;
            op.command.mem.atomic ='0;
            op.command.mem.loadStoreType = LoadStoreType_FpWord;
            op.command.mem.storeSrc = StoreSrcType_Fp;
            op.intRegWriteSrcType = IntRegWriteSrcType_Memory;
            op.imm = sext12(insn[31:20]);
            op.isLoad = 1;
            op.regWriteEnable = 1;
            op.dstRegType = RegType_Fp;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b0100111: begin
        if (funct3 == 3'b010) begin
            // FSW
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Imm;
            op.exUnitType = ExUnitType_LoadStore;
            op.command.mem.atomic ='0;
            op.command.mem.loadStoreType = LoadStoreType_FpWord;
            op.command.mem.storeSrc = StoreSrcType_Fp;
            op.imm = sext12({insn[31:25], insn[11:7]});
            op.isStore = 1;
            op.dstRegType = RegType_Fp;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1000011: begin
        if (funct2 == 2'b00) begin
            // FMADD.S
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FMADD;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1000111: begin
        if (funct2 == 2'b00) begin
            // FMSUB.S
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FMSUB;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1001011: begin
        if (funct2 == 2'b00) begin
            // FNMSUB.S
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FNMSUB;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1001111: begin
        if (funct2 == 2'b00) begin
            // FNMSUB.S
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FNMADD;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1010011: begin
        if (funct7 == 7'b0000000) begin
            // FADD.S
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FADD;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0000100) begin
            // FSUB.S
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FSUB;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0001000) begin
            // FMUL.S
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FMUL;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0001100) begin
            // FDIV.S
            op.fpUnitType = FpUnitType_Div;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0101100 && rs2 == 5'b00000) begin
            // FSQRT.S
            op.fpUnitType = FpUnitType_Sqrt;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0010000 && rm == 3'b000) begin
            // FSGNJ.S
            op.fpUnitType = FpUnitType_Sign;
            op.command.fp.sign = FpSignUnitCommand_Sgnj;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0010000 && rm == 3'b001) begin
            // FSGNJN.S
            op.fpUnitType = FpUnitType_Sign;
            op.command.fp.sign = FpSignUnitCommand_Sgnjn;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0010000 && rm == 3'b010) begin
            // FSGNJX.S
            op.fpUnitType = FpUnitType_Sign;
            op.command.fp.sign = FpSignUnitCommand_Sgnjx;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0010100 && rm == 3'b000) begin
            // FMIN.S
            op.fpUnitType = FpUnitType_Comparator;
            op.command.fp.cmp = FpComparatorCommand_Min;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0010100 && rm == 3'b001) begin
            // FMAX.S
            op.fpUnitType = FpUnitType_Comparator;
            op.command.fp.cmp = FpComparatorCommand_Max;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1100000 && rs2 == 5'b00000) begin
            // FCVT.W.S
            op.exUnitType = ExUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_W_S;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1100000 && rs2 == 5'b00001) begin
            // FCVT.WU.S
            op.exUnitType = ExUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_WU_S;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1110000 && rs2 == 5'b00000 && rm == 3'b000) begin
            // FMV.X.W
            op.fpUnitType = FpUnitType_Move;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1010000 && rm == 3'b010) begin
            // FEQ.S
            op.fpUnitType = FpUnitType_Comparator;
            op.command.fp.cmp = FpComparatorCommand_Eq;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1010000 && rm == 3'b001) begin
            // FLT.S
            op.fpUnitType = FpUnitType_Comparator;
            op.command.fp.cmp = FpComparatorCommand_Lt;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1010000 && rm == 3'b000) begin
            // FLE.S
            op.fpUnitType = FpUnitType_Comparator;
            op.command.fp.cmp = FpComparatorCommand_Le;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1110000 && rs2 == 5'b00000 && rm == 3'b001) begin
            // FCLASS.S
            op.fpUnitType = FpUnitType_Classifier;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1101000 && rs2 == 5'b00000) begin
            // FCVT.S.W
            op.exUnitType = ExUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_S_W;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1101000 && rs2 == 5'b00001) begin
            // FCVT.S.WU
            op.exUnitType = ExUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_S_WU;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1111000 && rs2 == 5'b00000 && rm == 3'b000) begin
            // FMV.W.X
            op.fpUnitType = FpUnitType_Move;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    default: begin
        op.isUnknown = 1;
    end
    endcase

    return op;
endfunction

function automatic Op DecodeRV32D(insn_t insn);
    logic [6:0] funct7  = insn[31:25];
    logic [1:0] funct2  = insn[26:25];
    logic [4:0] rs2     = insn[24:20];
    logic [2:0] funct3  = insn[14:12];
    logic [2:0] rm      = insn[14:12];
    logic [6:0] opcode  = insn[6:0];

    Op op;

    op.aluCommand = '0;
    op.aluSrcType1 = '0;
    op.aluSrcType2 = '0;
    op.branchType = '0;
    op.fenceType = '0;
    op.fpUnitType = '0;
    op.exUnitType = ExUnitType_Fp64;
    op.command = '0;
    op.intRegWriteSrcType = '0;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.dstRegType = '0;
    op.imm = '0;
    op.isAtomic = 0;
    op.isBranch = 0;
    op.isFence = 0;
    op.isLoad = 0;
    op.isStore = 0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isUnknown = '0;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.regWriteEnable = 0;

    unique case (opcode)
    7'b0000111: begin
        if (funct3 == 3'b011) begin
            // FLD
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Imm;
            op.exUnitType = ExUnitType_LoadStore;
            op.command.mem.atomic = '0;
            op.command.mem.loadStoreType = LoadStoreType_DoubleWord;
            op.command.mem.storeSrc = StoreSrcType_Fp;
            op.intRegWriteSrcType = IntRegWriteSrcType_Memory;
            op.imm = sext12(insn[31:20]);
            op.isLoad = 1;
            op.regWriteEnable = 1;
            op.dstRegType = RegType_Fp;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b0100111: begin
        if (funct3 == 3'b011) begin
            // FSD
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Imm;
            op.exUnitType = ExUnitType_LoadStore;
            op.command.mem.atomic = '0;
            op.command.mem.loadStoreType = LoadStoreType_DoubleWord;
            op.command.mem.storeSrc = StoreSrcType_Fp;
            op.imm = sext12({insn[31:25], insn[11:7]});
            op.isStore = 1;
            op.dstRegType = RegType_Fp;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1000011: begin
        if (funct2 == 2'b01) begin
            // FMADD.D
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FMADD;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1000111: begin
        if (funct2 == 2'b01) begin
            // FMSUB.D
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FMSUB;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1001011: begin
        if (funct2 == 2'b01) begin
            // FNMSUB.D
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FNMSUB;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1001111: begin
        if (funct2 == 2'b01) begin
            // FNMSUB.D
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FNMADD;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1010011: begin
        if (funct7 == 7'b0000001) begin
            // FADD.D
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FADD;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0000101) begin
            // FSUB.D
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FSUB;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0001001) begin
            // FMUL.D
            op.fpUnitType = FpUnitType_MulAdd;
            op.command.fp.mulAdd = FpMulAddCommand_FMUL;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0001101) begin
            // FDIV.D
            op.fpUnitType = FpUnitType_Div;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0101101 && rs2 == 5'b00000) begin
            // FSQRT.D
            op.fpUnitType = FpUnitType_Sqrt;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0010001 && rm == 3'b000) begin
            // FSGNJ.D
            op.fpUnitType = FpUnitType_Sign;
            op.command.fp.sign = FpSignUnitCommand_Sgnj;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0010001 && rm == 3'b001) begin
            // FSGNJN.D
            op.fpUnitType = FpUnitType_Sign;
            op.command.fp.sign = FpSignUnitCommand_Sgnjn;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0010001 && rm == 3'b010) begin
            // FSGNJX.D
            op.fpUnitType = FpUnitType_Sign;
            op.command.fp.sign = FpSignUnitCommand_Sgnjx;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0010101 && rm == 3'b000) begin
            // FMIN.D
            op.fpUnitType = FpUnitType_Comparator;
            op.command.fp.cmp = FpComparatorCommand_Min;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0010101 && rm == 3'b001) begin
            // FMAX.D
            op.fpUnitType = FpUnitType_Comparator;
            op.command.fp.cmp = FpComparatorCommand_Max;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0100000 && rs2 == 5'b00001) begin
            // FCVT.S.D
            op.exUnitType = ExUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_S_D;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b0100001 && rs2 == 5'b00000) begin
            // FCVT.D.S
            op.exUnitType = ExUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_D_S;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1010001 && rm == 3'b010) begin
            // FEQ.D
            op.fpUnitType = FpUnitType_Comparator;
            op.command.fp.cmp = FpComparatorCommand_Eq;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1010001 && rm == 3'b001) begin
            // FLT.S
            op.fpUnitType = FpUnitType_Comparator;
            op.command.fp.cmp = FpComparatorCommand_Lt;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1010001 && rm == 3'b000) begin
            // FLE.D
            op.fpUnitType = FpUnitType_Comparator;
            op.command.fp.cmp = FpComparatorCommand_Le;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1110001 && rs2 == 5'b00000 && rm == 3'b001) begin
            // FCLASS.D
            op.fpUnitType = FpUnitType_Classifier;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1100001 && rs2 == 5'b00000) begin
            // FCVT.W.D
            op.exUnitType = ExUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_W_D;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1100001 && rs2 == 5'b00001) begin
            // FCVT.WU.D
            op.exUnitType = ExUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_WU_D;
            op.dstRegType = RegType_Int;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1101001 && rs2 == 5'b00000) begin
            // FCVT.D.W
            op.exUnitType = ExUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_D_W;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else if (funct7 == 7'b1101001 && rs2 == 5'b00001) begin
            // FCVT.D.WU
            op.exUnitType = ExUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_D_WU;
            op.dstRegType = RegType_Fp;
            op.regWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    default: begin
        op.isUnknown = 1;
    end
    endcase

    return op;
endfunction

function automatic Op Decode(insn_t insn);
    logic [6:0] funct7 = insn[31:25];
    logic [2:0] funct3 = insn[14:12];
    logic [1:0] funct2 = insn[26:25];
    logic [6:0] opcode = insn[6:0];

    if (opcode == 7'b0110011 && funct7 == 7'b0000001) begin
        return DecodeRV32M(insn);
    end
    else if (opcode == 7'b0101111 && funct3 == 3'b010) begin
        return DecodeRV32A(insn);
    end
    else if ((opcode == 7'b0000111 && funct3 == 3'b010) ||
        (opcode == 7'b0100111 && funct3 == 3'b010) ||
        (opcode == 7'b1000011 && funct2 == 2'b00) ||
        (opcode == 7'b1000111 && funct2 == 2'b00) ||
        (opcode == 7'b1001011 && funct2 == 2'b00) ||
        (opcode == 7'b1001111 && funct2 == 2'b00) ||
        (opcode == 7'b1010011 && funct2 == 2'b00 && !(funct7 == 7'b0100000))) begin
        return DecodeRV32F(insn);
    end
    else if ((opcode == 7'b0000111 && funct3 == 3'b011) ||
        (opcode == 7'b0100111 && funct3 == 3'b011) ||
        (opcode == 7'b1000011 && funct2 == 2'b01) ||
        (opcode == 7'b1000111 && funct2 == 2'b01) ||
        (opcode == 7'b1001011 && funct2 == 2'b01) ||
        (opcode == 7'b1001111 && funct2 == 2'b01) ||
        (opcode == 7'b1010011 && funct2 == 2'b01) ||
        (opcode == 7'b1010011 && funct7 == 7'b0100000)) begin
        return DecodeRV32D(insn);
    end
    else begin
        return DecodeRV32I(insn);
    end
endfunction

endpackage
