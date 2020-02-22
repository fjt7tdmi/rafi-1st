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
    op.unit = '0;
    op.command = '0;
    op.intRegWriteSrcType = IntRegWriteSrcType_Result;
    op.trapOpType = TrapOpType_Ecall;
    op.trapReturnPrivilege = Privilege_User;
    op.imm = '0;
    op.isBranch = 0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isUnknown = 0;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.fpRegWriteEnable = 0;
    op.intRegWriteEnable = 0;
    op.rs1 = insn[19:15];
    op.rs2 = insn[24:20];
    op.rs3 = insn[31:27];
    op.rd = insn[11:7];

    unique case (opcode)
    7'b0110111: begin
        // lui
        op.aluSrcType2 = AluSrcType2_Imm;
        op.imm = sext32({insn[31:12], 12'b0000_0000_0000});
        op.intRegWriteEnable = 1;
    end
    7'b0010111: begin
        // auipc
        op.aluSrcType1 = AluSrcType1_Pc;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.imm = sext32({insn[31:12], 12'b0000_0000_0000});
        op.intRegWriteEnable = 1;
    end
    7'b1101111: begin
        // jal
        op.aluSrcType1 = AluSrcType1_Pc;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.intRegWriteSrcType = IntRegWriteSrcType_NextPc;
        op.imm = sext21({insn[31], insn[19:12], insn[20], insn[30:21], 1'b0});
        op.isBranch = 1;
        op.intRegWriteEnable = 1;
    end
    7'b1100111: begin
        // jalr
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.intRegWriteSrcType = IntRegWriteSrcType_NextPc;
        op.imm = sext12(insn[31:20]);
        op.isBranch = 1;
        op.intRegWriteEnable = 1;
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
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.isAtomic = 0;
        op.command.mem.isFence = 0;
        op.command.mem.isLoad = 1;
        op.command.mem.isStore = 0;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType'(funct3);
        op.command.mem.storeSrc = StoreSrcType_Int;
        op.intRegWriteSrcType = IntRegWriteSrcType_Memory;
        op.imm = sext12(insn[31:20]);
        op.intRegWriteEnable = 1;
        if (!IsValidLoadType(op.command.mem.loadStoreType)) begin
            op.isUnknown = 1;
        end
    end
    7'b0100011: begin
        // sb, sh, sw
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Imm;
        op.unit = ExecuteUnitType_LoadStore;
        op.command.mem.isAtomic = 0;
        op.command.mem.isFence = 0;
        op.command.mem.isLoad = 0;
        op.command.mem.isStore = 1;
        op.command.mem.atomic = '0;
        op.command.mem.fence = '0;
        op.command.mem.loadStoreType = LoadStoreType'(funct3);
        op.command.mem.storeSrc = StoreSrcType_Int;
        op.imm = sext12({insn[31:25], insn[11:7]});
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
        op.intRegWriteEnable = 1;
    end
    7'b0110011: begin
        op.aluCommand = AluCommand'({funct7[5], funct3});
        op.aluSrcType1 = AluSrcType1_Reg;
        op.aluSrcType2 = AluSrcType2_Reg;
        op.intRegWriteEnable = 1;
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
                op.unit = ExecuteUnitType_LoadStore;
                op.command.mem.isFence = 1;
                op.command.mem.isAtomic = 0;
                op.command.mem.isLoad = 0;
                op.command.mem.isStore = 0;
                op.command.mem.atomic = '0;
                op.command.mem.fence = FenceType_Vma;
                op.command.mem.loadStoreType = '0;
                op.command.mem.storeSrc = '0;
            end
            else begin
                op.isUnknown = 1;
            end
        end
        else if (funct3 == 3'b001) begin
            // csrrw
            op.csrReadEnable = 1;
            op.csrWriteEnable = 1;
            op.intRegWriteEnable = 1;
            op.intRegWriteSrcType = IntRegWriteSrcType_Csr;
            op.aluCommand = AluCommand_Add;
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Zero;
        end
        else if (funct3 == 3'b010) begin
            // csrrs
            op.csrReadEnable = 1;
            op.csrWriteEnable = 1;
            op.intRegWriteEnable = 1;
            op.intRegWriteSrcType = IntRegWriteSrcType_Csr;
            op.aluCommand = AluCommand_Or;
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Csr;
        end
        else if (funct3 == 3'b011) begin
            // csrrc
            op.csrReadEnable = 1;
            op.csrWriteEnable = 1;
            op.intRegWriteEnable = 1;
            op.intRegWriteSrcType = IntRegWriteSrcType_Csr;
            op.aluCommand = AluCommand_Clear2;
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Csr;
        end
        else if (funct3 == 3'b101) begin
            // csrrwi
            op.csrReadEnable = 1;
            op.csrWriteEnable = 1;
            op.intRegWriteEnable = 1;
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
            op.intRegWriteEnable = 1;
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
            op.intRegWriteEnable = 1;
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
            op.unit = ExecuteUnitType_LoadStore;
            op.command.mem.isFence = 1;
            op.command.mem.isAtomic = 0;
            op.command.mem.isLoad = 0;
            op.command.mem.isStore = 0;
            op.command.mem.atomic = '0;
            op.command.mem.fence = FenceType_Default;
            op.command.mem.loadStoreType = '0;
            op.command.mem.storeSrc = '0;
        end
        else if (funct3 == 3'b001 && rd == 5'b00000 && rs1 == 5'b00000 && csr == 12'h000) begin
            // FENCE.I
            op.unit = ExecuteUnitType_LoadStore;
            op.command.mem.isFence = 1;
            op.command.mem.isAtomic = 0;
            op.command.mem.isLoad = 0;
            op.command.mem.isStore = 0;
            op.command.mem.atomic = '0;
            op.command.mem.fence = FenceType_I;
            op.command.mem.loadStoreType = '0;
            op.command.mem.storeSrc = '0;
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
    op.unit = ExecuteUnitType_MulDiv;
    op.command.mulDiv = MulDivCommand'(insn[14:12]);
    op.intRegWriteSrcType = IntRegWriteSrcType_Result;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.imm = '0;
    op.isBranch = 0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isUnknown = 0;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.fpRegWriteEnable = 0;
    op.intRegWriteEnable = 1;
    op.rs1 = insn[19:15];
    op.rs2 = insn[24:20];
    op.rs3 = insn[31:27];
    op.rd = insn[11:7];

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
    op.unit = ExecuteUnitType_LoadStore;
    op.command.mem.isAtomic = 1;
    op.command.mem.isFence = 0;
    op.command.mem.isLoad = 0;
    op.command.mem.isStore = 0;
    op.command.mem.atomic = atomicType;
    op.command.mem.fence = '0;
    op.command.mem.loadStoreType = LoadStoreType_UnsignedWord;
    op.command.mem.storeSrc = '0;
    op.intRegWriteSrcType = IntRegWriteSrcType_Memory;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.imm = '0;
    op.isBranch = 0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isUnknown = !isSupportedAtomicOp;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.fpRegWriteEnable = 0;
    op.intRegWriteEnable = 1;
    op.rs1 = insn[19:15];
    op.rs2 = insn[24:20];
    op.rs3 = insn[31:27];
    op.rd = insn[11:7];

    return op;
endfunction

function automatic Op DecodeRV32F(insn_t insn);
    Op op;

    logic [6:0] funct7  = insn[31:25];
    logic [1:0] funct2  = insn[26:25];
    logic [4:0] rs2     = insn[24:20];
    logic [2:0] funct3  = insn[14:12];
    logic [2:0] rm      = insn[14:12];
    logic [6:0] opcode  = insn[6:0];

    // default
    op.aluCommand = '0;
    op.aluSrcType1 = '0;
    op.aluSrcType2 = '0;
    op.branchType = '0;
    op.unit = ExecuteUnitType_Fp32;
    op.command = '0;
    op.intRegWriteSrcType = '0;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.imm = '0;
    op.isBranch = 0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isUnknown = '0;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.fpRegWriteEnable = 0;
    op.intRegWriteEnable = 0;
    op.rs1 = insn[19:15];
    op.rs2 = insn[24:20];
    op.rs3 = insn[31:27];
    op.rd = insn[11:7];

    unique case (opcode)
    7'b0000111: begin
        if (funct3 == 3'b010) begin
            // FLW
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Imm;
            op.unit = ExecuteUnitType_LoadStore;
            op.command.mem.isAtomic = 0;
            op.command.mem.isFence = 0;
            op.command.mem.isLoad = 1;
            op.command.mem.isStore = 0;
            op.command.mem.atomic ='0;
            op.command.mem.fence = '0;
            op.command.mem.loadStoreType = LoadStoreType_FpWord;
            op.command.mem.storeSrc = StoreSrcType_Fp;
            op.intRegWriteSrcType = IntRegWriteSrcType_Memory;
            op.imm = sext12(insn[31:20]);
            op.fpRegWriteEnable = 1;
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
            op.unit = ExecuteUnitType_LoadStore;
            op.command.mem.isAtomic = 0;
            op.command.mem.isFence = 0;
            op.command.mem.isLoad = 0;
            op.command.mem.isStore = 1;
            op.command.mem.atomic ='0;
            op.command.mem.fence = '0;
            op.command.mem.loadStoreType = LoadStoreType_FpWord;
            op.command.mem.storeSrc = StoreSrcType_Fp;
            op.imm = sext12({insn[31:25], insn[11:7]});
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1000011: begin
        if (funct2 == 2'b00) begin
            // FMADD.S
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FMADD;
            op.fpRegWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1000111: begin
        if (funct2 == 2'b00) begin
            // FMSUB.S
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FMSUB;
            op.fpRegWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1001011: begin
        if (funct2 == 2'b00) begin
            // FNMSUB.S
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FNMSUB;
            op.fpRegWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1001111: begin
        if (funct2 == 2'b00) begin
            // FNMSUB.S
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FNMADD;
            op.fpRegWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1010011: begin
        if (funct7 == 7'b0000000) begin
            // FADD.S
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FADD;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0000100) begin
            // FSUB.S
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FSUB;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0001000) begin
            // FMUL.S
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FMUL;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0001100) begin
            // FDIV.S
            op.command.fp.unit = FpSubUnitType_Div;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0101100 && rs2 == 5'b00000) begin
            // FSQRT.S
            op.command.fp.unit = FpSubUnitType_Sqrt;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0010000 && rm == 3'b000) begin
            // FSGNJ.S
            op.command.fp.unit = FpSubUnitType_Sign;
            op.command.fp.command.sign = FpSignUnitCommand_Sgnj;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0010000 && rm == 3'b001) begin
            // FSGNJN.S
            op.command.fp.unit = FpSubUnitType_Sign;
            op.command.fp.command.sign = FpSignUnitCommand_Sgnjn;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0010000 && rm == 3'b010) begin
            // FSGNJX.S
            op.command.fp.unit = FpSubUnitType_Sign;
            op.command.fp.command.sign = FpSignUnitCommand_Sgnjx;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0010100 && rm == 3'b000) begin
            // FMIN.S
            op.command.fp.unit = FpSubUnitType_Comparator;
            op.command.fp.command.cmp = FpComparatorCommand_Min;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0010100 && rm == 3'b001) begin
            // FMAX.S
            op.command.fp.unit = FpSubUnitType_Comparator;
            op.command.fp.command.cmp = FpComparatorCommand_Max;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1100000 && rs2 == 5'b00000) begin
            // FCVT.W.S
            op.unit = ExecuteUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_W_S;
            op.intRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1100000 && rs2 == 5'b00001) begin
            // FCVT.WU.S
            op.unit = ExecuteUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_WU_S;
            op.intRegWriteEnable = 1;
         end
        else if (funct7 == 7'b1110000 && rs2 == 5'b00000 && rm == 3'b000) begin
            // FMV.X.W
            op.command.fp.unit = FpSubUnitType_Move;
            op.intRegWriteEnable = 1;
         end
        else if (funct7 == 7'b1010000 && rm == 3'b010) begin
            // FEQ.S
            op.command.fp.unit = FpSubUnitType_Comparator;
            op.command.fp.command.cmp = FpComparatorCommand_Eq;
             op.intRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1010000 && rm == 3'b001) begin
            // FLT.S
            op.command.fp.unit = FpSubUnitType_Comparator;
            op.command.fp.command.cmp = FpComparatorCommand_Lt;
            op.intRegWriteEnable = 1;
         end
        else if (funct7 == 7'b1010000 && rm == 3'b000) begin
            // FLE.S
            op.command.fp.unit = FpSubUnitType_Comparator;
            op.command.fp.command.cmp = FpComparatorCommand_Le;
            op.intRegWriteEnable = 1;
         end
        else if (funct7 == 7'b1110000 && rs2 == 5'b00000 && rm == 3'b001) begin
            // FCLASS.S
            op.command.fp.unit = FpSubUnitType_Classifier;
            op.intRegWriteEnable = 1;
         end
        else if (funct7 == 7'b1101000 && rs2 == 5'b00000) begin
            // FCVT.S.W
            op.unit = ExecuteUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_S_W;
            op.fpRegWriteEnable = 1;
         end
        else if (funct7 == 7'b1101000 && rs2 == 5'b00001) begin
            // FCVT.S.WU
            op.unit = ExecuteUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_S_WU;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1111000 && rs2 == 5'b00000 && rm == 3'b000) begin
            // FMV.W.X
            op.command.fp.unit = FpSubUnitType_Move;
            op.fpRegWriteEnable = 1;
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
    Op op;

    logic [6:0] funct7  = insn[31:25];
    logic [1:0] funct2  = insn[26:25];
    logic [4:0] rs2     = insn[24:20];
    logic [2:0] funct3  = insn[14:12];
    logic [2:0] rm      = insn[14:12];
    logic [6:0] opcode  = insn[6:0];

    op.aluCommand = '0;
    op.aluSrcType1 = '0;
    op.aluSrcType2 = '0;
    op.branchType = '0;
    op.command.fp.unit = '0;
    op.unit = ExecuteUnitType_Fp64;
    op.command = '0;
    op.intRegWriteSrcType = '0;
    op.trapOpType = '0;
    op.trapReturnPrivilege = '0;
    op.imm = '0;
    op.isBranch = 0;
    op.isTrap = 0;
    op.isTrapReturn = 0;
    op.isUnknown = '0;
    op.csrReadEnable = 0;
    op.csrWriteEnable = 0;
    op.intRegWriteEnable = 0;
    op.fpRegWriteEnable = 0;
    op.rs1 = insn[19:15];
    op.rs2 = insn[24:20];
    op.rs3 = insn[31:27];
    op.rd = insn[11:7];

    unique case (opcode)
    7'b0000111: begin
        if (funct3 == 3'b011) begin
            // FLD
            op.aluSrcType1 = AluSrcType1_Reg;
            op.aluSrcType2 = AluSrcType2_Imm;
            op.unit = ExecuteUnitType_LoadStore;
            op.command.mem.isAtomic = 0;
            op.command.mem.isFence = 0;
            op.command.mem.isLoad = 1;
            op.command.mem.isStore = 0;
            op.command.mem.atomic = '0;
            op.command.mem.fence = '0;
            op.command.mem.loadStoreType = LoadStoreType_DoubleWord;
            op.command.mem.storeSrc = StoreSrcType_Fp;
            op.intRegWriteSrcType = IntRegWriteSrcType_Memory;
            op.imm = sext12(insn[31:20]);
            op.fpRegWriteEnable = 1;
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
            op.unit = ExecuteUnitType_LoadStore;
            op.command.mem.isAtomic = 0;
            op.command.mem.isFence = 0;
            op.command.mem.isLoad = 0;
            op.command.mem.isStore = 1;
            op.command.mem.atomic = '0;
            op.command.mem.fence = '0;
            op.command.mem.loadStoreType = LoadStoreType_DoubleWord;
            op.command.mem.storeSrc = StoreSrcType_Fp;
            op.imm = sext12({insn[31:25], insn[11:7]});
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1000011: begin
        if (funct2 == 2'b01) begin
            // FMADD.D
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FMADD;
            op.fpRegWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1000111: begin
        if (funct2 == 2'b01) begin
            // FMSUB.D
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FMSUB;
            op.fpRegWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1001011: begin
        if (funct2 == 2'b01) begin
            // FNMSUB.D
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FNMSUB;
            op.fpRegWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1001111: begin
        if (funct2 == 2'b01) begin
            // FNMSUB.D
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FNMADD;
            op.fpRegWriteEnable = 1;
        end
        else begin
            op.isUnknown = 1;
        end
    end
    7'b1010011: begin
        if (funct7 == 7'b0000001) begin
            // FADD.D
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FADD;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0000101) begin
            // FSUB.D
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FSUB;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0001001) begin
            // FMUL.D
            op.command.fp.unit = FpSubUnitType_MulAdd;
            op.command.fp.command.mulAdd = FpMulAddCommand_FMUL;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0001101) begin
            // FDIV.D
            op.command.fp.unit = FpSubUnitType_Div;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0101101 && rs2 == 5'b00000) begin
            // FSQRT.D
            op.command.fp.unit = FpSubUnitType_Sqrt;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0010001 && rm == 3'b000) begin
            // FSGNJ.D
            op.command.fp.unit = FpSubUnitType_Sign;
            op.command.fp.command.sign = FpSignUnitCommand_Sgnj;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0010001 && rm == 3'b001) begin
            // FSGNJN.D
            op.command.fp.unit = FpSubUnitType_Sign;
            op.command.fp.command.sign = FpSignUnitCommand_Sgnjn;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0010001 && rm == 3'b010) begin
            // FSGNJX.D
            op.command.fp.unit = FpSubUnitType_Sign;
            op.command.fp.command.sign = FpSignUnitCommand_Sgnjx;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0010101 && rm == 3'b000) begin
            // FMIN.D
            op.command.fp.unit = FpSubUnitType_Comparator;
            op.command.fp.command.cmp = FpComparatorCommand_Min;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0010101 && rm == 3'b001) begin
            // FMAX.D
            op.command.fp.unit = FpSubUnitType_Comparator;
            op.command.fp.command.cmp = FpComparatorCommand_Max;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0100000 && rs2 == 5'b00001) begin
            // FCVT.S.D
            op.unit = ExecuteUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_S_D;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b0100001 && rs2 == 5'b00000) begin
            // FCVT.D.S
            op.unit = ExecuteUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_D_S;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1010001 && rm == 3'b010) begin
            // FEQ.D
            op.command.fp.unit = FpSubUnitType_Comparator;
            op.command.fp.command.cmp = FpComparatorCommand_Eq;
            op.intRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1010001 && rm == 3'b001) begin
            // FLT.S
            op.command.fp.unit = FpSubUnitType_Comparator;
            op.command.fp.command.cmp = FpComparatorCommand_Lt;
            op.intRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1010001 && rm == 3'b000) begin
            // FLE.D
            op.command.fp.unit = FpSubUnitType_Comparator;
            op.command.fp.command.cmp = FpComparatorCommand_Le;
            op.intRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1110001 && rs2 == 5'b00000 && rm == 3'b001) begin
            // FCLASS.D
            op.command.fp.unit = FpSubUnitType_Classifier;
            op.intRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1100001 && rs2 == 5'b00000) begin
            // FCVT.W.D
            op.unit = ExecuteUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_W_D;
            op.intRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1100001 && rs2 == 5'b00001) begin
            // FCVT.WU.D
            op.unit = ExecuteUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_WU_D;
            op.intRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1101001 && rs2 == 5'b00000) begin
            // FCVT.D.W
            op.unit = ExecuteUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_D_W;
            op.fpRegWriteEnable = 1;
        end
        else if (funct7 == 7'b1101001 && rs2 == 5'b00001) begin
            // FCVT.D.WU
            op.unit = ExecuteUnitType_FpConverter;
            op.command.fpConverter = FpConverterCommand_D_WU;
            op.fpRegWriteEnable = 1;
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
