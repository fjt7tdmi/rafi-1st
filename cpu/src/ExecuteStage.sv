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
    BypassLogicIF.ExecuteStage bypass,
    input logic clk,
    input logic rst
);
    // Wires
    logic valid;
    Op op;

    logic enableMulDiv;

    logic doneMulDiv;

    word_t srcRegValue1;
    word_t srcRegValue2;
    word_t dstRegValue;

    word_t result;
    word_t resultAlu;
    word_t resultMulDiv;

    logic branchTaken;
    addr_t branchTarget;
    word_t aluSrc1;
    word_t aluSrc2;

    TrapInfo trapInfo;
    logic trapReturn;

    // Modules
    ExecuteStage_MulDivUnit m_MulDivUnit(
        .done(doneMulDiv),
        .result(resultMulDiv),
        .mulDivType(op.mulDivType),
        .src1(srcRegValue1),
        .src2(srcRegValue2),
        .enable(enableMulDiv),
        .stall(ctrl.exStall),
        .flush(ctrl.flush),
        .clk,
        .rst
    );

    always_comb begin
        valid = prevStage.valid && !ctrl.flush;
        op = prevStage.op;
    end

    always_comb begin
        enableMulDiv = valid && (op.resultType == ResultType_MulDiv);
    end

    // src
    always_comb begin
        srcRegValue1 = bypass.hit1 ? bypass.readValue1 : prevStage.srcRegValue1;
        srcRegValue2 = bypass.hit2 ? bypass.readValue2 : prevStage.srcRegValue2;

        // aluSrc1
        unique case (op.aluSrcType1)
        AluSrcType1_Zero: aluSrc1 = '0;
        AluSrcType1_Pc: aluSrc1 = prevStage.pc;
        AluSrcType1_Reg: aluSrc1 = srcRegValue1;
        AluSrcType1_Csr: aluSrc1 = prevStage.srcCsrValue;
        default: aluSrc1 = 'x;
        endcase

        // aluSrc2
        unique case (op.aluSrcType2)
        AluSrcType2_Zero: aluSrc2 = '0;
        AluSrcType2_Imm: aluSrc2 = op.imm;
        AluSrcType2_Reg: aluSrc2 = srcRegValue2;
        AluSrcType2_Csr: aluSrc2 = prevStage.srcCsrValue;
        default: aluSrc2 = 'x;
        endcase
    end

    // result
    always_comb begin
        resultAlu = ALU(op.aluCommand, aluSrc1, aluSrc2);

        unique case (op.resultType)
        ResultType_Alu:     result = resultAlu;
        ResultType_MulDiv:  result = resultMulDiv;
        default:            result = 'x;
        endcase

        branchTaken = op.isBranch && BranchComparator(op.branchType, srcRegValue1, srcRegValue2);
        branchTarget = result;

        // dstRegValue
        unique case (op.regWriteSrcType)
        RegWriteSrcType_Result: dstRegValue = result;
        RegWriteSrcType_NextPc: dstRegValue = prevStage.pc + InsnSize;
        RegWriteSrcType_Csr:    dstRegValue = prevStage.srcCsrValue;
        default: dstRegValue = '0;
        endcase
    end

    always_comb begin
        ctrl.exStallReq = enableMulDiv && (!doneMulDiv);
    end

    always_comb begin
        bypass.readAddr1 = prevStage.srcRegAddr1;
        bypass.readAddr2 = prevStage.srcRegAddr2;
        bypass.writeAddr = prevStage.dstRegAddr;
        bypass.writeValue = dstRegValue;
        bypass.writeEnable = valid && op.regWriteEnable && !op.isLoad;
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
            nextStage.dstRegValue <= '0;
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
            nextStage.dstRegValue <= nextStage.dstRegValue;
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
            nextStage.dstRegValue <= '0;
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
            nextStage.dstCsrValue <= result;
            nextStage.dstRegAddr <= prevStage.dstRegAddr;
            nextStage.dstRegValue <= dstRegValue;
            nextStage.memAddr <= result;
            nextStage.storeRegValue <= srcRegValue2;
            nextStage.branchTaken <= branchTaken;
            nextStage.branchTarget <= branchTarget;
            nextStage.trapInfo <= trapInfo;
            nextStage.trapReturn <= trapReturn;
            nextStage.debugInsn <= prevStage.insn;
         end
    end

endmodule
