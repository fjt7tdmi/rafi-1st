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

package OpTypes;

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

typedef enum logic
{
    RegType_Int = 1'h0,
    RegType_Fp  = 1'h1
} RegType;

typedef enum logic [3:0]
{
    AluCommand_Add      = 4'b0000,
    AluCommand_Sub      = 4'b1000,
    AluCommand_Sll      = 4'b0001,
    AluCommand_Slt      = 4'b0010,
    AluCommand_Sltu     = 4'b0011,
    AluCommand_Xor      = 4'b0100,
    AluCommand_Srl      = 4'b0101,
    AluCommand_Sra      = 4'b1101,
    AluCommand_Or       = 4'b0110,
    AluCommand_And      = 4'b0111,
    AluCommand_Clear1   = 4'b1001, // src1 & ~src2
    AluCommand_Clear2   = 4'b1010  // ~src1 & src2
} AluCommand;

typedef enum logic [1:0]
{
    AluSrcType1_Zero    = 2'h0,
    AluSrcType1_Reg     = 2'h1,
    AluSrcType1_Pc      = 2'h2,
    AluSrcType1_Csr     = 2'h3
} AluSrcType1;

typedef enum logic [1:0]
{
    AluSrcType2_Zero    = 2'h0,
    AluSrcType2_Reg     = 2'h1,
    AluSrcType2_Imm     = 2'h2,
    AluSrcType2_Csr     = 2'h3
} AluSrcType2;

typedef enum logic [4:0]
{
    AtomicType_LoadReserved     = 5'b00010,
    AtomicType_StoreConditional = 5'b00011,
    AtomicType_Swap             = 5'b00001,
    AtomicType_Add              = 5'b00000,
    AtomicType_Xor              = 5'b00100,
    AtomicType_And              = 5'b01100,
    AtomicType_Or               = 5'b01000,
    AtomicType_Min              = 5'b10000,
    AtomicType_Max              = 5'b10100,
    AtomicType_Minu             = 5'b11000,
    AtomicType_Maxu             = 5'b11100
} AtomicType;

typedef enum logic [3:0]
{
    BranchType_Equal                = 4'b0000,
    BranchType_NotEqual             = 4'b0001,
    BranchType_LessThan             = 4'b0100,
    BranchType_GreaterEqual         = 4'b0101,
    BranchType_UnsignedLessThan     = 4'b0110,
    BranchType_UnsignedGreaterEqual = 4'b0111,
    BranchType_Always               = 4'b1111
} BranchType;

typedef enum logic [1:0]
{
    FenceType_Default   = 2'b00,
    FenceType_I         = 2'b01,
    FenceType_Vma       = 2'b10
} FenceType;

typedef enum logic [2:0]
{
    ExUnitType_None         = 3'h0,
    ExUnitType_FpConverter  = 3'h1,
    ExUnitType_Fp32         = 3'h2,
    ExUnitType_Fp64         = 3'h3,
    ExUnitType_LoadStore    = 3'h4,
    ExUnitType_MulDiv       = 3'h5
} ExUnitType;

typedef enum logic [2:0]
{
    FpUnitType_Move         = 3'h0,
    FpUnitType_Classifier   = 3'h1,
    FpUnitType_Sign         = 3'h2,
    FpUnitType_Comparator   = 3'h3,
    FpUnitType_Converter    = 3'h4,
    FpUnitType_MulAdd       = 3'h5,
    FpUnitType_Div          = 3'h6,
    FpUnitType_Sqrt         = 3'h7
} FpUnitType;

typedef enum logic [3:0]
{
    FpComparatorCommand_Eq    = 4'h1,
    FpComparatorCommand_Lt    = 4'h2,
    FpComparatorCommand_Le    = 4'h3,
    FpComparatorCommand_Min   = 4'h4,
    FpComparatorCommand_Max   = 4'h5
} FpComparatorCommand;

typedef enum logic [3:0]
{
    FpSignUnitCommand_Sgnj  = 4'h1,
    FpSignUnitCommand_Sgnjn = 4'h2,
    FpSignUnitCommand_Sgnjx = 4'h3
} FpSignUnitCommand;

typedef enum logic [3:0]
{
    FpConverterCommand_W_S  = 4'h0,
    FpConverterCommand_WU_S = 4'h1,
    FpConverterCommand_L_S  = 4'h2,
    FpConverterCommand_LU_S = 4'h3,
    FpConverterCommand_W_D  = 4'h4,
    FpConverterCommand_WU_D = 4'h5,
    FpConverterCommand_L_D  = 4'h6,
    FpConverterCommand_LU_D = 4'h7,
    FpConverterCommand_S_W  = 4'h8,
    FpConverterCommand_S_WU = 4'h9,
    FpConverterCommand_S_L  = 4'ha,
    FpConverterCommand_S_LU = 4'hb,
    FpConverterCommand_D_W  = 4'hc,
    FpConverterCommand_D_WU = 4'hd,
    FpConverterCommand_D_L  = 4'he,
    FpConverterCommand_D_LU = 4'hf
} FpConverterCommand;

typedef enum logic [3:0]
{
    FpMulAddCommand_FMADD   = 4'h0,
    FpMulAddCommand_FMSUB   = 4'h1,
    FpMulAddCommand_FNMSUB  = 4'h2,
    FpMulAddCommand_FNMADD  = 4'h3,
    FpMulAddCommand_FADD    = 4'h4,
    FpMulAddCommand_FSUB    = 4'h5,
    FpMulAddCommand_FMUL    = 4'h6
} FpMulAddCommand;

typedef union packed
{
    FpComparatorCommand cmp;
    FpSignUnitCommand sign;
    FpMulAddCommand mulAdd;
} FpUnitCommand;

typedef enum logic [2:0]
{
    LoadStoreType_Byte              = 3'b000,
    LoadStoreType_HalfWord          = 3'b001,
    LoadStoreType_Word              = 3'b010,
    LoadStoreType_DoubleWord        = 3'b011,
    LoadStoreType_UnsignedByte      = 3'b100,
    LoadStoreType_UnsignedHalfWord  = 3'b101,
    LoadStoreType_UnsignedWord      = 3'b110,
    LoadStoreType_FpWord            = 3'b111
} LoadStoreType;

typedef enum logic [2:0]
{
    MulDivType_Mul      = 3'h0,
    MulDivType_Mulh     = 3'h1,
    MulDivType_Mulhsu   = 3'h2,
    MulDivType_Mulhu    = 3'h3,
    MulDivType_Div      = 3'h4,
    MulDivType_Divu     = 3'h5,
    MulDivType_Rem      = 3'h6,
    MulDivType_Remu     = 3'h7
} MulDivType;

typedef enum logic [1:0]
{
    IntRegWriteSrcType_Result   = 2'h0,
    IntRegWriteSrcType_NextPc   = 2'h1,
    IntRegWriteSrcType_Memory   = 2'h2,
    IntRegWriteSrcType_Csr      = 2'h3
} IntRegWriteSrcType;

typedef enum logic
{
    StoreSrcType_Int    = 1'h0,
    StoreSrcType_Fp     = 1'h1
} StoreSrcType;

typedef enum logic
{
    TrapOpType_Ecall    = 1'h0,
    TrapOpType_Ebreak   = 1'h1
} TrapOpType;

typedef struct packed
{
    AluCommand aluCommand;
    AluSrcType1 aluSrcType1;
    AluSrcType2 aluSrcType2;
    AtomicType atomicType;
    BranchType branchType;
    FenceType fenceType;
    ExUnitType exUnitType;
    FpConverterCommand fpConverterCommand;
    FpUnitType fpUnitType;
    FpUnitCommand fpUnitCommand;
    LoadStoreType loadStoreType;
    MulDivType mulDivType;
    IntRegWriteSrcType intRegWriteSrcType;
    StoreSrcType storeSrcType;
    TrapOpType trapOpType;
    Privilege trapReturnPrivilege;
    RegType dstRegType;
    word_t imm;
    logic isAtomic;
    logic isBranch;
    logic isFence;
    logic isLoad;
    logic isStore;
    logic isTrap;
    logic isTrapReturn;
    logic isUnknown;
    logic csrReadEnable;
    logic csrWriteEnable;
    logic regWriteEnable;
} Op;

endpackage
