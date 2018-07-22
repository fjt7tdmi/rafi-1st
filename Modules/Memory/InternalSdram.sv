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

module InternalSdram #(
    parameter AddrWidth,
    parameter DataWidth
)(
    input   logic writeReq,        //user write req
    output  logic writeAck,        //user write ack
    output  logic writeDataEnable, //user write enable
    input   logic [AddrWidth-1:0] writeAddr,  //user write address
    input   logic [DataWidth-1:0] writeData,  //user write data
    input   logic readReq,        //user read req
    output  logic readAck,        //user read ack
    input   logic [AddrWidth-1:0] readAddr, //user read address
    output  logic readDataEnable, //user read enable
    output  logic [DataWidth-1:0] readData, //user read  data
    input   logic clk,
    input   logic rst
);
    // parameters
    localparam BankWidth = 3;
    localparam BankCount = 1 << BankWidth;
    localparam BodyIndexWidth = AddrWidth;
    localparam BodyEntryCount = 1 << BodyIndexWidth;
    localparam CycleWidth = 4;

    localparam ReadStartCycle = 2;
    localparam ReadEnableCycle = 4;
    localparam ReadDisableCycle = 12;
    localparam ReadEndCycle = 12;
    localparam WriteEnableCycle = 0;
    localparam WriteStartCycle = 1;
    localparam WriteDisableCycle = 8;
    localparam WriteEndCycle = 9;

    // typedef
    typedef logic unsigned [BankWidth - 1 : 0] _bank_t;
    typedef logic unsigned [BodyIndexWidth - 1 : 0] _body_index_t;
    typedef logic unsigned [CycleWidth - 1: 0] _cycle_t;
    typedef logic unsigned [DataWidth - 1 : 0] _data_t;

    typedef enum logic [1:0]
    {
        State_Default   = 2'h0,
        State_Read      = 2'h1,
        State_Write     = 2'h2
    } State;

    // Body
    logic [DataWidth-1:0] body[BodyEntryCount];

    _data_t bodyReadValue;
    _data_t bodyWriteValue;
    logic bodyWriteEnable;
    _body_index_t bodyIndex;

    always_ff @(posedge clk) begin
        bodyReadValue <= body[bodyIndex];
        if (bodyWriteEnable) begin
            body[bodyIndex] <= bodyWriteValue;
        end
    end

    // Registers
    State reg_State;
    _cycle_t reg_Cycle;

    // Wires
    State next_State;
    _cycle_t next_Cycle;

    _bank_t bank;

    always_comb begin
        writeAck = (reg_State == State_Write) && (reg_Cycle == 0);
        writeDataEnable = (reg_State == State_Write) && (WriteEnableCycle <= reg_Cycle) && (reg_Cycle < WriteDisableCycle);
        readAck = (reg_State == State_Read) && (reg_Cycle == 0);
        readDataEnable = (reg_State == State_Read) && (ReadEnableCycle <= reg_Cycle) && (reg_Cycle < ReadDisableCycle);
        readData = bodyReadValue;

        unique case (reg_State)
        State_Read:     bank = reg_Cycle - ReadStartCycle;
        State_Write:    bank = reg_Cycle - WriteStartCycle;
        default:        bank = '0;
        endcase

        bodyWriteValue = writeData;
        bodyWriteEnable = (reg_State == State_Write) && (WriteStartCycle <= reg_Cycle) && (reg_Cycle < WriteEndCycle);

        unique case (reg_State)
        State_Read:     bodyIndex = {readAddr[AddrWidth-1:BankWidth], bank};
        State_Write:    bodyIndex = {writeAddr[AddrWidth-1:BankWidth], bank};
        default:        bodyIndex = '0;
        endcase

        unique case (reg_State)
        State_Read: begin
            if (reg_Cycle != ReadEndCycle) begin
                next_State = reg_State;
                next_Cycle = reg_Cycle + 1;
            end
            else begin
                next_State = State_Default;
                next_Cycle = '0;
            end
        end
        State_Write: begin
            if (reg_Cycle != WriteEndCycle) begin
                next_State = reg_State;
                next_Cycle = reg_Cycle + 1;
            end
            else begin
                next_State = State_Default;
                next_Cycle = '0;
            end
        end
        default: begin
            if (readReq) begin
                next_State = State_Read;
            end
            else if (writeReq) begin
                next_State = State_Write;
            end
            else begin
                next_State = State_Default;
            end
            next_Cycle = '0;
        end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_Cycle <= '0;
            reg_State <= State_Default;
        end
        else begin
            reg_Cycle <= next_Cycle;
            reg_State <= next_State;
        end
    end

endmodule