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

module DivUnit32 (
    output  logic done,
    output  logic [31:0] quotient,
    output  logic [31:0] remnant,
    input   logic isSigned,
    input   logic [31:0] dividend,
    input   logic [31:0] divisor,
    input   logic enable,
    input   logic stall,
    input   logic flush,
    input   logic clk,
    input   logic rst
);
    DivUnit #(
        .N(32)
    ) m_DivUnit (
        .done(done),
        .quotient(quotient),
        .remnant(remnant),
        .isSigned(isSigned),
        .dividend(dividend),
        .divisor(divisor),
        .enable(enable),
        .stall(stall),
        .flush(flush),
        .clk(clk),
        .rst(rst)
    );
endmodule
