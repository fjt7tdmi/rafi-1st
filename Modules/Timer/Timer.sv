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

module Timer (
    output logic irq,
    output logic [31:0] readData,
    input logic [3:0] addr,
    input logic [31:0] writeData,
    input logic readEnable,
    input logic writeEnable,
    input logic clk,
    input logic rst
);
    // Registers
    logic [63:0] mtime;
    logic [63:0] mtimecmp;

    // Wires
    logic [63:0] inc_mtime;
    logic [63:0] next_mtime;
    logic [63:0] next_mtimecmp;

    always_comb begin
        irq = (mtime >= mtimecmp) ? 1 : 0;

        unique case(addr[3:2])
        0: readData = mtime[31:0];
        1: readData = mtime[63:32];
        2: readData = mtimecmp[31:0];
        3: readData = mtimecmp[63:32];
        endcase

        inc_mtime = mtime + 1;

        next_mtime[31:0]     = (writeEnable && addr[3:2] == 2'b00) ? writeData : inc_mtime[31:0];
        next_mtime[63:32]    = (writeEnable && addr[3:2] == 2'b01) ? writeData : inc_mtime[63:32];
        next_mtimecmp[31:0]  = (writeEnable && addr[3:2] == 2'b10) ? writeData : mtimecmp[31:0];
        next_mtimecmp[63:32] = (writeEnable && addr[3:2] == 2'b11) ? writeData : mtimecmp[63:32];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            mtime <= '0;
            mtimecmp <= '0;
        end
        else begin
            mtime <= next_mtime;
            mtimecmp <= next_mtimecmp;
        end
    end
endmodule
