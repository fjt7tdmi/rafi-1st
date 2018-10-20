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
    op.atomicType = AtomicType_LoadReserved;  // unused
    op.branchType = BranchType_Always;
    op.fenceType = FenceType_Default;
    op.loadStoreType = LoadStoreType_Word;
    op.mulDivType = MulDivType_Mul; // unused
    op.regWriteSrcType = RegWriteSrcType_Result;
    op.resultType = ResultType_Alu;
    op.trapOpType = TrapOpType_Ecall;
    op.trapReturnPrivilege = Privilege_User;
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
        op.regWriteSrcType = RegWriteSrcType_NextPc;
        op.imm = sext21({insn[31], insn[19:12], insn[20], insn[30:21], 1'b0});
        op.isBranch = 1;
        op.regWriteEnable = 1;
    end
    7'b1100111: begin
        // jalr
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.regWriteSrcType = RegWriteSrcType_NextPc;
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
        op.regWriteSrcType = RegWriteSrcType_Memory;
        op.loadStoreType = LoadStoreType'(funct3);
        op.imm = sext12(insn[31:20]);
        op.isLoad = 1;
        op.regWriteEnable = 1;
        if (!IsValidLoadType(op.loadStoreType)) begin
            op.isUnknown = 1;
        end
    end
    7'b0100011: begin
        // sb, sh, sw
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.loadStoreType = LoadStoreType'(funct3);
        op.imm = sext12({insn[31:25], insn[11:7]});
        op.isStore = 1;
        if (!IsValidStoreType(op.loadStoreType)) begin
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
            op.regWriteSrcType = RegWriteSrcType_Csr;
            op.aluCommand = AluCommand_Add;
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Zero;
        end
        else if (funct3 == 3'b010) begin
            // csrrs
            op.csrReadEnable = 1;
            op.csrWriteEnable = 1;
            op.regWriteEnable = 1;
            op.regWriteSrcType = RegWriteSrcType_Csr;
            op.aluCommand = AluCommand_Or;
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Csr;
        end
        else if (funct3 == 3'b011) begin
            // csrrc
            op.csrReadEnable = 1;
            op.csrWriteEnable = 1;
            op.regWriteEnable = 1;
            op.regWriteSrcType = RegWriteSrcType_Csr;
            op.aluCommand = AluCommand_Clear2;
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Csr;
        end
        else if (funct3 == 3'b101) begin
            // csrrwi
            op.csrReadEnable = 1;
            op.csrWriteEnable = 1;
            op.regWriteEnable = 1;
            op.regWriteSrcType = RegWriteSrcType_Csr;
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
            op.regWriteSrcType = RegWriteSrcType_Csr;
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
            op.regWriteSrcType = RegWriteSrcType_Csr;
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
            op.isFence = 1;
            op.fenceType = FenceType_Default;
        end
        else if (funct3 == 3'b001 && rd == 5'b00000 && rs1 == 5'b00000 && csr == 12'h000) begin
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

    MulDivType mulDivType = MulDivType'(insn[14:12]);

    op.aluCommand = AluCommand_Add;             // unused
    op.aluSrcType1 = AluSrcType1_Zero;          // unused
    op.aluSrcType2 = AluSrcType2_Zero;          // unused
    op.atomicType = AtomicType_LoadReserved;    // unused
    op.branchType = BranchType_Always;          // unused
    op.fenceType = FenceType_Default;           // unused
    op.loadStoreType = LoadStoreType_Word;      // unused
    op.mulDivType = mulDivType;
    op.regWriteSrcType = RegWriteSrcType_Result;
    op.resultType = ResultType_MulDiv;
    op.trapOpType = TrapOpType_Ebreak;          // unused
    op.trapReturnPrivilege = Privilege_User;    // unused
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
    op.atomicType = atomicType;
    op.branchType = BranchType_Always;          // unused
    op.fenceType = FenceType_Default;           // unused
    op.loadStoreType = LoadStoreType_Word;      // unused
    op.mulDivType = MulDivType_Mul;             // unused
    op.regWriteSrcType = RegWriteSrcType_Memory;
    op.resultType = ResultType_Alu;             // unused
    op.trapOpType = TrapOpType_Ebreak;          // unused
    op.trapReturnPrivilege = Privilege_User;    // unused
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

function automatic Op Decode(insn_t insn);
    logic [6:0] funct7 = insn[31:25];
    logic [2:0] funct3 = insn[14:12];
    logic [6:0] opcode = insn[6:0];
    
    if (opcode == 7'b0110011 && funct7 == 7'b0000001) begin
        return DecodeRV32M(insn);
    end
    else if (opcode == 7'b0101111 && funct3 == 3'b010) begin
        return DecodeRV32A(insn);
    end
    else begin
        return DecodeRV32I(insn);
    end
endfunction

endpackage
