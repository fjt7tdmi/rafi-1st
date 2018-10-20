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

module InternalMemory #(
    parameter Capacity,
    parameter LineSize,
    parameter LineWidth = LineSize * ByteWidth,
    parameter EntryIndexWidth = $clog2(Capacity) - $clog2(LineSize)
)(
    output  logic done,
    output  logic [LineWidth-1:0] readValue,
    input   logic [EntryIndexWidth-1:0] addr,
    input   logic enable,
    input   logic isWrite,
    input   logic [LineWidth-1:0] writeValue,
    input   logic clk,
    input   logic rst
);
    localparam EntryCount = 1 << EntryIndexWidth;

    // Body
    logic [LineWidth-1:0] body[EntryCount];

    // Registers
    logic r_Enable;

    // Wires
    logic [EntryIndexWidth-1:0] index;

    always_comb begin
        index = addr[EntryIndexWidth-1:0];

        done = r_Enable;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_Enable <= 0;
        end
        else begin
            r_Enable <= enable;
        end
    end

    always_ff @(posedge clk) begin
        readValue <= body[index];
        if (enable && isWrite) begin
            body[index] <= writeValue;
        end
    end

endmodule