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

/*
 * Module to assure asserting rst for specific cycles.
 * When rstIn is triggerd, rstOut is asserted for ${ResetCycle} cycles.
 */
module ResetSequencer #(
    parameter ResetCycle
)(
    output logic rstOut,
    input logic rstIn,
    input logic clk
);
    localparam CounterWidth = $clog2(ResetCycle + 1);

    // Registers
    logic [CounterWidth-1:0] r_Counter;

    // Wires
    logic [CounterWidth-1:0] nextCounter;

    always_comb begin
        rstOut = (r_Counter != '0);

        if (rstIn) begin
            nextCounter = ResetCycle;
        end
        else if (r_Counter != '0) begin
            nextCounter = r_Counter - 1;
        end
        else begin
            nextCounter = '0;
        end
    end

    always_ff @(posedge clk) begin
        r_Counter <= nextCounter;
    end
endmodule
