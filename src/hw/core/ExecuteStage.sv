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
import RafiTypes::*;

function automatic word_t ALU(AluCommand command, word_t src1, word_t src2);
    unique case(command)
    AluCommand_Add: return src1 + src2;
    AluCommand_Sub: return src1 - src2;
    AluCommand_Sll: return src1 << $unsigned(src2[XLEN_LOG2:0]);
    AluCommand_Slt: return ($signed(src1) < $signed(src2)) ? 1 : 0;
    AluCommand_Sltu: return ($unsigned(src1) < $unsigned(src2)) ? 1 : 0;
    AluCommand_Xor: return src1 ^ src2;
    AluCommand_Srl: return src1 >> $unsigned(src2[XLEN_LOG2:0]);
    AluCommand_Sra: return src1 >>> $unsigned(src2[XLEN_LOG2:0]);
    AluCommand_Or: return src1 | src2;
    AluCommand_And: return src1 & src2;
    AluCommand_Clear1: return src1 & ~src2;
    AluCommand_Clear2: return ~src1 & src2;
    default: return '0;
    endcase
endfunction

module ExecuteStage(
    RegReadStageIF.NextStage prevStage,
    ExecuteStageIF.ThisStage nextStage,
    MainPipeControllerIF.ExecuteStage ctrl,
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
    vaddr_t pc;
    always_comb begin
        valid = prevStage.valid;
        op = prevStage.op;
        pc = prevStage.pc;
    end

    logic enableFp32;
    logic enableFp64;
    logic enableMulDiv;
    logic enableBranch;
    always_comb begin
        enableFp32 = valid && (op.unit == ExecuteUnitType_Fp32);
        enableFp64 = valid && (op.unit == ExecuteUnitType_Fp64);
        enableMulDiv = valid && (op.unit == ExecuteUnitType_MulDiv);
        enableBranch = valid && (op.unit == ExecuteUnitType_Branch);
    end

    logic done;
    logic doneFp32;
    logic doneFp64;
    logic doneMulDiv;
    always_comb begin
        unique case (op.unit)
        ExecuteUnitType_Fp32:    done = doneFp32;
        ExecuteUnitType_Fp64:    done = doneFp64;
        ExecuteUnitType_MulDiv:  done = doneMulDiv;
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
    word_t intResultFpCvt;
    word_t intResultFp32;
    word_t intResultFp64;
    word_t intResultMulDiv;

    uint64_t fpResultCvt;
    uint32_t fpResult32;
    uint64_t fpResult64;

    logic fflagsWriteCvt;
    logic fflagsWrite32;
    logic fflagsWrite64;

    fflags_t fflagsValueCvt;
    fflags_t fflagsValue32;
    fflags_t fflagsValue64;

    logic branchTaken;
    vaddr_t branchTarget;
    word_t aluSrc1;
    word_t aluSrc2;

    TrapInfo trapInfo;
    logic trapReturn;

    logic invalidateICache;
    logic invalidateTlb;

    // Modules
    FpConverter fpConverter (
        .intResult(intResultFpCvt),
        .fpResult(fpResultCvt),
        .writeFlagsValue(fflagsValueCvt),
        .writeFlags(fflagsWriteCvt),
        .command(op.command.fpConverter),
        .roundingMode(csr.frm),
        .intSrc(srcIntRegValue1),
        .fpSrc(srcFpRegValue1),
        .clk(clk),
        .rst(rst));

    FpUnit #(
        .EXPONENT_WIDTH(8),
        .FRACTION_WIDTH(23)
    ) fp32Unit (
        .intResult(intResultFp32),
        .fpResult(fpResult32),
        .writeFlagsValue(fflagsValue32),
        .writeFlags(fflagsWrite32),
        .done(doneFp32),
        .enable(enableFp32),
        .flush(0),
        .unit(op.command.fp.unit),
        .command(op.command.fp.command),
        .roundingMode(csr.frm),
        .intSrc1(srcIntRegValue1),
        .intSrc2(srcIntRegValue2),
        .fpSrc1(srcFpRegValue1[31:0]),
        .fpSrc2(srcFpRegValue2[31:0]),
        .fpSrc3(srcFpRegValue3[31:0]),
        .clk,
        .rst
    );

    FpUnit #(
        .EXPONENT_WIDTH(11),
        .FRACTION_WIDTH(52)
    ) fp64Unit (
        .intResult(intResultFp64),
        .fpResult(fpResult64),
        .writeFlagsValue(fflagsValue64),
        .writeFlags(fflagsWrite64),
        .done(doneFp64),
        .enable(enableFp64),
        .flush(0),
        .unit(op.command.fp.unit),
        .command(op.command.fp.command),
        .roundingMode(csr.frm),
        .intSrc1(srcIntRegValue1),
        .intSrc2(srcIntRegValue2),
        .fpSrc1(srcFpRegValue1),
        .fpSrc2(srcFpRegValue2),
        .fpSrc3(srcFpRegValue3),
        .clk,
        .rst
    );

    MulDivUnit mulDivUnit(
        .done(doneMulDiv),
        .result(intResultMulDiv),
        .command(op.command.mulDiv),
        .src1(srcIntRegValue1),
        .src2(srcIntRegValue2),
        .enable(enableMulDiv),
        .stall(0),
        .flush(0),
        .clk,
        .rst
    );

    BranchUnit branchUnit (
        .taken(branchTaken),
        .target(branchTarget),
        .enable(enableBranch),
        .condition(op.command.branch.condition),
        .indirect(op.command.branch.indirect),
        .pc(pc),
        .srcRegValue1(srcIntRegValue1),
        .srcRegValue2(srcIntRegValue2),
        .imm(op.imm));

    // Permission check
    logic csrPermissionError;
    logic fencePermissionError;
    always_comb begin
        csrPermissionError = valid &&
            csr.status.TVM == 1 && csr.priv != Priv_Machine &&
            op.csrWriteEnable && prevStage.csrAddr == CSR_ADDR_SATP;
        fencePermissionError = valid &&
            csr.status.TVM == 1 && csr.priv != Priv_Machine &&
            op.unit == ExecuteUnitType_LoadStore && op.command.mem.fence == FenceType_Vma;
    end

    // CSR
    always_comb begin
        csr.readAddr = prevStage.csrAddr;
        csr.readEnable = op.csrReadEnable;
        csr.writeEnable = valid && !trapInfo.valid && op.csrWriteEnable && !csrPermissionError;
        csr.writeAddr = prevStage.csrAddr;
        csr.writeValue = intResult;

        unique case (op.unit)
        ExecuteUnitType_FpConverter: begin
            csr.write_fflags = fflagsWriteCvt;
            csr.write_fflags_value = fflagsValueCvt;
        end
        ExecuteUnitType_Fp32: begin
            csr.write_fflags = fflagsWrite32;
            csr.write_fflags_value = fflagsValue32;
        end
        ExecuteUnitType_Fp64: begin
            csr.write_fflags = fflagsWrite64;
            csr.write_fflags_value = fflagsValue64;
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

        unique case (op.unit)
        ExecuteUnitType_FpConverter: intResult = intResultFpCvt;
        ExecuteUnitType_Fp32:        intResult = intResultFp32;
        ExecuteUnitType_Fp64:        intResult = intResultFp64;
        ExecuteUnitType_MulDiv:      intResult = intResultMulDiv;
        default:                intResult = intResultAlu;
        endcase
    end

    // dstIntRegValue
    always_comb begin
        unique case (op.intRegWriteSrcType)
        IntRegWriteSrcType_Result:  dstIntRegValue = intResult;
        IntRegWriteSrcType_NextPc:  dstIntRegValue = prevStage.pc + (prevStage.isCompressedInsn ? 2 : 4);
        IntRegWriteSrcType_Memory:  dstIntRegValue = loadStoreUnit.resultValue[31:0];
        IntRegWriteSrcType_Csr:     dstIntRegValue = csr.readValue;
        default: dstIntRegValue = '0;
        endcase
    end

    // dstFpRegValue
    always_comb begin
        unique case (op.unit)
        ExecuteUnitType_FpConverter: dstFpRegValue = fpResultCvt;
        ExecuteUnitType_Fp32:        dstFpRegValue = {32'hffff_ffff, fpResult32};
        ExecuteUnitType_Fp64:        dstFpRegValue = fpResult64;
        ExecuteUnitType_LoadStore:   dstFpRegValue = loadStoreUnit.resultValue;
        default:                dstFpRegValue = '0;
        endcase
    end

    // FetchUnit
    always_comb begin
        invalidateICache = valid && !fencePermissionError &&
            op.unit == ExecuteUnitType_LoadStore && op.command.mem.fence inside {FenceType_I, FenceType_Vma};
        invalidateTlb = valid && !fencePermissionError && 
            op.unit == ExecuteUnitType_LoadStore && op.command.mem.fence == FenceType_Vma;

        fetchUnit.invalidateICache = invalidateICache;
        fetchUnit.invalidateTlb = invalidateTlb;
    end

    // LoadStoreUnit
    always_comb begin
        loadStoreUnit.enable = valid && op.unit == ExecuteUnitType_LoadStore && !prevStage.trapInfo.valid;
        loadStoreUnit.invalidateTlb = valid && !fencePermissionError && op.unit == ExecuteUnitType_LoadStore && op.command.mem.fence == FenceType_Vma;
        loadStoreUnit.loadStoreUnitCommand = op.command.mem.command;
        loadStoreUnit.command = op.command.mem;
        loadStoreUnit.imm = op.imm;
        loadStoreUnit.srcIntRegValue1 = srcIntRegValue1;
        loadStoreUnit.srcIntRegValue2 = srcIntRegValue2;
        loadStoreUnit.srcFpRegValue2 = srcFpRegValue2;
    end

    // MainPipeController
    always_comb begin
        ctrl.exStallReq = !done || (loadStoreUnit.enable && !loadStoreUnit.done);
        ctrl.flushReq = valid && !ctrl.exStallReq && (
            (enableBranch && branchTaken) ||
            op.csrWriteEnable ||
            invalidateICache ||
            invalidateTlb ||
            trapInfo.valid ||
            trapReturn);

        if (enableBranch && branchTaken) begin
            ctrl.flushTarget = branchTarget;
        end
        else begin
            ctrl.flushTarget = prevStage.pc + (prevStage.isCompressedInsn ? 2 : 4);
        end
    end

    // Bypass
    always_comb begin
        intBypass.readAddr1 = op.rs1;
        intBypass.readAddr2 = op.rs2;
        intBypass.writeAddr = op.rd;
        intBypass.writeValue = dstIntRegValue;
        intBypass.writeEnable = valid && op.intRegWriteEnable && !ctrl.exStallReq;

        fpBypass.readAddr1 = op.rs1;
        fpBypass.readAddr2 = op.rs2;
        fpBypass.readAddr3 = op.rs3;
        fpBypass.writeAddr = op.rd;
        fpBypass.writeValue = dstFpRegValue;
        fpBypass.writeEnable = valid && op.fpRegWriteEnable && !ctrl.exStallReq;
    end

    // trapInfo
    always_comb begin
        if (prevStage.trapInfo.valid) begin
            trapInfo = prevStage.trapInfo;
        end
        else if (valid && fencePermissionError && op.unit == ExecuteUnitType_LoadStore && op.command.mem.fence != FenceType_None) begin
            trapInfo.valid = 1;
            trapInfo.cause.isInterrupt = 0;
            trapInfo.cause.code = EXCEPTION_CODE_ILLEGAL_INSN;
            trapInfo.value = prevStage.insn;
        end
        else if (valid && csrPermissionError && op.csrWriteEnable) begin
            trapInfo.valid = 1;
            trapInfo.cause.isInterrupt = 0;
            trapInfo.cause.code = EXCEPTION_CODE_ILLEGAL_INSN;
            trapInfo.value = prevStage.insn;
        end
        else if (valid && op.isTrap && op.trapOpType == TrapOpType_Ecall) begin
            trapInfo.valid = 1;
            trapInfo.value = '0;
            trapInfo.cause.isInterrupt = 0;

            unique case (csr.priv)
            Priv_Machine:      trapInfo.cause.code = EXCEPTION_CODE_ECALL_FROM_U;
            Priv_Supervisor:   trapInfo.cause.code = EXCEPTION_CODE_ECALL_FROM_S;
            default:                trapInfo.cause.code = EXCEPTION_CODE_ECALL_FROM_M;
            endcase
        end
        else if (valid && op.isTrap && op.trapOpType == TrapOpType_Ebreak) begin
            trapInfo.valid = 1;
            trapInfo.cause.isInterrupt = 0;
            trapInfo.cause.code = EXCEPTION_CODE_BREAKPOINT;
            trapInfo.value = '0;
        end
        else if (valid && op.isTrapReturn && op.trapReturnPriv == Priv_Supervisor && csr.status.TSR) begin
            trapInfo.valid = 1;
            trapInfo.cause.isInterrupt = 0;
            trapInfo.cause.code = EXCEPTION_CODE_ILLEGAL_INSN;
            trapInfo.value = prevStage.insn;
        end
        else if (valid && op.isWfi && csr.priv != Priv_Machine && csr.status.TW) begin
            trapInfo.valid = 1;
            trapInfo.cause.isInterrupt = 0;
            trapInfo.cause.code = EXCEPTION_CODE_ILLEGAL_INSN;
            trapInfo.value = prevStage.insn;
        end
        else if (valid && loadStoreUnit.loadPagefault) begin
            trapInfo.valid = 1;
            trapInfo.cause.isInterrupt = 0;
            trapInfo.cause.code = EXCEPTION_CODE_LOAD_PAGE_FAULT;
            trapInfo.value = loadStoreUnit.resultAddr;
        end
        else if (valid && loadStoreUnit.storePagefault) begin
            trapInfo.valid = 1;
            trapInfo.cause.isInterrupt = 0;
            trapInfo.cause.code = EXCEPTION_CODE_STORE_PAGE_FAULT;
            trapInfo.value = loadStoreUnit.resultAddr;
        end
        else begin
            trapInfo = '0;
        end

        trapReturn = (valid && !trapInfo.valid && op.isTrapReturn);
    end

    always_ff @(posedge clk) begin
        if (rst || ctrl.exStallReq) begin
            nextStage.valid <= '0;
            nextStage.pc <= '0;
            nextStage.pc_paddr_debug <= '0;
            nextStage.insn <= '0;
            nextStage.op <= '0;
            nextStage.dstIntRegValue <= '0;
            nextStage.dstFpRegValue <= '0;
            nextStage.branchTaken <= '0;
            nextStage.branchTarget <= '0;
            nextStage.trapInfo <= '0;
            nextStage.trapReturn <= '0;
        end
        else begin
            nextStage.valid <= prevStage.valid;
            nextStage.insn <= prevStage.insn;
            nextStage.pc <= prevStage.pc;
            nextStage.pc_paddr_debug <= prevStage.pc_paddr_debug;
            nextStage.op <= prevStage.op;
            nextStage.dstIntRegValue <= dstIntRegValue;
            nextStage.dstFpRegValue <= dstFpRegValue;
            nextStage.branchTaken <= branchTaken;
            nextStage.branchTarget <= branchTarget;
            nextStage.trapInfo <= trapInfo;
            nextStage.trapReturn <= trapReturn;
         end
    end

endmodule
