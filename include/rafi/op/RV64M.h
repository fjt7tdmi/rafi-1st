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

class MUL final : public IOp
{
public:
    MUL(int rd, int rs1, int rs2);

    virtual ~MUL() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class MULH final : public IOp
{
public:
    MULH(int rd, int rs1, int rs2);

    virtual ~MULH() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class MULHSU final : public IOp
{
public:
    MULHSU(int rd, int rs1, int rs2);

    virtual ~MULHSU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class MULHU final : public IOp
{
public:
    MULHU(int rd, int rs1, int rs2);

    virtual ~MULHU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class MULW final : public IOp
{
public:
    MULW(int rd, int rs1, int rs2);

    virtual ~MULW() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class DIV final : public IOp
{
public:
    DIV(int rd, int rs1, int rs2);

    virtual ~DIV() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class DIVW final : public IOp
{
public:
    DIVW(int rd, int rs1, int rs2);

    virtual ~DIVW() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class DIVU final : public IOp
{
public:
    DIVU(int rd, int rs1, int rs2);

    virtual ~DIVU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class DIVUW final : public IOp
{
public:
    DIVUW(int rd, int rs1, int rs2);

    virtual ~DIVUW() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class REM final : public IOp
{
public:
    REM(int rd, int rs1, int rs2);

    virtual ~REM() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class REMW final : public IOp
{
public:
    REMW(int rd, int rs1, int rs2);

    virtual ~REMW() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class REMU final : public IOp
{
public:
    REMU(int rd, int rs1, int rs2);

    virtual ~REMU() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

class REMUW final : public IOp
{
public:
    REMUW(int rd, int rs1, int rs2);

    virtual ~REMUW() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
};

}}
