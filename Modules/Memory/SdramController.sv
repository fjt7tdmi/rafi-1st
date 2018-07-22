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

module SdramController #(
    parameter UserAddrWidth,
    parameter UserLineSize,
    parameter UserLineWidth = UserLineSize * ByteWidth,
    parameter MemoryAddrWidth = 25,
    parameter MemoryDataWidth = 16
)(
    // Signals for sdram
    output  logic memoryWriteReq, //user write req
    input   logic memoryWriteAck, //user write ack
    input   logic memoryWriteDataEnable,  //user write enable
    output  logic [MemoryAddrWidth-1:0]   memoryWriteAddr, //user write address
    output  logic [MemoryDataWidth-1:0]   memoryWriteData, //user write data
    output  logic memoryReadReq,  //user read req
    input   logic memoryReadAck,  //user read ack
    output  logic [MemoryAddrWidth-1:0]   memoryReadAddr, //user read address
    input   logic memoryReadDataEnable,   //user read  enable
    input   logic [MemoryDataWidth-1:0]   memoryReadData, //user read  data

    // Signals for user
    output  logic userDone,
    output  logic [UserLineWidth-1:0] userReadValue,
    input   logic [UserAddrWidth-1:0] userAddr,
    input   logic userEnable,
    input   logic userIsWrite,
    input   logic [UserLineWidth-1:0] userWriteValue,

    // Clock and Reset
    input   logic clk,
    input   logic rst
);
    // parameters
    localparam BankCount = UserLineWidth / MemoryDataWidth;
    localparam BankIndexMax = BankCount - 1;
    localparam BankIndexWidth = $clog2(BankCount);

    // typedef
    typedef logic unsigned [$clog2(BankCount)-1:0] _bank_index_t;
    typedef logic unsigned [MemoryDataWidth-1:0] _memory_data_t;

    typedef enum logic [2:0]
    {
        State_Default       = 3'h0,
        State_WaitReadAck   = 3'h1,
        State_ReadMemory    = 3'h2,
        State_ReadDone      = 3'h3,
        State_WaitWriteAck  = 3'h5,
        State_WriteMemory   = 3'h6,
        State_WriteDone     = 3'h7
    } State;

    // Registers
    State reg_State;

    // TODO: integrate reg_ReadData and reg_WriteData for optimization.
    _memory_data_t reg_ReadDataBuffer;
    _memory_data_t [BankCount-1:0] reg_ReadData;
    _memory_data_t [BankCount-1:0] reg_WriteData;
    logic [MemoryAddrWidth - BankIndexWidth - 1 : 0] reg_Addr;
    _bank_index_t reg_Index;

    // Wires
    State next_State;
    _memory_data_t [BankCount-1:0] next_ReadData;
    _memory_data_t [BankCount-1:0] next_WriteData;
    logic [MemoryAddrWidth - BankIndexWidth - 1 : 0] next_Addr;
    _bank_index_t next_Index;

    always_comb begin
        userDone = (reg_State == State_ReadDone || reg_State == State_WriteDone);
        userReadValue = reg_ReadData;

        memoryWriteReq = (reg_State == State_WaitWriteAck);
        memoryWriteAddr = {reg_Addr, reg_Index};
        memoryWriteData = reg_WriteData[reg_Index];

        memoryReadReq = (reg_State == State_WaitReadAck);
        memoryReadAddr = {reg_Addr, reg_Index};

        // next_State
        unique case (reg_State)
        State_WaitReadAck:  next_State = memoryReadAck ? State_ReadMemory : reg_State;
        State_ReadMemory:   next_State = (reg_Index == BankIndexMax) ? State_ReadDone : reg_State;
        State_ReadDone:     next_State = State_Default;
        State_WaitWriteAck: next_State = memoryWriteAck ? State_WriteMemory : reg_State;
        State_WriteMemory:  next_State = (reg_Index == BankIndexMax) ? State_WriteDone : reg_State;
        State_WriteDone:    next_State = State_Default;
        default: begin
            // State_Default
            if (userEnable && !userIsWrite) begin
                next_State = State_WaitReadAck;
            end
            else if (userEnable && userIsWrite) begin
                next_State = State_WaitWriteAck;
            end
            else begin
                next_State = reg_State;
            end
        end
        endcase

        // next_ReadData
        if (reg_State == State_ReadMemory) begin
            for (int i = 0; i < BankCount; i++) begin
                if (i == reg_Index) begin
                    next_ReadData[i] = reg_ReadDataBuffer;
                end
                else begin
                    next_ReadData[i] = reg_ReadData[i];
                end
            end
        end
        else begin
            next_ReadData = reg_ReadData;
        end

        // next_WriteData, next_Addr
        if (reg_State == State_Default && userEnable) begin
            next_WriteData = userWriteValue;
            next_Addr = userAddr[MemoryAddrWidth - BankIndexWidth - 1 : 0];
        end
        else begin
            next_WriteData = reg_WriteData;
            next_Addr = reg_Addr;
        end

        // nextIndex
        if (reg_State == State_Default) begin
            next_Index = '0;
        end
        else begin
            next_Index = (memoryReadDataEnable || reg_State == State_WriteMemory)
                ? reg_Index + 1
                : reg_Index;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_State <= State_Default;
            reg_ReadDataBuffer <= '0;
            reg_ReadData <= '0;
            reg_WriteData <= '0;
            reg_Addr <= '0;
            reg_Index <= '0;
        end
        else begin
            reg_State <= next_State;
            reg_ReadDataBuffer <= memoryReadData;
            reg_ReadData <= next_ReadData;
            reg_WriteData <= next_WriteData;
            reg_Addr <= next_Addr;
            reg_Index <= next_Index;
        end
    end
endmodule
