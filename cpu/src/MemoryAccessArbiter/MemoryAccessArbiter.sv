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

module MemoryAccessArbiter (
    MemoryAccessArbiterIF.MemoryAccessArbiter bus,
    input logic clk,
    input logic rst
);
    typedef enum logic [2:0]
    {
        State_None         = 3'h0,
        State_DCacheRead   = 3'h4,
        State_DCacheWrite  = 3'h5,
        State_ICacheRead   = 3'h6,
        State_ICacheWrite  = 3'h7
    } State;

    // Registers
    State r_State;

    // Wires
    State nextState;

    always_comb begin
        // nextState
        unique case(r_State)
            State_None: begin
                if (bus.dcWriteReq) begin
                    nextState = State_DCacheWrite;
                end
                else if (bus.dcReadReq) begin
                    nextState = State_DCacheRead;
                end
                else if (bus.icWriteReq) begin
                    nextState = State_ICacheWrite;
                end
                else if (bus.icReadReq) begin
                    nextState = State_ICacheRead;
                end
                else begin
                    nextState = State_None;
                end
            end
            default: begin
                // State_DCacheRead, State_DCacheWrite, State_ICacheRead, State_ICacheWrite
                nextState = bus.memDone ? State_None : r_State;
            end
        endcase

        // bus
        bus.icReadValue = bus.memReadValue;
        bus.icReadGrant = (r_State == State_ICacheRead) && bus.memDone;
        bus.icWriteGrant = (r_State == State_ICacheWrite) && bus.memDone;

        bus.dcReadValue = bus.memReadValue;
        bus.dcReadGrant = (r_State == State_DCacheRead) && bus.memDone;
        bus.dcWriteGrant = (r_State == State_DCacheWrite) && bus.memDone;

        bus.memEnable = (r_State != State_None);
        bus.memIsWrite = (r_State == State_DCacheWrite || r_State == State_ICacheWrite);

        if (r_State == State_DCacheRead || r_State == State_DCacheWrite) begin
            bus.memAddr = bus.dcAddr;
            bus.memWriteValue = bus.dcWriteValue;
        end
        else if (r_State == State_ICacheRead || r_State == State_ICacheWrite) begin
            bus.memAddr = bus.icAddr;
            bus.memWriteValue = bus.icWriteValue;
        end
        else begin
            bus.memAddr = '0;
            bus.memWriteValue = '0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_State <= State_None;
        end
        else begin
            r_State <= nextState;
        end
    end
endmodule
