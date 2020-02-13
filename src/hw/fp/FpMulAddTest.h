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

#include "FpTest.h"

namespace rafi { namespace test {

namespace {
    // Command
    const int CMD_FMADD  = 0x0;
    const int CMD_FMSUB  = 0x1;
    const int CMD_FNMSUB = 0x2;
    const int CMD_FNMADD = 0x3;
    const int CMD_FADD   = 0x4;
    const int CMD_FSUB   = 0x5;
    const int CMD_FMUL   = 0x6;

    // Rounding Mode
    const int FRM_RNE = 0b000; // Round to Nearest, ties to Even
    const int FRM_RTZ = 0b001; // Round towards Zero
    const int FRM_RDN = 0b010; // Round Down
    const int FRM_RUP = 0b011; // Round Up
    const int FRM_RMM = 0b100; // Round to Nearest, ties to Max Magnitude
    const int FRM_DYN = 0b111; // In instruction's rm field, selects dynamic rounding mode; In Rounding Mode register, Invalid.
}

template<typename VTopModule>
class FpMulAddTest : public FpTest<VTopModule>
{
public:
    void ProcessCycle()
    {
        GetTop()->clk = 1;
        GetTop()->eval();
        GetTfp()->dump(m_Cycle * 10 + 5);

        GetTop()->clk = 0;
        GetTop()->eval();
        GetTfp()->dump(m_Cycle * 10 + 10);

        m_Cycle++;
    }

protected:
    virtual void SetUpModule() override
    {
        GetTop()->command = 0;
        GetTop()->roundingMode = 0;
        GetTop()->fpSrc1 = 0;
        GetTop()->fpSrc2 = 0;
        GetTop()->fpSrc3 = 0;

        // reset
        GetTop()->rst = 1;
        GetTop()->clk = 0;
        GetTop()->eval();
        GetTfp()->dump(0);

        ProcessCycle();

        GetTop()->rst = 0;
    }

    virtual void TearDownModule() override
    {
    }
};

}}
