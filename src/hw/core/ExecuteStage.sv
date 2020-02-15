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

function automatic LoadStoreUnitCommand getLoadStoreUnitCommand(Op op);
    if (op.isLoad) begin
        return LoadStoreUnitCommand_Load;
    end
    else if (op.isStore) begin
        return LoadStoreUnitCommand_Store;
    end
    else if (op.isFence && (op.fenceType == FenceType_I || op.fenceType == FenceType_Vma)) begin
        return LoadStoreUnitCommand_Invalidate;
    end
    else if (op.isAtomic && op.atomicType == AtomicType_LoadReserved) begin
        return LoadStoreUnitCommand_LoadReserved;
    end
    else if (op.isAtomic && op.atomicType == AtomicType_StoreConditional) begin
        return LoadStoreUnitCommand_StoreConditional;
    end
    else if (op.isAtomic) begin
        return LoadStoreUnitCommand_AtomicMemOp;
    end
    else begin
        return LoadStoreUnitCommand_None;
    end
endfunction

module ExecuteStage(
    RegReadStageIF.NextStage prevStage,
    ExecuteStageIF.ThisStage nextStage,
    PipelineControllerIF.ExecuteStage ctrl,
    CsrIF.ExecuteStage csr,
    FetchUnitIF.ExecuteStage fetchUnit,
    LoadStoreUnitIF.ExecuteStage loadStoreUnit,
    IntBypassLogicIF.ExecuteStage intBypass,
    FpBypassLogicIF.ExecuteStage fpBypass,
    input logic clk,
    input logic rst
);
    // Wires
    logic valid;
    Op op;
    always_comb begin
        valid = prevStage.valid;
        op = prevStage.op;
    end

    logic enableMulDiv;
    logic enableFp32;
    always_comb begin
        enableMulDiv = valid && (op.exUnitType == ExUnitType_MulDiv);
        enableFp32 = valid && (op.exUnitType == ExUnitType_Fp32);
    end

    logic done;
    logic doneMulDiv;
    logic doneFp32;
    always_comb begin
        unique case (op.exUnitType)
        ExUnitType_MulDiv:  done = doneMulDiv;
        ExUnitType_Fp32:    done = doneFp32;
        default:            done = 1;
        endcase
    end

    word_t srcIntRegValue1;
    word_t srcIntRegValue2;
    word_t dstIntRegValue;

    uint64_t srcFpRegValue1;
    uint64_t srcFpRegValue2;
    uint64_t srcFpRegValue3;
    uint64_t dstFpRegValue;

    word_t intResult;
    word_t intResultAlu;
    word_t intResultMulDiv;
    word_t intResultFp32;
    word_t intResultFpCvt;

    uint32_t fpResult32;
    uint32_t fpResultCvt;

    logic fflagsWriteCvt;
    logic fflagsWrite32;

    fflags_t fflagsValueCvt;
    fflags_t fflagsValue32;

    logic branchTaken;
    addr_t branchTarget;
    word_t aluSrc1;
    word_t aluSrc2;

    TrapInfo trapInfo;
    logic trapReturn;

    addr_t memAddr;
    word_t storeRegValue;
    logic invalidateICache;
    logic invalidateTlb;

    // Modules
    FpConverter m_FpConverter (
        .intResult(intResultFpCvt),
        .fp32Result(fpResultCvt),
        .writeFlagsValue(fflagsValueCvt),
        .writeFlags(fflagsWriteCvt),
        .command(op.fpConverterCommand),
        .roundingMode(csr.frm),
        .intSrc(srcIntRegValue1),
        .fp32Src(srcFpRegValue1[31:0]),
        .clk(clk),
        .rst(rst));

    Fp32Unit m_Fp32Unit(
        .intResult(intResultFp32),
        .fpResult(fpResult32),
        .writeFlagsValue(fflagsValue32),
        .writeFlags(fflagsWrite32),
        .done(doneFp32),
        .enable(enableFp32),
        .flush(0),
        .unit(op.fpUnitType),
        .command(op.fpUnitCommand),
        .roundingMode(csr.frm),
        .intSrc1(srcIntRegValue1),
        .intSrc2(srcIntRegValue2),
        .fpSrc1(srcFpRegValue1[31:0]),
        .fpSrc2(srcFpRegValue2[31:0]),
        .fpSrc3(srcFpRegValue3[31:0]),
        .clk,
        .rst
    );

    MulDivUnit m_MulDivUnit(
        .done(doneMulDiv),
        .result(intResultMulDiv),
        .mulDivType(op.mulDivType),
        .src1(srcIntRegValue1),
        .src2(srcIntRegValue2),
        .enable(enableMulDiv),
        .stall(0),
        .flush(0),
        .clk,
        .rst
    );

    // CSR
    always_comb begin
        csr.readAddr = prevStage.csrAddr;
        csr.readEnable = op.csrReadEnable;
        csr.writeEnable = valid && !trapInfo.valid && op.csrWriteEnable;
        csr.writeAddr = prevStage.csrAddr;
        csr.writeValue = intResult;

        unique case (op.exUnitType)
        ExUnitType_FpConverter: begin
            csr.write_fflags = fflagsWriteCvt;
            csr.write_fflags_value = fflagsValueCvt;
        end
        ExUnitType_Fp32: begin
            csr.write_fflags = fflagsWrite32;
            csr.write_fflags_value = fflagsValue32;
        end
        default: begin
            csr.write_fflags = '0;
            csr.write_fflags_value = '0;
        end
        endcase
    end

    // src
    always_comb begin
        srcIntRegValue1 = intBypass.hit1 ? intBypass.readValue1 : prevStage.srcIntRegValue1;
        srcIntRegValue2 = intBypass.hit2 ? intBypass.readValue2 : prevStage.srcIntRegValue2;

        srcFpRegValue1 = fpBypass.hit1 ? fpBypass.readValue1 : prevStage.srcFpRegValue1;
        srcFpRegValue2 = fpBypass.hit2 ? fpBypass.readValue2 : prevStage.srcFpRegValue2;
        srcFpRegValue3 = fpBypass.hit3 ? fpBypass.readValue3 : prevStage.srcFpRegValue3;

        // aluSrc1
        unique case (op.aluSrcType1)
        AluSrcType1_Zero: aluSrc1 = '0;
        AluSrcType1_Pc: aluSrc1 = prevStage.pc;
        AluSrcType1_Reg: aluSrc1 = srcIntRegValue1;
        AluSrcType1_Csr: aluSrc1 = csr.readValue;
        default: aluSrc1 = '0;
        endcase

        // aluSrc2
        unique case (op.aluSrcType2)
        AluSrcType2_Zero: aluSrc2 = '0;
        AluSrcType2_Imm: aluSrc2 = op.imm;
        AluSrcType2_Reg: aluSrc2 = srcIntRegValue2;
        AluSrcType2_Csr: aluSrc2 = csr.readValue;
        default: aluSrc2 = '0;
        endcase
    end

    // result
    always_comb begin
        intResultAlu = ALU(op.aluCommand, aluSrc1, aluSrc2);

        unique case (op.exUnitType)
        ExUnitType_FpConverter: intResult = intResultFpCvt;
        ExUnitType_Fp32:        intResult = intResultFp32;
        ExUnitType_MulDiv:      intResult = intResultMulDiv;
        default:                intResult = intResultAlu;
        endcase

        branchTaken = op.isBranch && BranchComparator(op.branchType, srcIntRegValue1, srcIntRegValue2);
        branchTarget = intResult;
    end

    // dstIntRegValue
    always_comb begin
        unique case (op.intRegWriteSrcType)
        IntRegWriteSrcType_Result:  dstIntRegValue = intResult;
        IntRegWriteSrcType_NextPc:  dstIntRegValue = prevStage.pc + InsnSize;
        IntRegWriteSrcType_Memory:  dstIntRegValue = loadStoreUnit.result;
        IntRegWriteSrcType_Csr:     dstIntRegValue = csr.readValue;
        default: dstIntRegValue = '0;
        endcase
    end

    // dstFpRegValue
    always_comb begin
        unique case (op.exUnitType)
        ExUnitType_FpConverter: dstFpRegValue = {32'h0, fpResultCvt};
        ExUnitType_Fp32:        dstFpRegValue = {32'h0, fpResult32};
        ExUnitType_LoadStore:   dstFpRegValue = {32'h0, loadStoreUnit.result};
        default:                dstFpRegValue = '0;
        endcase
    end

    // FetchUnit
    always_comb begin
        invalidateICache = valid && op.isFence &&
            (op.fenceType == FenceType_I || op.fenceType == FenceType_Vma);
        invalidateTlb = valid && op.isFence && op.fenceType == FenceType_Vma;

        fetchUnit.invalidateICache = invalidateICache;
        fetchUnit.invalidateTlb = invalidateTlb;
    end

    // LoadStoreUnit
    always_comb begin
        memAddr = intResult;

        unique case (op.storeSrcType)
        StoreSrcType_Int:   storeRegValue = srcIntRegValue2;
        StoreSrcType_Fp:    storeRegValue = srcFpRegValue2[31:0];
        default:            storeRegValue = '0;
        endcase

        loadStoreUnit.addr = memAddr;
        loadStoreUnit.enable = valid && (op.isLoad || op.isStore || op.isFence || op.isAtomic) && !prevStage.trapInfo.valid;
        loadStoreUnit.invalidateTlb = valid && op.isFence && op.fenceType == FenceType_Vma;
        loadStoreUnit.loadStoreType = op.loadStoreType;
        loadStoreUnit.atomicType = op.atomicType;
        loadStoreUnit.storeRegValue = storeRegValue;
        loadStoreUnit.command = getLoadStoreUnitCommand(op);
    end

    // PipelineController
    always_comb begin
        ctrl.exStallReq = !done || (loadStoreUnit.enable && !loadStoreUnit.done);
        ctrl.flushReq = valid && !ctrl.exStallReq && (
            (op.isBranch && branchTaken) ||
            op.csrWriteEnable ||
            invalidateICache ||
            invalidateTlb ||
            trapInfo.valid ||
            trapReturn);

        if (op.isBranch && branchTaken) begin
            ctrl.nextPc = branchTarget;
        end
        else begin
            ctrl.nextPc = prevStage.pc + InsnSize;
        end
    end

    // Bypass
    always_comb begin
        intBypass.readAddr1 = prevStage.srcRegAddr1;
        intBypass.readAddr2 = prevStage.srcRegAddr2;
        intBypass.writeAddr = prevStage.dstRegAddr;
        intBypass.writeValue = dstIntRegValue;
        intBypass.writeEnable = valid && op.regWriteEnable && op.dstRegType == RegType_Int && !ctrl.exStallReq;

        fpBypass.readAddr1 = prevStage.srcRegAddr1;
        fpBypass.readAddr2 = prevStage.srcRegAddr2;
        fpBypass.readAddr3 = prevStage.srcRegAddr3;
        fpBypass.writeAddr = prevStage.dstRegAddr;
        fpBypass.writeValue = dstFpRegValue;
        fpBypass.writeEnable = valid && op.regWriteEnable && op.dstRegType == RegType_Fp && !ctrl.exStallReq;
    end

    // trapInfo
    always_comb begin
        if (prevStage.trapInfo.valid) begin
            trapInfo = prevStage.trapInfo;
        end
        else if (valid && csr.readEnable && csr.readIllegal) begin
            trapInfo.valid = 1;
            trapInfo.value = prevStage.insn;
            trapInfo.cause = ExceptionCode_IllegalInsn;
        end
        else if (valid && op.isTrap && op.trapOpType == TrapOpType_Ecall) begin
            trapInfo.valid = 1;
            trapInfo.value = '0;

            unique case (csr.privilege)
            Privilege_Machine:      trapInfo.cause = ExceptionCode_EcallFromMachine;
            Privilege_Supervisor:   trapInfo.cause = ExceptionCode_EcallFromSupervisor;
            default:                trapInfo.cause = ExceptionCode_EcallFromUser;
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
        else if (valid && loadStoreUnit.fault) begin
            trapInfo.valid = 1;
            trapInfo.value = memAddr;
            trapInfo.cause = op.isStore ? ExceptionCode_StorePageFault : ExceptionCode_LoadPageFault;
        end
        else begin
            trapInfo = '0;
        end

        trapReturn = (valid && !trapInfo.valid && op.isTrapReturn);
    end

    always_ff @(posedge clk) begin
        if (rst || ctrl.exStallReq) begin
            nextStage.valid <= '0;
            nextStage.op <= '0;
            nextStage.pc <= '0;
            nextStage.csrAddr <= '0;
            nextStage.dstRegAddr <= '0;
            nextStage.dstIntRegValue <= '0;
            nextStage.dstFpRegValue <= '0;
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
            nextStage.dstRegAddr <= prevStage.dstRegAddr;
            nextStage.dstIntRegValue <= dstIntRegValue;
            nextStage.dstFpRegValue <= dstFpRegValue;
            nextStage.branchTaken <= branchTaken;
            nextStage.branchTarget <= branchTarget;
            nextStage.trapInfo <= trapInfo;
            nextStage.trapReturn <= trapReturn;
            nextStage.debugInsn <= prevStage.insn;
         end
    end

endmodule
