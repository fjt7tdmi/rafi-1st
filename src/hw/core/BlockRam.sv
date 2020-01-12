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
    parameter DataWidth,
    parameter IndexWidth
)(
    output logic [DataWidth-1:0] readValue,
    input logic [IndexWidth-1:0] index,
    input logic [DataWidth-1:0] writeValue,
    input logic writeEnable,
    input logic clk
);
    localparam EntryCount = 1 << IndexWidth;

    // RAM
    logic [DataWidth-1:0] body[EntryCount];

    always_ff @(posedge clk) begin
        readValue <= body[index];
        if (writeEnable) begin
            body[index] <= writeValue;
        end
    end
endmodule

/*
 * 1-RW memory
 * Read / write operations take 1 cycle.
 * Block RAM will be used for FPGA.
 * All entries are cleard on reset.
 * Reset sequence takes ${EntryCount} cycle.
 */
module BlockRamWithReset #(
    parameter DataWidth,
    parameter IndexWidth
)(
    output logic [DataWidth-1:0] readValue,
    input logic [IndexWidth-1:0] index,
    input logic [DataWidth-1:0] writeValue,
    input logic writeEnable,
    input logic clk,
    input logic rst
);
    localparam EntryCount = 1 << IndexWidth;

    // RAM
    logic [DataWidth-1:0] body[EntryCount];

    // Registers
    logic [IndexWidth-1:0] r_ResetIndex;

    // Wires
    logic bodyWriteEnable;
    logic [DataWidth-1:0] bodyWriteValue;
    logic [IndexWidth-1:0] bodyWriteIndex;
    logic [IndexWidth-1:0] nextResetIndex;


    always_comb begin
        if (rst) begin
            bodyWriteEnable = 1;
            bodyWriteValue = '0;
            bodyWriteIndex = r_ResetIndex;
            nextResetIndex = r_ResetIndex + 1;
        end
        else begin
            bodyWriteEnable = writeEnable;
            bodyWriteValue = writeValue;
            bodyWriteIndex = index;
            nextResetIndex = '0;
        end
    end

    always_ff @(posedge clk) begin
        // RAM
        readValue <= body[index];
        if (bodyWriteEnable) begin
            body[bodyWriteIndex] <= bodyWriteValue;
        end

        // Registers
        r_ResetIndex <= nextResetIndex;
    end
endmodule

/*
 * 1-RW multi-bank memory
 * Read / write operations take 1 cycle.
 * Block RAM will be used for FPGA.
 */
module MultiBankBlockRam #(
    parameter DataWidthPerBank,
    parameter BankCount,
    parameter IndexWidth
)(
    output  logic [BankCount-1:0][DataWidthPerBank-1:0] readValue,
    input   logic [IndexWidth-1:0] index,
    input   logic [BankCount-1:0][DataWidthPerBank-1:0] writeValue,
    input   logic [BankCount-1:0] writeMask,
    input   logic clk
);
    genvar i;
    generate
        // Data array instance
        for (i = 0; i < BankCount; i++) begin : banks
            BlockRam #(
                .DataWidth(DataWidthPerBank),
                .IndexWidth(IndexWidth)
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
