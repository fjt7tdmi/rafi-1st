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

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

import OpTypes::*;
import ProcessorTypes::*;

function automatic word_t ALU(AluCommand command, word_t src1, word_t src2);
    unique case(command)
    AluCommand_Add: return src1 + src2;
    AluCommand_Sub: return src1 - src2;
    AluCommand_Sll: return src1 << $unsigned(src2[XLenLog2:0]);
    AluCommand_Slt: return ($signed(src1) < $signed(src2)) ? 1 : 0;
    AluCommand_Sltu: return ($unsigned(src1) < $unsigned(src2)) ? 1 : 0;
    AluCommand_Xor: return src1 ^ src2;
    AluCommand_Srl: return src1 >> $unsigned(src2[XLenLog2:0]);
    AluCommand_Sra: return src1 >>> $unsigned(src2[XLenLog2:0]);
    AluCommand_Or: return src1 | src2;
    AluCommand_And: return src1 & src2;
    AluCommand_Clear1: return src1 & ~src2;
    AluCommand_Clear2: return ~src1 & src2;
    default: return '0;
    endcase
endfunction

function automatic logic BranchComparator(BranchType branchType, word_t src1, word_t src2);
    unique case (branchType)
    BranchType_Equal: return src1 == src2;
    BranchType_NotEqual: return src1 != src2;
    BranchType_LessThan: return $signed(src1) < $signed(src2);
    BranchType_GreaterEqual: return $signed(src1) >= $signed(src2);
    BranchType_UnsignedLessThan: return $unsigned(src1) < $unsigned(src2);
    BranchType_UnsignedGreaterEqual: return $unsigned(src1) >= $unsigned(src2);
    BranchType_Always: return 1;
    default: return '0;
    endcase
endfunction

module ExecuteStage_MulDivUnit(
    output logic done,
    output logic [31:0] result,
    input MulDivType mulDivType,
    input logic [31:0] src1,
    input logic [31:0] src2,
    input logic enable,
    input logic stall,
    input logic flush,
    input logic clk,
    input logic rst
);
    // MulUnit
    logic mulDone;
    logic [31:0] mulResult;
    logic mulHigh;
    logic mulSrcSigned1;
    logic mulSrcSigned2;

    MulUnit m_MulUnit(
        .done(mulDone),
        .result(mulResult),
        .high(mulHigh),
        .srcSigned1(mulSrcSigned1),
        .srcSigned2(mulSrcSigned2),
        .src1,
        .src2,
        .enable,
        .stall,
        .flush,
        .clk,
        .rst
    );

    // DivUnit
    logic divDone;
    logic [31:0] quotient;
    logic [31:0] remnant;
    logic divSigned;

    DivUnit #(
        .N(32)
    ) m_DivUnit (
        .done(divDone),
        .quotient,
        .remnant,
        .isSigned(divSigned),
        .dividend(src1),
        .divisor(src2),
        .enable,
        .stall,
        .flush,
        .clk,
        .rst
    );

    always_comb begin
        mulHigh = (mulDivType == MulDivType_Mulh || mulDivType == MulDivType_Mulhsu || mulDivType == MulDivType_Mulhu);
        mulSrcSigned1 = (mulDivType == MulDivType_Mulh || mulDivType == MulDivType_Mulhsu);
        mulSrcSigned2 = (mulDivType == MulDivType_Mulh);
        divSigned = (mulDivType == MulDivType_Div || mulDivType == MulDivType_Rem);
    end

    always_comb begin
        if (mulDivType == MulDivType_Mul || mulDivType == MulDivType_Mulh || mulDivType == MulDivType_Mulhsu || mulDivType == MulDivType_Mulhu) begin
            done = mulDone;
            result = mulResult;
        end
        else if (mulDivType == MulDivType_Div || mulDivType == MulDivType_Divu) begin
            done = divDone;
            result = quotient;
        end
        else begin
            done = divDone;
            result = remnant;
        end
    end
endmodule

module ExecuteStage(
    RegReadStageIF.NextStage prevStage,
    ExecuteStageIF.ThisStage nextStage,
    PipelineControllerIF.ExecuteStage ctrl,
    ControlStatusRegisterIF.ExecuteStage csr,
    IntBypassLogicIF.ExecuteStage intBypass,
    FpBypassLogicIF.ExecuteStage fpBypass,
    input logic clk,
    input logic rst
);
    // Wires
    logic valid;
    Op op;

    logic enableMulDiv;

    logic doneMulDiv;

    word_t srcIntRegValue1;
    word_t srcIntRegValue2;
    word_t dstIntRegValue;

    uint64_t srcFpRegValue1;
    uint64_t srcFpRegValue2;
    uint64_t dstFpRegValue;

    word_t intResult;
    word_t intResultAlu;
    word_t intResultMulDiv;
    word_t intResultFp32;

    uint32_t fp32Result;

    logic branchTaken;
    addr_t branchTarget;
    word_t aluSrc1;
    word_t aluSrc2;

    TrapInfo trapInfo;
    logic trapReturn;

    // Modules
    ExecuteStage_MulDivUnit m_MulDivUnit(
        .done(doneMulDiv),
        .result(intResultMulDiv),
        .mulDivType(op.mulDivType),
        .src1(srcIntRegValue1),
        .src2(srcIntRegValue2),
        .enable(enableMulDiv),
        .stall(ctrl.exStall),
        .flush(ctrl.flush),
        .clk,
        .rst
    );

    Fp32Unit m_Fp32Unit(
        .intResult(intResultFp32),
        .fpResult(fp32Result),
        .command(op.fpUnitCommand),
        .intSrc1(srcIntRegValue1),
        .intSrc2(srcIntRegValue2),
        .fpSrc1(srcFpRegValue1[31:0]),
        .fpSrc2(srcFpRegValue2[31:0]),
        .clk,
        .rst
    );

    always_comb begin
        valid = prevStage.valid && !ctrl.flush;
        op = prevStage.op;
    end

    always_comb begin
        enableMulDiv = valid && (op.intResultType == IntResultType_MulDiv);
    end

    // src
    always_comb begin
        srcIntRegValue1 = intBypass.hit1 ? intBypass.readValue1 : prevStage.srcIntRegValue1;
        srcIntRegValue2 = intBypass.hit2 ? intBypass.readValue2 : prevStage.srcIntRegValue2;

        srcFpRegValue1 = fpBypass.hit1 ? fpBypass.readValue1 : prevStage.srcFpRegValue1;
        srcFpRegValue2 = fpBypass.hit2 ? fpBypass.readValue2 : prevStage.srcFpRegValue2;

        // aluSrc1
        unique case (op.aluSrcType1)
        AluSrcType1_Zero: aluSrc1 = '0;
        AluSrcType1_Pc: aluSrc1 = prevStage.pc;
        AluSrcType1_Reg: aluSrc1 = srcIntRegValue1;
        AluSrcType1_Csr: aluSrc1 = prevStage.srcCsrValue;
        default: aluSrc1 = '0;
        endcase

        // aluSrc2
        unique case (op.aluSrcType2)
        AluSrcType2_Zero: aluSrc2 = '0;
        AluSrcType2_Imm: aluSrc2 = op.imm;
        AluSrcType2_Reg: aluSrc2 = srcIntRegValue2;
        AluSrcType2_Csr: aluSrc2 = prevStage.srcCsrValue;
        default: aluSrc2 = '0;
        endcase
    end

    // result
    always_comb begin
        intResultAlu = ALU(op.aluCommand, aluSrc1, aluSrc2);

        unique case (op.intResultType)
        IntResultType_Alu:      intResult = intResultAlu;
        IntResultType_MulDiv:   intResult = intResultMulDiv;
        IntResultType_Fp32:     intResult = intResultFp32;
        default:                intResult = '0;
        endcase

        branchTaken = op.isBranch && BranchComparator(op.branchType, srcIntRegValue1, srcIntRegValue2);
        branchTarget = intResult;

        // dstIntRegValue
        unique case (op.intRegWriteSrcType)
        IntRegWriteSrcType_Result:  dstIntRegValue = intResult;
        IntRegWriteSrcType_NextPc:  dstIntRegValue = prevStage.pc + InsnSize;
        IntRegWriteSrcType_Csr:     dstIntRegValue = prevStage.srcCsrValue;
        default: dstIntRegValue = '0;
        endcase

        // dstFpRegValue
        dstFpRegValue = {32'h0, fp32Result};
    end

    always_comb begin
        ctrl.exStallReq = enableMulDiv && (!doneMulDiv);
    end

    always_comb begin
        intBypass.readAddr1 = prevStage.srcRegAddr1;
        intBypass.readAddr2 = prevStage.srcRegAddr2;
        intBypass.writeAddr = prevStage.dstRegAddr;
        intBypass.writeValue = dstIntRegValue;
        intBypass.writeEnable = valid && op.regWriteEnable && op.dstRegType == RegType_Int && !(op.isLoad || op.isAtomic) && !ctrl.exStallReq;

        fpBypass.readAddr1 = prevStage.srcRegAddr1;
        fpBypass.readAddr2 = prevStage.srcRegAddr2;
        fpBypass.writeAddr = prevStage.dstRegAddr;
        fpBypass.writeValue = dstFpRegValue;
        fpBypass.writeEnable = valid && op.regWriteEnable && op.dstRegType == RegType_Fp && !(op.isLoad || op.isAtomic) && !ctrl.exStallReq;
    end

    always_comb begin
        // trapInfo
        if (prevStage.trapInfo.valid) begin
            trapInfo = prevStage.trapInfo;
        end
        else if (valid && op.isTrap && op.trapOpType == TrapOpType_Ecall) begin
            trapInfo.valid = 1;
            trapInfo.value = '0;
            unique case (csr.privilege)
            Privilege_Machine: trapInfo.cause = ExceptionCode_EcallFromMachine;
            Privilege_Supervisor: trapInfo.cause = ExceptionCode_EcallFromSupervisor;
            default: trapInfo.cause = ExceptionCode_EcallFromUser;
            endcase
        end
        else if (valid && op.isTrap && op.trapOpType == TrapOpType_Ebreak) begin
            trapInfo.valid = 1;
            trapInfo.value = '0;
            trapInfo.cause = ExceptionCode_Breakpoint;
        end
        else if (valid && op.isTrapReturn && op.trapReturnPrivilege == Privilege_Supervisor && csr.trapSupervisorReturn) begin
            trapInfo.valid = 1;
            trapInfo.value = prevStage.insn;
            trapInfo.cause = ExceptionCode_IllegalInsn;
        end
        else begin
            trapInfo = '0;
        end

        trapReturn = (valid && !trapInfo.valid && op.isTrapReturn);
    end

    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            nextStage.valid <= '0;
            nextStage.op <= '0;
            nextStage.pc <= '0;
            nextStage.csrAddr <= '0;
            nextStage.dstCsrValue <= '0;
            nextStage.dstRegAddr <= '0;
            nextStage.dstIntRegValue <= '0;
            nextStage.dstFpRegValue <= '0;
            nextStage.memAddr <= '0;
            nextStage.storeRegValue <= '0;
            nextStage.branchTaken <= '0;
            nextStage.branchTarget <= '0;
            nextStage.trapInfo <= '0;
            nextStage.trapReturn <= '0;
            nextStage.debugInsn <= '0;
        end
        else if (ctrl.exStall) begin
            nextStage.valid <= nextStage.valid;
            nextStage.op <= nextStage.op;
            nextStage.pc <= nextStage.pc;
            nextStage.csrAddr <= nextStage.csrAddr;
            nextStage.dstCsrValue <= nextStage.dstCsrValue;
            nextStage.dstRegAddr <= nextStage.dstRegAddr;
            nextStage.dstIntRegValue <= nextStage.dstIntRegValue;
            nextStage.dstFpRegValue <= nextStage.dstFpRegValue;
            nextStage.memAddr <= nextStage.memAddr;
            nextStage.storeRegValue <= nextStage.storeRegValue;
            nextStage.branchTaken <= nextStage.branchTaken;
            nextStage.branchTarget <= nextStage.branchTarget;
            nextStage.trapInfo <= nextStage.trapInfo;
            nextStage.trapReturn <= nextStage.trapReturn;
            nextStage.debugInsn <= nextStage.debugInsn;
        end
        else if (ctrl.exStallReq) begin
            nextStage.valid <= '0;
            nextStage.op <= '0;
            nextStage.pc <= '0;
            nextStage.csrAddr <= '0;
            nextStage.dstCsrValue <= '0;
            nextStage.dstRegAddr <= '0;
            nextStage.dstIntRegValue <= '0;
            nextStage.dstFpRegValue <= '0;
            nextStage.memAddr <= '0;
            nextStage.storeRegValue <= '0;
            nextStage.branchTaken <= '0;
            nextStage.branchTarget <= '0;
            nextStage.trapInfo <= '0;
            nextStage.trapReturn <= '0;
            nextStage.debugInsn <= '0;
        end
        else begin
            nextStage.valid <= prevStage.valid;
            nextStage.op <= prevStage.op;
            nextStage.pc <= prevStage.pc;
            nextStage.csrAddr <= prevStage.csrAddr;
            nextStage.dstCsrValue <= intResult;
            nextStage.dstRegAddr <= prevStage.dstRegAddr;
            nextStage.dstIntRegValue <= dstIntRegValue;
            nextStage.dstFpRegValue <= dstFpRegValue;
            nextStage.memAddr <= intResult;
            nextStage.storeRegValue <= srcIntRegValue2;
            nextStage.branchTaken <= branchTaken;
            nextStage.branchTarget <= branchTarget;
            nextStage.trapInfo <= trapInfo;
            nextStage.trapReturn <= trapReturn;
            nextStage.debugInsn <= prevStage.insn;
         end
    end

endmodule
