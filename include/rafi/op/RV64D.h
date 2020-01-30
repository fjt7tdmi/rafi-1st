/*
 * Copyright 2018 Akifumi Fujita
 *
 * Licensed under the Apache License, Version 2.0(the "License");
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

#pragma once

#include <rafi/op/OpCommon.h>

namespace rafi { namespace op64 {

class FLD final : public IOp
{
public:
    FLD(int rd, int rs1, uint32_t imm);

    virtual ~FLD() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class FSD final : public IOp
{
public:
    FSD(int rs1, int rs2, uint32_t imm);

    virtual ~FSD() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
    uint32_t m_Imm;
};

class FMADD_D final : public IOp
{
public:
    FMADD_D(int rd, int rs1, int rs2, int rs3, int rm);

    virtual ~FMADD_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rs3;
    int m_Rm;
};

class FMSUB_D final : public IOp
{
public:
    FMSUB_D(int rd, int rs1, int rs2, int rs3, int rm);

    virtual ~FMSUB_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rs3;
    int m_Rm;
};

class FNMSUB_D final : public IOp
{
public:
    FNMSUB_D(int rd, int rs1, int rs2, int rs3, int rm);

    virtual ~FNMSUB_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rs3;
    int m_Rm;
};

class FNMADD_D final : public IOp
{
public:
    FNMADD_D(int rd, int rs1, int rs2, int rs3, int rm);

    virtual ~FNMADD_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rs3;
    int m_Rm;
};

class FADD_D final : public IOp
{
public:
    FADD_D(int rd, int rs1, int rs2, int rm);

    virtual ~FADD_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rm;
};

class FSUB_D final : public IOp
{
public:
    FSUB_D(int rd, int rs1, int rs2, int rm);

    virtual ~FSUB_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rm;
};

class FMUL_D final : public IOp
{
public:
    FMUL_D(int rd, int rs1, int rs2, int rm);

    virtual ~FMUL_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rm;
};

class FDIV_D final : public IOp
{
public:
    FDIV_D(int rd, int rs1, int rs2, int rm);

    virtual ~FDIV_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rm;
};

class FSQRT_D final : public IOp
{
public:
    FSQRT_D(int rd, int rs1, int rm);

    virtual ~FSQRT_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FSGNJ_D final : public IOp
{
public:
    FSGNJ_D(int rd, int rs1, int rs2);

    virtual ~FSGNJ_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FSGNJN_D final : public IOp
{
public:
    FSGNJN_D(int rd, int rs1, int rs2);

    virtual ~FSGNJN_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FSGNJX_D final : public IOp
{
public:
    FSGNJX_D(int rd, int rs1, int rs2);

    virtual ~FSGNJX_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FMIN_D final : public IOp
{
public:
    FMIN_D(int rd, int rs1, int rs2);

    virtual ~FMIN_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FMAX_D final : public IOp
{
public:
    FMAX_D(int rd, int rs1, int rs2);

    virtual ~FMAX_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FCVT_S_D final : public IOp
{
public:
    FCVT_S_D(int rd, int rs1, int rm);

    virtual ~FCVT_S_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FCVT_D_S final : public IOp
{
public:
    FCVT_D_S(int rd, int rs1, int rm);

    virtual ~FCVT_D_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FEQ_D final : public IOp
{
public:
    FEQ_D(int rd, int rs1, int rs2);

    virtual ~FEQ_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FLT_D final : public IOp
{
public:
    FLT_D(int rd, int rs1, int rs2);

    virtual ~FLT_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FLE_D final : public IOp
{
public:
    FLE_D(int rd, int rs1, int rs2);

    virtual ~FLE_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FCLASS_D final : public IOp
{
public:
    FCLASS_D(int rd, int rs1);

    virtual ~FCLASS_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
};

class FCVT_W_D final : public IOp
{
public:
    FCVT_W_D(int rd, int rs1, int rm);

    virtual ~FCVT_W_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FCVT_WU_D final : public IOp
{
public:
    FCVT_WU_D(int rd, int rs1, int rm);

    virtual ~FCVT_WU_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FCVT_D_W final : public IOp
{
public:
    FCVT_D_W(int rd, int rs1, int rm);

    virtual ~FCVT_D_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FCVT_D_WU final : public IOp
{
public:
    FCVT_D_WU(int rd, int rs1, int rm);

    virtual ~FCVT_D_WU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FCVT_L_D final : public IOp
{
public:
    FCVT_L_D(int rd, int rs1, int rm);

    virtual ~FCVT_L_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FCVT_LU_D final : public IOp
{
public:
    FCVT_LU_D(int rd, int rs1, int rm);

    virtual ~FCVT_LU_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FMV_X_D final : public IOp
{
public:
    FMV_X_D(int rd, int rs1);

    virtual ~FMV_X_D() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
};

class FCVT_D_L final : public IOp
{
public:
    FCVT_D_L(int rd, int rs1, int rm);

    virtual ~FCVT_D_L() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FCVT_D_LU final : public IOp
{
public:
    FCVT_D_LU(int rd, int rs1, int rm);

    virtual ~FCVT_D_LU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FMV_D_X final : public IOp
{
public:
    FMV_D_X(int rd, int rs1);

    virtual ~FMV_D_X() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
};

}}
