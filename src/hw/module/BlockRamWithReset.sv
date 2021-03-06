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
 * 1-RW memory
 * Read / write operations take 1 cycle.
 * Block RAM will be used for FPGA.
 * All entries are cleard on reset.
 * Reset sequence takes ${EntryCount} cycle.
 */
module BlockRamWithReset #(
    parameter DATA_WIDTH,
    parameter INDEX_WIDTH
)(
    output logic [DATA_WIDTH-1:0] readValue,
    input logic [INDEX_WIDTH-1:0] index,
    input logic [DATA_WIDTH-1:0] writeValue,
    input logic writeEnable,
    input logic clk,
    input logic rst
);
    localparam EntryCount = 1 << INDEX_WIDTH;

    // RAM
    logic [DATA_WIDTH-1:0] body[EntryCount];

    // Registers
    logic [INDEX_WIDTH-1:0] reg_reset_index;

    // Wires
    logic body_write_enable;
    logic [DATA_WIDTH-1:0] body_write_value;
    logic [INDEX_WIDTH-1:0] body_write_index;
    logic [INDEX_WIDTH-1:0] next_reset_index;


    always_comb begin
        if (rst) begin
            body_write_enable = 1;
            body_write_value = '0;
            body_write_index = reg_reset_index;
            next_reset_index = reg_reset_index + 1;
        end
        else begin
            body_write_enable = writeEnable;
            body_write_value = writeValue;
            body_write_index = index;
            next_reset_index = '0;
        end
    end

    always_ff @(posedge clk) begin
        // RAM
        readValue <= body[index];
        if (body_write_enable) begin
            body[body_write_index] <= body_write_value;
        end

        // Registers
        reg_reset_index <= next_reset_index;
    end
endmodule
