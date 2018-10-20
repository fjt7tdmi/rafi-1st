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
module MulUnitTest;
    // Constant parameter
    parameter MAX_CYCLE = 10000;
    parameter HALF_CYCLE_TIME = 5;
    parameter ONE_CYCLE_TIME = HALF_CYCLE_TIME * 2;
    parameter RESET_TIME = ONE_CYCLE_TIME * 2;

    logic done;
    int32_t result;
    logic enable;
    logic high;
    logic srcSigned1;
    logic srcSigned2;
    int32_t src1;
    int32_t src2;

    logic clk;
    logic rst;

    MulUnit m_MulUnit (
        .done,
        .result,
        .high,
        .srcSigned1,
        .srcSigned2,
        .src1,
        .src2,
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
        src1 = operand1;
        src2 = operand2;

        for (int i = 0; i < 8; i++) begin

            #1;
            assert(!done);

            enable = 1'b1;

            srcSigned1 = i[0];
            srcSigned2 = i[1];
            high = i[2];

            while (!done) begin
                @(posedge clk); #1;
            end

            if (srcSigned1 && srcSigned2) begin
                expectedResult = $signed(src1) * $signed(src2);
            end
            else if (srcSigned1 && !srcSigned2) begin
                expectedResult = $signed(src1) * $signed({1'b0, src2});
            end
            else if (!srcSigned1 && srcSigned2) begin
                expectedResult = $signed({1'b0, src1}) * $signed(src2);
            end
            else begin
                expectedResult = $signed({1'b0, src1}) * $signed({1'b0, src2});
            end

            if (high) begin
                assert(result == expectedResult[63:32]);
            end
            else begin
                assert(result == expectedResult[31:0]);
            end
            
            #1;
            enable = 1'b0;

            @(posedge clk); #1;
        end
    endtask

    // test
    initial begin
        enable = '0;
        high = '0;
        srcSigned1 = '0;
        srcSigned2 = '0;
        src1 = '0;
        src2 = '0;

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

        $finish;
    end
endmodule
