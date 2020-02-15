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

module SqrtUnit #(
    parameter WIDTH = 16
)(
    output logic [WIDTH-1:0] sqrt,
    output logic [WIDTH-1:0] remnant,
    output logic done,
    input logic enable,
    input logic [WIDTH*2-1:0] src,
    input logic flush,
    input logic clk,
    input logic rst
);
    typedef logic [$clog2(WIDTH+1)-1:0] _counter_t;

    // Regs
    _counter_t reg_counter;
    logic [WIDTH*2-1:0] reg_shifted_src;
    logic [WIDTH-1:0] reg_sqrt;
    logic [WIDTH-1:0] reg_remnant;

    // Subtract
    logic [WIDTH+1:0] sub_src1;
    logic [WIDTH+1:0] sub_src2;
    logic [WIDTH+1:0] sub_result;
    logic sub_result_sign;
    always_comb begin
        sub_src1 = {reg_remnant, (reg_counter == WIDTH) ? src[WIDTH*2-1:WIDTH*2-2] : reg_shifted_src[WIDTH*2-1:WIDTH*2-2]};
        sub_src2 = {reg_sqrt, 2'b01};
        sub_result = sub_src1 - sub_src2;
        sub_result_sign = sub_result[WIDTH+1];
    end

    // Next reg values
    _counter_t next_counter;
    logic [WIDTH*2-1:0] next_shifted_src;
    logic [WIDTH-1:0] next_sqrt;
    logic [WIDTH-1:0] next_remnant;
    always_comb begin
        if (!enable || flush || reg_counter == '0) begin
            next_counter = WIDTH;
            next_shifted_src = '0;
            next_sqrt = '0;
            next_remnant = '0;
        end
        else begin
            next_counter = reg_counter - 1;
            next_shifted_src = (reg_counter == WIDTH) ? src << 2 : reg_shifted_src << 2;
            next_sqrt = {reg_sqrt[WIDTH-2:0], ~sub_result_sign};
            next_remnant = sub_result_sign ? sub_src1[WIDTH-1:0] : sub_result[WIDTH-1:0];
        end
    end

    // Output
    always_comb begin
        sqrt = reg_sqrt;
        remnant = reg_remnant;
        done = reg_counter == '0;
    end

    // FF
    always_ff @(posedge clk) begin
        if (rst) begin
            reg_counter <= WIDTH;
            reg_shifted_src <= '0;
            reg_sqrt <= '0;
            reg_remnant <= '0;
        end
        else begin
            reg_counter <= next_counter;
            reg_shifted_src <= next_shifted_src;
            reg_sqrt <= next_sqrt;
            reg_remnant <= next_remnant;
        end
    end
endmodule
