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

module DivUnit #(
    parameter N = 32
)(
    output  logic done,
    output  logic [N-1:0] quotient,
    output  logic [N-1:0] remnant,
    input   logic is_signed,
    input   logic [N-1:0] dividend,
    input   logic [N-1:0] divisor,
    input   logic enable,
    input   logic stall,
    input   logic flush,
    input   logic clk,
    input   logic rst
);
    // typedef
    typedef logic [N:0] _abs_t;
    typedef logic [$clog2(N+1)-1:0] _counter_t;

    typedef enum logic [1:0]
    {
        State_Init = 2'h0,
        State_Process = 2'h1,
        State_Done = 2'h2
    } State;

    // Functions
    function automatic _abs_t GetAbs(logic [N-1:0] val, logic is_signed);
        _abs_t exVal;

        if (is_signed) begin
            exVal = {val[N-1], val[N-1:0]};
        end
        else begin
            exVal = {1'b0, val[N-1:0]};
        end

        return (exVal[N] == 1'b1) ? (-exVal) : exVal;
    endfunction

    // Registers
    logic [N-1:0] reg_quotient;
    logic [N-1:0] reg_dividend_shifter;
    _abs_t reg_dividend;
    _abs_t reg_divisor;
    logic reg_quontient_negative;
    logic reg_remnant_negative;
    _counter_t reg_counter;
    State reg_state;

    // Wires
    logic [N-1:0] next_quotient;
    logic [N-1:0] next_dividend_shifter;
    _abs_t next_dividend;
    _abs_t next_divisor;
    logic next_quontient_negative;
    logic next_remnant_negative;
    _counter_t next_counter;
    State next_state;

    _abs_t abs_dividend;
    _abs_t abs_divisor;

    logic cmp_result;
    _abs_t sub_result;
    logic [N-1:0] div_result;

    always_comb begin
        abs_dividend = GetAbs(dividend, is_signed);
        abs_divisor = GetAbs(divisor, is_signed);

        cmp_result = (reg_dividend >= reg_divisor) ? 1'b1 : 1'b0;
        sub_result = cmp_result ? (reg_dividend - reg_divisor) : reg_dividend;
        div_result = reg_dividend[N-1:0];

        done = (reg_state == State_Done);
        quotient = reg_quontient_negative ? (-reg_quotient) : reg_quotient;
        remnant = reg_remnant_negative ? (-div_result) : div_result;

        if (reg_state == State_Init && enable) begin
            if (divisor == '0) begin
                next_quotient = '1;
                next_dividend = abs_dividend;
                next_dividend_shifter = '0;
                next_divisor = '0;
                next_quontient_negative = '0;
                next_remnant_negative = '0;
                next_counter = '0;
                next_state = State_Done;
            end
            else if (is_signed && dividend[N-1] == 1'b1 && dividend[N-2:0] == '0 && divisor == '1) begin
                // for 32 bit, dividend == 32'h80000000 && divisor == 32'hffffffff
                next_quotient = dividend;
                next_dividend = '0;
                next_dividend_shifter = '0;
                next_divisor = '0;
                next_quontient_negative = '0;
                next_remnant_negative = '0;
                next_counter = '0;
                next_state = State_Done;
            end
            else begin
                next_quotient = '0;
                next_dividend[N:1] = '0;
                next_dividend[0] = abs_dividend[N];
                next_dividend_shifter = abs_dividend[N-1:0];
                next_divisor = abs_divisor;
                next_quontient_negative = is_signed ? (dividend[N-1] ^ divisor[N-1]) : 1'b0;
                next_remnant_negative = is_signed ? dividend[N-1] : 1'b0;
                next_counter = '0;
                next_state = State_Process;
            end
        end
        else if (reg_state == State_Process) begin
            next_quotient = {reg_quotient[N-2:0], cmp_result};
            next_dividend_shifter = (reg_dividend_shifter << 1);
            next_divisor = reg_divisor;
            next_quontient_negative = reg_quontient_negative;
            next_remnant_negative = reg_remnant_negative;

            if (reg_counter < N) begin
                next_dividend = {sub_result[N-1:0], reg_dividend_shifter[N-1]};
                next_counter = reg_counter + 1;
                next_state = State_Process;
            end
            else begin
                next_dividend = sub_result;
                next_counter = reg_counter;
                next_state = State_Done;
            end
        end
        else begin
            next_quotient = '0;
            next_dividend = '0;
            next_dividend_shifter = '0;
            next_divisor = '0;
            next_quontient_negative = '0;
            next_remnant_negative = '0;
            next_counter = '0;
            next_state = State_Init;
        end
    end

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            reg_quotient <= '0;
            reg_dividend <= '0;
            reg_dividend_shifter <= '0;
            reg_divisor <= '0;
            reg_quontient_negative <= '0;
            reg_remnant_negative = '0;
            reg_counter <= '0;
            reg_state <= State_Init;
        end
        else if (stall) begin
            reg_quotient <= reg_quotient;
            reg_dividend <= reg_dividend;
            reg_dividend_shifter <= reg_dividend_shifter;
            reg_divisor <= reg_divisor;
            reg_quontient_negative <= reg_quontient_negative;
            reg_remnant_negative = reg_remnant_negative;
            reg_counter <= reg_counter;
            reg_state <= reg_state;
        end
        else begin
            reg_quotient <= next_quotient;
            reg_dividend <= next_dividend;
            reg_dividend_shifter <= next_dividend_shifter;
            reg_divisor <= next_divisor;
            reg_quontient_negative <= next_quontient_negative;
            reg_remnant_negative = next_remnant_negative;
            reg_counter <= next_counter;
            reg_state <= next_state;
        end
    end
endmodule
