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

import RafiTypes::*;

module IntRegFile(
    IntRegFileIF.RegFile bus,
    input logic clk,
    input logic rst
);
    word_t body[REG_FILE_SIZE] /* verilator public */;

    always_comb begin
        bus.readValue1 = body[bus.readAddr1];
        bus.readValue2 = body[bus.readAddr2];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < REG_FILE_SIZE; i++) begin
                body[i] <= 0;
            end
        end
        else begin
            if (bus.writeEnable && bus.writeAddr != 0) begin
                body[bus.writeAddr] <= bus.writeValue;
            end
        end
    end
endmodule

module FpRegFile(
    FpRegFileIF.RegFile bus,
    input logic clk,
    input logic rst
);
    uint64_t body[REG_FILE_SIZE] /* verilator public */;

    always_comb begin
        bus.readValue1 = body[bus.readAddr1];
        bus.readValue2 = body[bus.readAddr2];
        bus.readValue3 = body[bus.readAddr3];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < REG_FILE_SIZE; i++) begin
                body[i] <= 0;
            end
        end
        else begin
            if (bus.writeEnable) begin
                body[bus.writeAddr] <= bus.writeValue;
            end
        end
    end
endmodule
