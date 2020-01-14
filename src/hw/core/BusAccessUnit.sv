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
    localparam DCacheWordCount = DCacheLineSize / 4;
    localparam ICacheWordCount = ICacheLineSize / 4;

    typedef logic [$clog2(DCacheWordCount)-1:0] _dcache_word_index_t;
    typedef logic [$clog2(ICacheWordCount)-1:0] _icache_word_index_t;

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
    State state;
    BusState busState;
    logic done;
    _dcache_word_index_t dcWordIndex;
    _icache_word_index_t icWordIndex;
    int32_t [DCacheWordCount-1:0] dcValue;
    int32_t [ICacheWordCount-1:0] icValue;

    // Wires
    logic rdataValid;

    State nextState;
    BusState nextBusState;
    logic nextDone;
    _dcache_word_index_t nextDcWordIndex;
    _icache_word_index_t nextIcWordIndex;
    int32_t [DCacheWordCount-1:0] nextDcValue;
    int32_t [ICacheWordCount-1:0] nextIcValue;

    // D$
    always_comb begin
        core.dcReadValue = dcValue;
        core.dcReadGrant = done && (state == State_DCacheRead);
        core.dcWriteGrant = done && (state == State_DCacheWrite);
    end

    // I$
    always_comb begin
        core.icReadValue = icValue;
        core.icReadGrant = done && (state == State_ICacheRead);
        core.icWriteGrant = done && (state == State_ICacheWrite);
    end

    // bus
    always_comb begin
        if (state == State_DCacheRead || state == State_DCacheWrite) begin
            addr = {core.dcAddr[(29 - $bits(dcWordIndex)):0], dcWordIndex, 2'b00};
            wdata = dcValue[dcWordIndex];
        end
        else if (state == State_ICacheRead || state == State_ICacheWrite) begin
            addr = {core.icAddr[(29 - $bits(icWordIndex)):0], icWordIndex, 2'b00};
            wdata = icValue[icWordIndex];
        end
        else begin
            addr = '0;
            wdata = '0;
        end

        select = (busState == BusState_Setup || busState == BusState_Access);
        enable = (busState == BusState_Access);
        write = (busState == BusState_Access) && (state == State_DCacheWrite || state == State_ICacheWrite);
    end

    always_comb begin
        rdataValid = (busState == BusState_Access) && ready;
    end

    // next
    always_comb begin
        unique case(state)
            State_Idle: begin
                if (core.dcWriteReq) begin
                    nextState = State_DCacheWrite;
                end
                else if (core.dcReadReq) begin
                    nextState = State_DCacheRead;
                end
                else if (core.icWriteReq) begin
                    nextState = State_ICacheWrite;
                end
                else if (core.icReadReq) begin
                    nextState = State_ICacheRead;
                end
                else begin
                    nextState = State_Idle;
                end
            end
            default: begin
                nextState = done ? State_Idle : state;
            end
        endcase
    end

    always_comb begin
        if (state == State_Idle || done) begin
            nextBusState = BusState_Idle;
        end
        else begin
            unique case(busState)
                BusState_Idle: nextBusState = BusState_Setup;
                BusState_Setup: nextBusState = BusState_Access;
                BusState_Access: nextBusState = ready ? BusState_Idle : busState;
                default: nextBusState = BusState_Setup;
            endcase
        end
    end

    always_comb begin
        if (state == State_DCacheRead || state == State_DCacheWrite) begin
            nextDone = rdataValid && (dcWordIndex == _dcache_word_index_t'(DCacheWordCount - 1));
        end
        else if (state == State_ICacheRead || state == State_ICacheWrite) begin
            nextDone = rdataValid && (icWordIndex == _icache_word_index_t'(ICacheWordCount - 1));
        end
        else begin
            nextDone = 1'b0;
        end
    end

    always_comb begin
        if (state == State_DCacheRead || state == State_DCacheWrite) begin
            nextDcWordIndex = (busState == BusState_Access && rdataValid) ? dcWordIndex + 1 : dcWordIndex;
        end
        else begin
            nextDcWordIndex = '0;
        end

        if (state == State_ICacheRead || state == State_ICacheWrite) begin
            nextIcWordIndex = (busState == BusState_Access && rdataValid) ? icWordIndex + 1 : icWordIndex;
        end
        else begin
            nextIcWordIndex = '0;
        end
    end

    always_comb begin
        unique case(state)
            State_Idle: begin
                nextDcValue = (core.dcWriteReq) ? core.dcWriteValue : '0;
            end
            State_DCacheRead: begin
                for (int i = 0; i < DCacheWordCount; i++) begin
                    nextDcValue[i] = (_dcache_word_index_t'(i) == dcWordIndex && rdataValid) ? rdata : dcValue[i];
                end
            end
            State_DCacheWrite: begin
                nextDcValue = core.dcWriteValue;
            end
            default: begin
                nextDcValue = '0;
            end
        endcase
    end

    always_comb begin
        unique case(state)
            State_Idle: begin
                nextIcValue = (core.icWriteReq) ? core.icWriteValue : '0;
            end
            State_ICacheRead: begin
                for (int i = 0; i < ICacheWordCount; i++) begin
                    nextIcValue[i] = (_icache_word_index_t'(i) == icWordIndex && rdataValid) ? rdata : icValue[i];
                end
            end
            State_ICacheWrite: begin
                nextIcValue = core.icWriteValue;
            end
            default: begin
                nextIcValue = '0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= State_Idle;
            busState <= BusState_Idle;
            done <= '0;
            dcWordIndex <= '0;
            icWordIndex <= '0;
            dcValue <= '0;
            icValue <= '0;
        end
        else begin
            state <= nextState;
            busState <= nextBusState;
            done <= nextDone;
            dcWordIndex <= nextDcWordIndex;
            icWordIndex <= nextIcWordIndex;
            dcValue <= nextDcValue;
            icValue <= nextIcValue;
        end
    end
endmodule
