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
 * 1-RW multi-bank memory
 * Read / write operations take 1 cycle.
 * Block RAM will be used for FPGA.
 */
module MultiBankBlockRam #(
    parameter DATA_WIDTH_PER_BANK,
    parameter BANK_COUNT,
    parameter INDEX_WIDTH
)(
    output  logic [BANK_COUNT-1:0][DATA_WIDTH_PER_BANK-1:0] readValue,
    input   logic [INDEX_WIDTH-1:0] index,
    input   logic [BANK_COUNT-1:0][DATA_WIDTH_PER_BANK-1:0] writeValue,
    input   logic [BANK_COUNT-1:0] writeMask,
    input   logic clk
);
    genvar i;
    generate
        // Data array instance
        for (i = 0; i < BANK_COUNT; i++) begin : banks
            BlockRam #(
                .DATA_WIDTH(DATA_WIDTH_PER_BANK),
                .INDEX_WIDTH(INDEX_WIDTH)
            ) body (
                .readValue(readValue[i]),
                .index(index),
                .writeValue(writeValue[i]),
                .writeEnable(writeMask[i]),
                .clk
            );
        end
    endgenerate
endmodule
