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

module BusAccessUnit (
    BusAccessUnitIF.BusAccessUnit core,
    output  logic [31:0] addr,
    output  logic select,
    output  logic enable,
    output  logic write,
    output  logic [31:0] wdata,
    input   logic [31:0] rdata,
    input   logic ready,
    input   logic irq,
    input   logic irqTimer,
    input   logic clk,
    input   logic rst
);
    localparam DCACHE_WORD_COUNT = DCACHE_LINE_SIZE / 4;
    localparam ICACHE_WORD_COUNT = ICACHE_LINE_SIZE / 4;

    typedef logic [$clog2(DCACHE_WORD_COUNT)-1:0] _dcache_word_index_t;
    typedef logic [$clog2(ICACHE_WORD_COUNT)-1:0] _icache_word_index_t;

    typedef enum logic [2:0]
    {
        State_Idle         = 3'h0,
        State_Reserved     = 3'h1,
        State_IoRead       = 3'h2,
        State_IoWrite      = 3'h3,
        State_DCacheRead   = 3'h4,
        State_DCacheWrite  = 3'h5,
        State_ICacheRead   = 3'h6,
        State_ICacheWrite  = 3'h7
    } State;

    typedef enum logic [1:0]
    {
        BusState_Idle   = 2'h0,
        BusState_Setup  = 2'h1,
        BusState_Access = 2'h2
    } BusState;

    // Registers
    State reg_state;
    BusState reg_bus_state;
    logic reg_done;
    _dcache_word_index_t reg_dcache_index;
    _icache_word_index_t reg_icache_index;
    int32_t [DCACHE_WORD_COUNT-1:0] reg_dcache_value;
    int32_t [ICACHE_WORD_COUNT-1:0] reg_icache_value;

    State next_state;
    BusState next_bus_state;
    logic next_done;
    _dcache_word_index_t next_dcache_index;
    _icache_word_index_t next_icache_index;
    int32_t [DCACHE_WORD_COUNT-1:0] next_dcache_value;
    int32_t [ICACHE_WORD_COUNT-1:0] next_icache_value;

    logic rdata_valid;
    always_comb begin
        rdata_valid = (reg_bus_state == BusState_Access) && ready;
    end

    // D$
    always_comb begin
        core.dcacheReadValue = reg_dcache_value;
        core.dcacheReadGrant = reg_done && (reg_state == State_DCacheRead);
        core.dcacheWriteGrant = reg_done && (reg_state == State_DCacheWrite);
    end

    // I$
    always_comb begin
        core.icacheReadValue = reg_icache_value;
        core.icacheReadGrant = reg_done && (reg_state == State_ICacheRead);
        core.icacheWriteGrant = reg_done && (reg_state == State_ICacheWrite);
    end

    // bus
    always_comb begin
        if (reg_state == State_DCacheRead || reg_state == State_DCacheWrite) begin
            addr = {core.dcacheAddr[(29 - $bits(reg_dcache_index)):0], reg_dcache_index, 2'b00};
            wdata = reg_dcache_value[reg_dcache_index];
        end
        else if (reg_state == State_ICacheRead || reg_state == State_ICacheWrite) begin
            addr = {core.icacheAddr[(29 - $bits(reg_icache_index)):0], reg_icache_index, 2'b00};
            wdata = reg_icache_value[reg_icache_index];
        end
        else begin
            addr = '0;
            wdata = '0;
        end

        select = (reg_bus_state == BusState_Setup || reg_bus_state == BusState_Access);
        enable = (reg_bus_state == BusState_Access);
        write = (reg_bus_state == BusState_Access) && (reg_state == State_DCacheWrite || reg_state == State_ICacheWrite);
    end

    // next
    always_comb begin
        unique case(reg_state)
            State_Idle: begin
                if (core.dcacheWriteReq) begin
                    next_state = State_DCacheWrite;
                end
                else if (core.dcacheReadReq) begin
                    next_state = State_DCacheRead;
                end
                else if (core.icacheWriteReq) begin
                    next_state = State_ICacheWrite;
                end
                else if (core.icacheReadReq) begin
                    next_state = State_ICacheRead;
                end
                else begin
                    next_state = State_Idle;
                end
            end
            default: begin
                next_state = reg_done ? State_Idle : reg_state;
            end
        endcase
    end

    always_comb begin
        if (reg_state == State_Idle || reg_done) begin
            next_bus_state = BusState_Idle;
        end
        else begin
            unique case(reg_bus_state)
                BusState_Idle: next_bus_state = BusState_Setup;
                BusState_Setup: next_bus_state = BusState_Access;
                BusState_Access: next_bus_state = ready ? BusState_Idle : reg_bus_state;
                default: next_bus_state = BusState_Setup;
            endcase
        end
    end

    always_comb begin
        if (reg_state == State_DCacheRead || reg_state == State_DCacheWrite) begin
            next_done = rdata_valid && (reg_dcache_index == _dcache_word_index_t'(DCACHE_WORD_COUNT - 1));
        end
        else if (reg_state == State_ICacheRead || reg_state == State_ICacheWrite) begin
            next_done = rdata_valid && (reg_icache_index == _icache_word_index_t'(ICACHE_WORD_COUNT - 1));
        end
        else begin
            next_done = 1'b0;
        end
    end

    always_comb begin
        if (reg_state == State_DCacheRead || reg_state == State_DCacheWrite) begin
            next_dcache_index = (reg_bus_state == BusState_Access && rdata_valid) ? reg_dcache_index + 1 : reg_dcache_index;
        end
        else begin
            next_dcache_index = '0;
        end

        if (reg_state == State_ICacheRead || reg_state == State_ICacheWrite) begin
            next_icache_index = (reg_bus_state == BusState_Access && rdata_valid) ? reg_icache_index + 1 : reg_icache_index;
        end
        else begin
            next_icache_index = '0;
        end
    end

    always_comb begin
        unique case(reg_state)
            State_Idle: begin
                next_dcache_value = (core.dcacheWriteReq) ? core.dcacheWriteValue : '0;
            end
            State_DCacheRead: begin
                for (int i = 0; i < DCACHE_WORD_COUNT; i++) begin
                    next_dcache_value[i] = (_dcache_word_index_t'(i) == reg_dcache_index && rdata_valid) ? rdata : reg_dcache_value[i];
                end
            end
            State_DCacheWrite: begin
                next_dcache_value = core.dcacheWriteValue;
            end
            default: begin
                next_dcache_value = '0;
            end
        endcase
    end

    always_comb begin
        unique case(reg_state)
            State_Idle: begin
                next_icache_value = (core.icacheWriteReq) ? core.icacheWriteValue : '0;
            end
            State_ICacheRead: begin
                for (int i = 0; i < ICACHE_WORD_COUNT; i++) begin
                    next_icache_value[i] = (_icache_word_index_t'(i) == reg_icache_index && rdata_valid) ? rdata : reg_icache_value[i];
                end
            end
            State_ICacheWrite: begin
                next_icache_value = core.icacheWriteValue;
            end
            default: begin
                next_icache_value = '0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_state <= State_Idle;
            reg_bus_state <= BusState_Idle;
            reg_done <= '0;
            reg_dcache_index <= '0;
            reg_icache_index <= '0;
            reg_dcache_value <= '0;
            reg_icache_value <= '0;
        end
        else begin
            reg_state <= next_state;
            reg_bus_state <= next_bus_state;
            reg_done <= next_done;
            reg_dcache_index <= next_dcache_index;
            reg_icache_index <= next_icache_index;
            reg_dcache_value <= next_dcache_value;
            reg_icache_value <= next_icache_value;
        end
    end
endmodule
