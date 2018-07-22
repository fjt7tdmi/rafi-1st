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

module DivUnit #(
    parameter N = 32
)(
    output  logic done,
    output  logic [N-1:0] quotient,
    output  logic [N-1:0] remnant,
    input   logic isSigned,
    input   logic [N-1:0] dividend,
    input   logic [N-1:0] divisor,
    input   logic enable,
    input   logic stall,
    input   logic flush,
    input   logic clk,
    input   logic rst
);
    // typedef
    typedef logic unsigned [N:0] _abs_t;
    typedef logic [$clog2(N+1)-1:0] _counter_t;

    typedef enum logic [1:0]
    {
        State_Init = 2'h0,
        State_Process = 2'h1,
        State_Done = 2'h2
    } State;

    // Functions
    function automatic _abs_t getAbs(logic [N-1:0] val, logic isSigned);
        _abs_t exVal;
        
        if (isSigned) begin
            exVal = {val[N-1], val[N-1:0]};
        end
        else begin
            exVal = {1'b0, val[N-1:0]};
        end

        return (exVal[N] == 1'b1) ? (-exVal) : exVal;
    endfunction

    // Registers
    logic [N-1:0] reg_Quotient;
    logic [N-1:0] reg_DividendShifter;
    _abs_t reg_Dividend;
    _abs_t reg_Divisor;
    logic reg_QuontientNegative;
    logic reg_RemnantNegative;
    _counter_t reg_Counter;
    State reg_State;

    // Wires
    logic [N-1:0] next_Quotient;
    logic [N-1:0] next_DividendShifter;
    _abs_t next_Dividend;
    _abs_t next_Divisor;
    logic next_QuontientNegative;
    logic next_RemnantNegative;
    _counter_t next_Counter;
    State next_State;

    _abs_t absDividend;
    _abs_t absDivisor;

    logic cmpResult;
    _abs_t subResult;
    logic [N-1:0] divResult;

    always_comb begin
        absDividend = getAbs(dividend, isSigned);
        absDivisor = getAbs(divisor, isSigned);

        cmpResult = (reg_Dividend >= reg_Divisor) ? 1'b1 : 1'b0;
        subResult = cmpResult ? (reg_Dividend - reg_Divisor) : reg_Dividend;
        divResult = reg_Dividend[N-1:0];

        done = (reg_State == State_Done);
        quotient = reg_QuontientNegative ? (-reg_Quotient) : reg_Quotient;
        remnant = reg_RemnantNegative ? (-divResult) : divResult;

        if (reg_State == State_Init && enable) begin
            if (divisor == '0) begin
                next_Quotient = '1;
                next_Dividend = dividend;
                next_DividendShifter = '0;
                next_Divisor = '0;
                next_QuontientNegative = '0;
                next_RemnantNegative = '0;
                next_Counter = '0;
                next_State = State_Done;            
            end
            else if (isSigned && dividend[N-1] == 1'b1 && dividend[N-2:0] == '0 && divisor == '1) begin
                // for 32 bit, dividend == 32'h80000000 && divisor == 32'hffffffff
                next_Quotient = dividend;
                next_Dividend = '0;
                next_DividendShifter = '0;
                next_Divisor = '0;
                next_QuontientNegative = '0;
                next_RemnantNegative = '0;
                next_Counter = '0;
                next_State = State_Done;
            end
            else begin
                next_Quotient = '0;
                next_Dividend = absDividend[N];
                next_DividendShifter = absDividend[N-1:0];
                next_Divisor = absDivisor;
                next_QuontientNegative = isSigned ? (dividend[N-1] ^ divisor[N-1]) : 1'b0;
                next_RemnantNegative = isSigned ? dividend[N-1] : 1'b0;
                next_Counter = '0;
                next_State = State_Process;
            end
        end
        else if (reg_State == State_Process) begin
            next_Quotient = {reg_Quotient[N-2:0], cmpResult};
            next_DividendShifter = (reg_DividendShifter << 1);
            next_Divisor = reg_Divisor;
            next_QuontientNegative = reg_QuontientNegative;
            next_RemnantNegative = reg_RemnantNegative;

            if (reg_Counter < N) begin
                next_Dividend = {subResult[N-2:0], reg_DividendShifter[N-1]};
                next_Counter = reg_Counter + 1;
                next_State = State_Process;
            end
            else begin
                next_Dividend = subResult;
                next_Counter = reg_Counter;
                next_State = State_Done;
            end
        end
        else begin
            next_Quotient = '0;
            next_Dividend = '0;
            next_DividendShifter = '0;
            next_Divisor = '0;
            next_QuontientNegative = '0;
            next_RemnantNegative = '0;
            next_Counter = '0;
            next_State = State_Init;
        end
    end

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            reg_Quotient <= '0;
            reg_Dividend <= '0;
            reg_DividendShifter <= '0;
            reg_Divisor <= '0;
            reg_QuontientNegative <= '0;
            reg_RemnantNegative = '0;
            reg_Counter <= '0;
            reg_State <= State_Init;
        end
        else if (stall) begin
            reg_Quotient <= reg_Quotient;
            reg_Dividend <= reg_Dividend;
            reg_DividendShifter <= reg_DividendShifter;
            reg_Divisor <= reg_Divisor;
            reg_QuontientNegative <= reg_QuontientNegative;
            reg_RemnantNegative = reg_RemnantNegative;
            reg_Counter <= reg_Counter;
            reg_State <= reg_State;
        end
        else begin
            reg_Quotient <= next_Quotient;
            reg_Dividend <= next_Dividend;
            reg_DividendShifter <= next_DividendShifter;
            reg_Divisor <= next_Divisor;
            reg_QuontientNegative <= next_QuontientNegative;
            reg_RemnantNegative = next_RemnantNegative;
            reg_Counter <= next_Counter;
            reg_State <= next_State;
        end
    end
endmodule
