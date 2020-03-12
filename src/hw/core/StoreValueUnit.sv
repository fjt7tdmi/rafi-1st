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

module StoreValueUnit #(
    parameter LINE_SIZE = DCACHE_LINE_SIZE,
    parameter LINE_WIDTH = LINE_SIZE * 8,
    parameter ADDR_WIDTH = $clog2(LINE_SIZE)
)(
    output logic [LINE_WIDTH-1:0] line,
    output logic [LINE_SIZE-1:0] writeMask,
    input logic [ADDR_WIDTH-1:0] addr,
    input uint64_t value,
    input LoadStoreType loadStoreType
);
    function automatic logic [LINE_WIDTH-1:0] LeftShift(uint64_t value, logic [ADDR_WIDTH-1:0] shift);
        int8_t [7:0] bytes;
        int8_t [LINE_SIZE-1:0] shiftedBytes;

        bytes = value;

        for (int i = 0; i < LINE_SIZE; i++) begin
            /* verilator lint_off WIDTH */
            if (shift <= i) begin
                shiftedBytes[i] = bytes[i - shift];
            end
            else begin
                shiftedBytes[i] = '0;
            end
        end

        return shiftedBytes;
    endfunction

    function automatic logic [LINE_SIZE-1:0] MakeWriteMask(logic [ADDR_WIDTH-1:0] shift, LoadStoreType loadStoreType);
        logic [LINE_SIZE-1:0] mask;

        /* verilator lint_off WIDTH */
        if (loadStoreType inside {LoadStoreType_Byte, LoadStoreType_UnsignedByte}) begin
            mask = 8'b0000_0001;
        end
        else if (loadStoreType inside {LoadStoreType_HalfWord, LoadStoreType_UnsignedHalfWord}) begin
            mask = 8'b0000_0011;
        end
        else if (loadStoreType inside {LoadStoreType_Word, LoadStoreType_UnsignedWord, LoadStoreType_FpWord}) begin
            mask = 8'b0000_1111;
        end
        else if (loadStoreType inside {LoadStoreType_DoubleWord}) begin
            mask = 8'b1111_1111;
        end
        else begin
            mask = '0;
        end

        return mask << shift;
    endfunction

    always_comb begin
        line = LeftShift(value, addr);
        writeMask = MakeWriteMask(addr, loadStoreType);
    end
endmodule
