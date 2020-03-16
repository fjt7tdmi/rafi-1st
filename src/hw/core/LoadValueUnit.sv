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

import OpTypes::*;
import CacheTypes::*;

module LoadValueUnit #(
    parameter LINE_SIZE = DCACHE_LINE_SIZE,
    parameter LINE_WIDTH = LINE_SIZE * 8,
    parameter ADDR_WIDTH = $clog2(LINE_SIZE)
)(
    output uint64_t result,
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [LINE_WIDTH-1:0] line,
    input LoadStoreType loadStoreType
);
    function automatic uint64_t RightShift(logic [LINE_WIDTH-1:0] value, logic [ADDR_WIDTH-1:0] shift);
        int8_t [LINE_SIZE-1:0] bytes;
        int8_t [7:0] shifted_bytes;

        bytes = value;

        for (int i = 0; i < 8; i++) begin
            /* verilator lint_off WIDTH */
            if (shift + i < LINE_SIZE) begin
                shifted_bytes[i] = bytes[shift + i];
            end
            else begin
                shifted_bytes[i] = '0;
            end
        end

        return shifted_bytes;
    endfunction

    function automatic uint64_t Extend(uint64_t value, LoadStoreType loadStoreType);
        unique case(loadStoreType)
        LoadStoreType_Byte: begin
            if (value[7]) begin
                return {56'hffff_ffff_ffff_ff, value[7:0]};
            end
            else begin
                return {56'h0000_0000_0000_00, value[7:0]};
            end
        end
        LoadStoreType_HalfWord: begin
            if (value[15]) begin
                return {48'hffff_ffff_ffff, value[15:0]};
            end
            else begin
                return {48'h0000_0000_0000, value[15:0]};
            end
        end
        LoadStoreType_Word: begin
            if (value[31]) begin
                return {32'hffff_ffff, value[31:0]};
            end
            else begin
                return {32'h0000_0000, value[31:0]};
            end
        end
        LoadStoreType_DoubleWord: begin
            return value;
        end
        LoadStoreType_UnsignedByte: begin
            return {56'h0000_0000_0000_00, value[7:0]};
        end
        LoadStoreType_UnsignedHalfWord: begin
            return {48'h0000_0000_0000, value[15:0]};
        end
        LoadStoreType_UnsignedWord: begin
            return {32'h0000_0000, value[31:0]};
        end
        LoadStoreType_FpWord: begin
            return {32'hffff_ffff, value[31:0]};
        end
        default: return '0;
        endcase
    endfunction

    uint64_t shifted_value;
    always_comb begin
        shifted_value = RightShift(line, addr);
    end

    always_comb begin
        result = Extend(shifted_value, loadStoreType);
    end
endmodule
