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
 */
module BlockRam #(
    parameter DATA_WIDTH,
    parameter INDEX_WIDTH
)(
    output logic [DATA_WIDTH-1:0] readValue,
    input logic [INDEX_WIDTH-1:0] index,
    input logic [DATA_WIDTH-1:0] writeValue,
    input logic writeEnable,
    input logic clk
);
    localparam EntryCount = 1 << INDEX_WIDTH;

    // RAM
    logic [DATA_WIDTH-1:0] body[EntryCount];

    always_ff @(posedge clk) begin
        readValue <= body[index];
        if (writeEnable) begin
            body[index] <= writeValue;
        end
    end
endmodule
