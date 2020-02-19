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
 * When rstIn is triggerd, rstOut is asserted for ${RESET_CYCLE} cycles.
 */
module ResetSequencer #(
    parameter RESET_CYCLE
)(
    output logic rstOut,
    input logic rstIn,
    input logic clk
);
    localparam COUNTER_WIDTH = $clog2(RESET_CYCLE + 1);
    localparam COUNTER_MAX = RESET_CYCLE[COUNTER_WIDTH-1:0];

    // Registers
    logic [COUNTER_WIDTH-1:0] reg_counter;

    // Wires
    logic [COUNTER_WIDTH-1:0] next_counter;

    always_comb begin
        rstOut = (reg_counter != '0);

        if (rstIn) begin
            next_counter = COUNTER_MAX;
        end
        else if (reg_counter != '0) begin
            next_counter = reg_counter - 1;
        end
        else begin
            next_counter = '0;
        end
    end

    always_ff @(posedge clk) begin
        reg_counter <= next_counter;
    end
endmodule
