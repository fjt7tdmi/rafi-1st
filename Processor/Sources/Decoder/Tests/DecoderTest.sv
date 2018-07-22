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

import Decoder::*;
import OpTypes::*;
import ProcessorTypes::*;

task automatic assert_addi(insn_t insn, word_t imm);
    Op op = Decode(insn);
    assert(op.aluCommand == AluCommand_Add);
    assert(op.aluSrcType1 == AluSrcType1_Reg);
    assert(op.aluSrcType2 == AluSrcType2_Imm);
    assert(op.regWriteSrcType == RegWriteSrcType_Result);
    assert(op.imm == imm);
    assert(op.isBranch == 0);
    assert(op.isLoad == 0);
    assert(op.isStore == 0);
    assert(op.isUnknown == 0);
    assert(op.regWriteEnable == 1);
endtask

task automatic assert_add(insn_t insn);
    Op op = Decode(insn);
    assert(op.aluCommand == AluCommand_Add)
    assert(op.aluSrcType1 == AluSrcType1_Reg);
    assert(op.aluSrcType2 == AluSrcType2_Reg);
    assert(op.regWriteSrcType == RegWriteSrcType_Result);
    assert(op.isBranch == 0);
    assert(op.isLoad == 0);
    assert(op.isStore == 0);
    assert(op.isUnknown == 0);
    assert(op.regWriteEnable == 1);
endtask

task automatic assert_branch(insn_t insn, BranchType branchType);
    Op op = Decode(insn);
    assert(op.aluCommand == AluCommand_Add)
    assert(op.aluSrcType1 == AluSrcType1_Pc);
    assert(op.aluSrcType2 == AluSrcType2_Imm);
    assert(op.branchType == branchType);
    assert(op.isBranch == 1);
    assert(op.isLoad == 0);
    assert(op.isStore == 0);
    assert(op.isUnknown == 0);
    assert(op.regWriteEnable == 0);
endtask

task automatic assert_jal(insn_t insn);
    Op op = Decode(insn);
    assert(op.aluCommand == AluCommand_Add)
    assert(op.aluSrcType1 == AluSrcType1_Pc);
    assert(op.aluSrcType2 == AluSrcType2_Imm);
    assert(op.branchType == BranchType_Always);
    assert(op.isBranch == 1);
    assert(op.isLoad == 0);
    assert(op.isStore == 0);
    assert(op.isUnknown == 0);
    assert(op.regWriteEnable == 1);
endtask

module DecoderTest;

    initial begin
        assert_addi(32'h00100093, 1);
        assert_addi(32'h00100113, 1);
        assert_addi(32'h00000193, 0);
        assert_addi(32'h00000213, 0);
        assert_addi(32'h00a00293, 10);
        assert_addi(32'h00008113, 0);
        assert_addi(32'h00018093, 0);
        assert_addi(32'h00120213, 1);
        
        assert_add(32'h002081b3);
        assert_add(32'h000180b3);
        
        assert_branch(32'hfe5216e3, BranchType_NotEqual);
        
        assert_jal(32'h0000006f);
        
        $finish;
    end

endmodule