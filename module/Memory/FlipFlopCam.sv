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
 * 1R1W CAM
 * Read operation take 0 cycle.
 * Write operation take 1 cycle.
 * When a key is written and read at the same time, writeValue will be bypassed to readValue.
 * D-FF will be used for FPGA.
 */
module FlipFlopCam #(
    parameter KeyWidth,
    parameter ValueWidth,
    parameter IndexWidth
)(
    output  logic                   hit,
    output  logic [ValueWidth-1:0]  readValue,
    output  logic [IndexWidth-1:0]  readIndex,
    input   logic [KeyWidth-1:0]    readKey,
    input   logic                   writeEnable,
    input   logic [IndexWidth-1:0]  writeIndex,
    input   logic [KeyWidth-1:0]    writeKey,
    input   logic [ValueWidth-1:0]  writeValue,
    input   logic                   clear,
    input   logic                   clk,
    input   logic                   rst
);
    localparam EntryCount = 1 << IndexWidth;

    typedef logic [KeyWidth-1:0]    _key_t;
    typedef logic [ValueWidth-1:0]  _value_t;
    typedef logic [IndexWidth-1:0]  _index_t;

    // Functions
    function automatic _index_t encodeIndex(logic [EntryCount-1:0] value);
        /* verilator lint_off WIDTH */
        for (int i = 0; i < EntryCount; i++) begin
            if (value[i]) begin
                return i;
            end
        end
        return 0;
    endfunction

    // Registers
    logic                   valid[EntryCount];
    logic [KeyWidth-1:0]    key[EntryCount];
    logic [ValueWidth-1:0]  value[EntryCount];

    // Wires
    logic [EntryCount-1:0]  hits;

    always_comb begin
        for (int i = 0; i < EntryCount; i++) begin
            hits[i] = valid[i] && (readKey == key[i]);
        end

        readIndex = encodeIndex(hits);

        hit = !rst && !clear && (|hits);
        if (writeEnable && readKey == writeKey) begin
            readValue = writeValue;
        end
        else begin
            readValue = value[readIndex];
        end
    end

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            for (int i = 0; i < EntryCount; i++) begin
                valid[i] <= 0;
                key[i] <= '0;
            end
        end
        else begin
            if (writeEnable) begin
                valid[writeIndex] <= 1;
                key[writeIndex] <= writeKey;
                value[writeIndex] <= writeValue;
            end
        end
    end
endmodule

