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

import ProcessorTypes::*;

module IntBypassLogic(
    IntBypassLogicIF.BypassLogic bus,
    PipelineControllerIF.BypassLogic ctrl,
    input clk,
    input rst
);
    typedef logic [$clog2(BypassDepth)-1:0] _index_t;

    typedef struct packed {
        logic valid;
        reg_addr_t addr;
        word_t value;
    } PipelineEntry;

    // Functions
    function automatic _index_t encodeIndex(logic [BypassDepth-1:0] depth);
        /* verilator lint_off WIDTH */
        for (int i = 0; i < BypassDepth; i++) begin
            if (depth[i]) begin
                return i;
            end
        end
        return 0;
    endfunction

    // Registers
    PipelineEntry pipeline[BypassDepth];

    // Wires
    logic hit[BypassReadPortCount];
    reg_addr_t readAddr[BypassReadPortCount];
    word_t readValue[BypassReadPortCount];

    logic [BypassDepth-1:0] camHits[BypassReadPortCount];
    _index_t camIndex[BypassReadPortCount];

    always_comb begin
        readAddr[0] = bus.readAddr1;
        readAddr[1] = bus.readAddr2;

        bus.readValue1 = readValue[0];
        bus.readValue2 = readValue[1];
        bus.hit1 = hit[0];
        bus.hit2 = hit[1];
    end

    // Bypass CAM
    always_comb begin
        for (int i = 0; i < BypassReadPortCount; i++) begin
            for (int j = 0; j < BypassDepth; j++) begin
                camHits[i][j] = pipeline[j].valid && (pipeline[j].addr == readAddr[i]);
            end
            camIndex[i] = encodeIndex(camHits[i]);

            hit[i] = |(camHits[i]);
            if (readAddr[i] == '0) begin
                // zero register
                readValue[i] = '0;
            end
            else if (|(camHits[i])) begin
                readValue[i] = pipeline[camIndex[i]].value;
            end
            else begin
                // bypass failure
                readValue[i] = '0;
            end
        end
    end

    // Bypass Pipeline
    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            for (int i = 0; i < BypassDepth; i++) begin
                pipeline[i] <= '0;
            end
        end
        else if (ctrl.bypassStall) begin
            for (int i = 0; i < BypassDepth; i++) begin
                pipeline[i] <= pipeline[i];
            end
        end
        else begin
            pipeline[0].valid <= bus.writeEnable;
            pipeline[0].addr <= bus.writeAddr;
            pipeline[0].value <= bus.writeValue;

            for (int i = 1; i < BypassDepth; i++) begin
                pipeline[i] <= pipeline[i-1];
            end
        end
    end
endmodule

module FpBypassLogic(
    FpBypassLogicIF.BypassLogic bus,
    PipelineControllerIF.BypassLogic ctrl,
    input clk,
    input rst
);
    typedef logic [$clog2(BypassDepth)-1:0] _index_t;

    typedef struct packed {
        logic valid;
        reg_addr_t addr;
        word_t value;
    } PipelineEntry;

    // Functions
    function automatic _index_t encodeIndex(logic [BypassDepth-1:0] depth);
        /* verilator lint_off WIDTH */
        for (int i = 0; i < BypassDepth; i++) begin
            if (depth[i]) begin
                return i;
            end
        end
        return 0;
    endfunction

    // Registers
    PipelineEntry pipeline[BypassDepth];

    // Wires
    logic hit[BypassReadPortCount];
    reg_addr_t readAddr[BypassReadPortCount];
    word_t readValue[BypassReadPortCount];

    logic [BypassDepth-1:0] camHits[BypassReadPortCount];
    _index_t camIndex[BypassReadPortCount];

    always_comb begin
        readAddr[0] = bus.readAddr1;
        readAddr[1] = bus.readAddr2;

        bus.readValue1 = readValue[0];
        bus.readValue2 = readValue[1];
        bus.hit1 = hit[0];
        bus.hit2 = hit[1];
    end

    // Bypass CAM
    always_comb begin
        for (int i = 0; i < BypassReadPortCount; i++) begin
            for (int j = 0; j < BypassDepth; j++) begin
                camHits[i][j] = pipeline[j].valid && (pipeline[j].addr == readAddr[i]);
            end
            camIndex[i] = encodeIndex(camHits[i]);

            hit[i] = |(camHits[i]);
            if (|(camHits[i])) begin
                readValue[i] = pipeline[camIndex[i]].value;
            end
            else begin
                // bypass failure
                readValue[i] = '0;
            end
        end
    end

    // Bypass Pipeline
    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            for (int i = 0; i < BypassDepth; i++) begin
                pipeline[i] <= '0;
            end
        end
        else if (ctrl.bypassStall) begin
            for (int i = 0; i < BypassDepth; i++) begin
                pipeline[i] <= pipeline[i];
            end
        end
        else begin
            pipeline[0].valid <= bus.writeEnable;
            pipeline[0].addr <= bus.writeAddr;
            pipeline[0].value <= bus.writeValue;

            for (int i = 1; i < BypassDepth; i++) begin
                pipeline[i] <= pipeline[i-1];
            end
        end
    end
endmodule
