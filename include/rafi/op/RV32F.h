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

namespace rafi { namespace rv32f {

class FLW final : public IOp
{
public:
    FLW(int rd, int rs1, uint32_t imm);

    virtual ~FLW() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    uint32_t m_Imm;
};

class FSW final : public IOp
{
public:
    FSW(int rs1, int rs2, uint32_t imm);

    virtual ~FSW() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rs1;
    int m_Rs2;
    uint32_t m_Imm;
};

class FMADD_S final : public IOp
{
public:
    FMADD_S(int rd, int rs1, int rs2, int rs3, int rm);

    virtual ~FMADD_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rs3;
    int m_Rm;
};

class FMSUB_S final : public IOp
{
public:
    FMSUB_S(int rd, int rs1, int rs2, int rs3, int rm);

    virtual ~FMSUB_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rs3;
    int m_Rm;
};

class FNMSUB_S final : public IOp
{
public:
    FNMSUB_S(int rd, int rs1, int rs2, int rs3, int rm);

    virtual ~FNMSUB_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rs3;
    int m_Rm;
};

class FNMADD_S final : public IOp
{
public:
    FNMADD_S(int rd, int rs1, int rs2, int rs3, int rm);

    virtual ~FNMADD_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rs3;
    int m_Rm;
};

class FADD_S final : public IOp
{
public:
    FADD_S(int rd, int rs1, int rs2, int rm);

    virtual ~FADD_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rm;
};

class FSUB_S final : public IOp
{
public:
    FSUB_S(int rd, int rs1, int rs2, int rm);

    virtual ~FSUB_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rm;
};

class FMUL_S final : public IOp
{
public:
    FMUL_S(int rd, int rs1, int rs2, int rm);

    virtual ~FMUL_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rm;
};

class FDIV_S final : public IOp
{
public:
    FDIV_S(int rd, int rs1, int rs2, int rm);

    virtual ~FDIV_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    int m_Rm;
};

class FSQRT_S final : public IOp
{
public:
    FSQRT_S(int rd, int rs1, int rm);

    virtual ~FSQRT_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FSGNJ_S final : public IOp
{
public:
    FSGNJ_S(int rd, int rs1, int rs2);

    virtual ~FSGNJ_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FSGNJN_S final : public IOp
{
public:
    FSGNJN_S(int rd, int rs1, int rs2);

    virtual ~FSGNJN_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FSGNJX_S final : public IOp
{
public:
    FSGNJX_S(int rd, int rs1, int rs2);

    virtual ~FSGNJX_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FMIN_S final : public IOp
{
public:
    FMIN_S(int rd, int rs1, int rs2);

    virtual ~FMIN_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FMAX_S final : public IOp
{
public:
    FMAX_S(int rd, int rs1, int rs2);

    virtual ~FMAX_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FCVT_W_S final : public IOp
{
public:
    FCVT_W_S(int rd, int rs1, int rm);

    virtual ~FCVT_W_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FCVT_WU_S final : public IOp
{
public:
    FCVT_WU_S(int rd, int rs1, int rm);

    virtual ~FCVT_WU_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FMV_X_W final : public IOp
{
public:
    FMV_X_W(int rd, int rs1);

    virtual ~FMV_X_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
};

class FEQ_S final : public IOp
{
public:
    FEQ_S(int rd, int rs1, int rs2);

    virtual ~FEQ_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FLT_S final : public IOp
{
public:
    FLT_S(int rd, int rs1, int rs2);

    virtual ~FLT_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FLE_S final : public IOp
{
public:
    FLE_S(int rd, int rs1, int rs2);

    virtual ~FLE_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class FCLASS_S final : public IOp
{
public:
    FCLASS_S(int rd, int rs1);

    virtual ~FCLASS_S() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
};

class FCVT_S_W final : public IOp
{
public:
    FCVT_S_W(int rd, int rs1, int rm);

    virtual ~FCVT_S_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FCVT_S_WU final : public IOp
{
public:
    FCVT_S_WU(int rd, int rs1, int rm);

    virtual ~FCVT_S_WU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rm;
};

class FMV_W_X final : public IOp
{
public:
    FMV_W_X(int rd, int rs1);

    virtual ~FMV_W_X() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
};

}}
