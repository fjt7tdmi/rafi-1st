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

namespace rafi { namespace rv32a {

class LR_W final : public IOp
{
public:
    LR_W(int rd, int rs1, bool aq, bool rl);

    virtual ~LR_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    bool m_Aq;
    bool m_Rl;
};

class SC_W final : public IOp
{
public:
    SC_W(int rd, int rs1, int rs2, bool aq, bool rl);

    virtual ~SC_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    bool m_Aq;
    bool m_Rl;
};

class AMOSWAP_W final : public IOp
{
public:
    AMOSWAP_W(int rd, int rs1, int rs2, bool aq, bool rl);

    virtual ~AMOSWAP_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    bool m_Aq;
    bool m_Rl;
};

class AMOADD_W final : public IOp
{
public:
    AMOADD_W(int rd, int rs1, int rs2, bool aq, bool rl);

    virtual ~AMOADD_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    bool m_Aq;
    bool m_Rl;
};

class AMOXOR_W final : public IOp
{
public:
    AMOXOR_W(int rd, int rs1, int rs2, bool aq, bool rl);

    virtual ~AMOXOR_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    bool m_Aq;
    bool m_Rl;
};

class AMOAND_W final : public IOp
{
public:
    AMOAND_W(int rd, int rs1, int rs2, bool aq, bool rl);

    virtual ~AMOAND_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    bool m_Aq;
    bool m_Rl;
};

class AMOOR_W final : public IOp
{
public:
    AMOOR_W(int rd, int rs1, int rs2, bool aq, bool rl);

    virtual ~AMOOR_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    bool m_Aq;
    bool m_Rl;
};

class AMOMIN_W final : public IOp
{
public:
    AMOMIN_W(int rd, int rs1, int rs2, bool aq, bool rl);

    virtual ~AMOMIN_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    bool m_Aq;
    bool m_Rl;
};

class AMOMAX_W final : public IOp
{
public:
    AMOMAX_W(int rd, int rs1, int rs2, bool aq, bool rl);

    virtual ~AMOMAX_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    bool m_Aq;
    bool m_Rl;
};

class AMOMINU_W final : public IOp
{
public:
    AMOMINU_W(int rd, int rs1, int rs2, bool aq, bool rl);

    virtual ~AMOMINU_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    bool m_Aq;
    bool m_Rl;
};

class AMOMAXU_W final : public IOp
{
public:
    AMOMAXU_W(int rd, int rs1, int rs2, bool aq, bool rl);

    virtual ~AMOMAXU_W() override = default;
    virtual std::string ToString() const override;

private:
    int m_Rd;
    int m_Rs1;
    int m_Rs2;
    bool m_Aq;
    bool m_Rl;
};

}}
