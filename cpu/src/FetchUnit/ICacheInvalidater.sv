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

module ICacheInvalidater #(
    parameter LineSize,
    parameter IndexWidth,
    parameter TagWidth
)(
    // Cache array access
    output logic arrayWriteEnable,
    output logic [IndexWidth-1:0] arrayIndex,
    output logic arrayWriteValid,
    output logic [TagWidth-1:0] arrayWriteTag,

    // TLB access
    output logic tlbInvalidate,

    // Control
    output logic waitInvalidate,
    output logic done,
    input logic enable,
    input logic invalidateICacheReq,
    input logic invalidateTlbReq,

    // clk & rst
    input logic clk,
    input logic rst
);
    localparam IndexLsb = $clog2(LineSize);
    localparam IndexMsb = IndexLsb + IndexWidth - 1;

    typedef logic [IndexWidth-1:0] _index_t;

    typedef enum logic
    {
        State_None = 1'h0,
        State_Invalidate = 1'h1
    } State;

    // Registers
    State r_State;
    _index_t r_Index;

    logic r_WaitICacheInvalidate;
    logic r_WaitTlbInvalidate;

    logic r_DoICacheInvalidate;
    logic r_DoTlbInvalidate;

    // Wires
    State nextState;
    _index_t nextIndex;

    logic nextWaitICacheInvalidate;
    logic nextWaitTlbInvalidate;

    logic nextDoICacheInvalidate;
    logic nextDoTlbInvalidate;

    always_comb begin
        // Cache array access
        arrayWriteEnable = (r_State == State_Invalidate);
        arrayIndex = r_Index;
        arrayWriteValid = r_DoICacheInvalidate;
        arrayWriteTag = '0;

        // TLB access
        tlbInvalidate = r_DoTlbInvalidate;

        // Wires
        if (r_State == State_Invalidate) begin
            nextIndex = r_Index + 1;
            nextState = (nextIndex == '0) ? State_None : State_Invalidate;
        end
        else begin
            nextIndex = '0;
            nextState = enable ? State_Invalidate : State_None;
        end

        if (r_State == State_None && nextState == State_Invalidate) begin
            nextWaitICacheInvalidate = '0;
            nextWaitTlbInvalidate = '0;
        end
        else begin
            nextWaitICacheInvalidate = r_WaitICacheInvalidate || invalidateICacheReq;
            nextWaitTlbInvalidate = r_WaitTlbInvalidate || invalidateTlbReq;
        end

        if (r_State == State_None && nextState == State_Invalidate) begin
            nextDoICacheInvalidate = r_WaitICacheInvalidate || invalidateICacheReq;
            nextDoTlbInvalidate = r_WaitTlbInvalidate || invalidateTlbReq;
        end
        else if (r_State == State_Invalidate && nextState == State_None) begin
            nextDoICacheInvalidate = '0;
            nextDoTlbInvalidate = '0;
        end
        else begin
            nextDoICacheInvalidate = r_DoICacheInvalidate;
            nextDoTlbInvalidate = r_DoTlbInvalidate;
        end

        // Control
        waitInvalidate = r_WaitICacheInvalidate || r_WaitTlbInvalidate;
        done = (r_State == State_Invalidate && nextState == State_None);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_State <= State_None;
            r_Index <= '0;
            r_WaitICacheInvalidate <= '0;
            r_WaitTlbInvalidate <= '0;
            r_DoICacheInvalidate <= '0;
            r_DoTlbInvalidate <= '0;
        end
        else begin
            r_State <= nextState;
            r_Index <= nextIndex;
            r_WaitICacheInvalidate <= nextWaitICacheInvalidate;
            r_WaitTlbInvalidate <= nextWaitTlbInvalidate;
            r_DoICacheInvalidate <= nextDoICacheInvalidate;
            r_DoTlbInvalidate <= nextDoTlbInvalidate;
        end
    end
endmodule
