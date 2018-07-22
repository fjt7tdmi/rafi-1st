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

/*
 * Module to assure asserting rst for specific cycles.
 * When rstIn is triggerd, rstOut is asserted for ${ResetCycle} cycles.
 */
module DivUnitTest;
    // Constant parameter
    parameter MAX_CYCLE = 10000;
    parameter HALF_CYCLE_TIME = 5;
    parameter ONE_CYCLE_TIME = HALF_CYCLE_TIME * 2;
    parameter RESET_TIME = ONE_CYCLE_TIME * 2;

    logic done;
    int32_t quotient;
    int32_t remnant;

    logic isSigned;
    int32_t dividend;
    int32_t divisor;
    logic enable;

    logic clk;
    logic rst;

    DivUnit m_DivUnit (
        .done,
        .quotient,
        .remnant,
        .isSigned,
        .dividend,
        .divisor,
        .enable(enable),
        .stall('0),
        .flush('0),
        .clk,
        .rst
    );

    // rst
    initial begin
        $display("Reset asserted.");
        rst = 1;
        #RESET_TIME;
        #HALF_CYCLE_TIME;
        $display("Reset deasserted.");
        rst = 0;
    end

    // clk
    initial begin
        clk = 0;

        for (int i = 0; i < MAX_CYCLE; i++) begin
            clk = 1;
            #HALF_CYCLE_TIME;
            clk = 0;
            #HALF_CYCLE_TIME;
        end

        // Test not finished.
        $display("Test not finished. You should increase test cycle count.");
        assert(0);
    end

    longint expectedResult;
    task Test(int32_t operand1, int32_t operand2);
        dividend = operand1;
        divisor = operand2;

        assert(!done);
        enable = 1'b1;

        // Unsigned
        isSigned = '0;
        #1;

        while (!done) begin
            @(posedge clk); #1;
        end

        if (divisor == 32'h00000000) begin
            assert(quotient == 32'hffffffff);
        end
        else begin
            assert(quotient == $unsigned(dividend) / $unsigned(divisor));
        end

        if (divisor == 32'h00000000) begin
            assert(remnant == dividend);
        end
        else begin
            assert(remnant == $unsigned(dividend) % $unsigned(divisor));
        end

        @(posedge clk); #1;

        // Signed
        isSigned = '1;
        #1;

        while (!done) begin
            @(posedge clk); #1;
        end

        if (dividend == 32'h80000000 && divisor == 32'hffffffff) begin
            assert(quotient == 32'h80000000);
        end
        else if (divisor == 32'h00000000) begin
            assert(quotient == 32'hffffffff);
        end
        else begin
            assert(quotient == $signed(dividend) / $signed(divisor));
        end

        if (dividend == 32'h80000000 && divisor == 32'hffffffff) begin
            assert(remnant == 32'h00000000);
        end
        else if (divisor == 32'h00000000) begin
            assert(remnant == dividend);
        end
        else begin
            assert(remnant == $signed(dividend) % $signed(divisor));
        end

        #1;
        enable = 1'b0;

        @(posedge clk); #1;
    endtask

    // test
    initial begin
        enable = '0;
        isSigned = '0;
        dividend = '0;
        divisor = '0;

        while (rst) @(posedge clk);

        Test(32'h00000000, 32'h00000001);
        Test(32'h00000000, 32'h00000000);
        Test(32'h00000000, 32'h7fffffff);
        Test(32'h00000000, 32'h80000000);
        Test(32'h00000000, 32'hffffffff);
        Test(32'h00000001, 32'h00000000);
        Test(32'h00000001, 32'h00000001);
        Test(32'h00000001, 32'h7fffffff);
        Test(32'h00000001, 32'h80000000);
        Test(32'h00000001, 32'hffffffff);
        Test(32'h7fffffff, 32'h00000000);
        Test(32'h7fffffff, 32'h00000001);
        Test(32'h7fffffff, 32'h7fffffff);
        Test(32'h7fffffff, 32'h80000000);
        Test(32'h7fffffff, 32'hffffffff);
        Test(32'h80000000, 32'h00000001);
        Test(32'h80000000, 32'h00000000);
        Test(32'h80000000, 32'h7fffffff);
        Test(32'h80000000, 32'h80000000);
        Test(32'h80000000, 32'hffffffff);
        Test(32'hffffffff, 32'h00000000);
        Test(32'hffffffff, 32'h00000001);
        Test(32'hffffffff, 32'h7fffffff);
        Test(32'hffffffff, 32'h80000000);
        Test(32'hffffffff, 32'hffffffff);

        Test(32'h00001234, 32'h00005678);
        Test(32'h12340000, 32'h56780000);
        Test(32'h12345678, 32'h12345678);
        Test(32'h12345678, 32'habcdabcd);
        Test(32'habcdabcd, 32'habcdabcd);

        for (int i = 0; i < 256; i++) begin
            Test(32'h000000ff, i);
        end

        Test(32'd20, 32'd6);

        $finish;
    end
endmodule
