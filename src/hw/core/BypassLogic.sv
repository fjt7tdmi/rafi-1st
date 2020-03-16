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

module IntBypassLogic(
    IntBypassLogicIF.BypassLogic bus,
    PipelineControllerIF.BypassLogic ctrl,
    input clk,
    input rst
);
    typedef logic [$clog2(BYPASS_DEPTH)-1:0] _index_t;

    typedef struct packed {
        logic valid;
        reg_addr_t addr;
        word_t value;
    } PipelineEntry;

    // Functions
    function automatic _index_t EncodeIndex(logic [BYPASS_DEPTH-1:0] depth);
        /* verilator lint_off WIDTH */
        for (int i = 0; i < BYPASS_DEPTH; i++) begin
            if (depth[i]) begin
                return i;
            end
        end
        return 0;
    endfunction

    // Registers
    PipelineEntry pipeline[BYPASS_DEPTH];

    // Wires
    logic hit[BYPASS_READ_PORT_COUNT];
    reg_addr_t read_addr[BYPASS_READ_PORT_COUNT];
    word_t read_value[BYPASS_READ_PORT_COUNT];

    logic [BYPASS_DEPTH-1:0] cam_hits[BYPASS_READ_PORT_COUNT];
    _index_t cam_index[BYPASS_READ_PORT_COUNT];

    always_comb begin
        read_addr[0] = bus.readAddr1;
        read_addr[1] = bus.readAddr2;

        bus.readValue1 = read_value[0];
        bus.readValue2 = read_value[1];
        bus.hit1 = hit[0];
        bus.hit2 = hit[1];
    end

    // Bypass CAM
    always_comb begin
        for (int i = 0; i < BYPASS_READ_PORT_COUNT; i++) begin
            for (int j = 0; j < BYPASS_DEPTH; j++) begin
                cam_hits[i][j] = pipeline[j].valid && (pipeline[j].addr == read_addr[i]);
            end
            cam_index[i] = EncodeIndex(cam_hits[i]);

            hit[i] = |(cam_hits[i]);
            if (read_addr[i] == '0) begin
                // zero register
                read_value[i] = '0;
            end
            else if (|(cam_hits[i])) begin
                read_value[i] = pipeline[cam_index[i]].value;
            end
            else begin
                // bypass failure
                read_value[i] = '0;
            end
        end
    end

    // Bypass Pipeline
    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            for (int i = 0; i < BYPASS_DEPTH; i++) begin
                pipeline[i] <= '0;
            end
        end
        else if (ctrl.bypassStall) begin
            for (int i = 0; i < BYPASS_DEPTH; i++) begin
                pipeline[i] <= pipeline[i];
            end
        end
        else begin
            pipeline[0].valid <= bus.writeEnable;
            pipeline[0].addr <= bus.writeAddr;
            pipeline[0].value <= bus.writeValue;

            for (int i = 1; i < BYPASS_DEPTH; i++) begin
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
    parameter READ_PORT_COUNT = 3;

    typedef logic [$clog2(BYPASS_DEPTH)-1:0] _index_t;

    typedef struct packed {
        logic valid;
        reg_addr_t addr;
        uint64_t value;
    } PipelineEntry;

    // Functions
    function automatic _index_t EncodeIndex(logic [BYPASS_DEPTH-1:0] depth);
        /* verilator lint_off WIDTH */
        for (int i = 0; i < BYPASS_DEPTH; i++) begin
            if (depth[i]) begin
                return i;
            end
        end
        return 0;
    endfunction

    // Registers
    PipelineEntry pipeline[BYPASS_DEPTH];

    // Wires
    logic hit[READ_PORT_COUNT];
    reg_addr_t read_addr[READ_PORT_COUNT];
    uint64_t read_value[READ_PORT_COUNT];

    logic [BYPASS_DEPTH-1:0] cam_hits[READ_PORT_COUNT];
    _index_t cam_index[READ_PORT_COUNT];

    always_comb begin
        read_addr[0] = bus.readAddr1;
        read_addr[1] = bus.readAddr2;
        read_addr[2] = bus.readAddr3;

        bus.readValue1 = read_value[0];
        bus.readValue2 = read_value[1];
        bus.readValue3 = read_value[2];
        bus.hit1 = hit[0];
        bus.hit2 = hit[1];
        bus.hit3 = hit[2];
    end

    // Bypass CAM
    always_comb begin
        for (int i = 0; i < READ_PORT_COUNT; i++) begin
            for (int j = 0; j < BYPASS_DEPTH; j++) begin
                cam_hits[i][j] = pipeline[j].valid && (pipeline[j].addr == read_addr[i]);
            end
            cam_index[i] = EncodeIndex(cam_hits[i]);

            hit[i] = |(cam_hits[i]);
            if (|(cam_hits[i])) begin
                read_value[i] = pipeline[cam_index[i]].value;
            end
            else begin
                // bypass failure
                read_value[i] = '0;
            end
        end
    end

    // Bypass Pipeline
    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            for (int i = 0; i < BYPASS_DEPTH; i++) begin
                pipeline[i] <= '0;
            end
        end
        else if (ctrl.bypassStall) begin
            for (int i = 0; i < BYPASS_DEPTH; i++) begin
                pipeline[i] <= pipeline[i];
            end
        end
        else begin
            pipeline[0].valid <= bus.writeEnable;
            pipeline[0].addr <= bus.writeAddr;
            pipeline[0].value <= bus.writeValue;

            for (int i = 1; i < BYPASS_DEPTH; i++) begin
                pipeline[i] <= pipeline[i-1];
            end
        end
    end
endmodule
