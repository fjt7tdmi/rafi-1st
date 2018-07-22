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

module UartTxTestUnit #(
    parameter BaudRate,
    parameter ClockFrequency
)(
    output  logic uartTx,
    input   logic clk,
    input   logic rst
);
    localparam MinValue = 8'h41;
    localparam MaxValue = 8'h5a;

    // Registers
    int8_t reg_Value;

    // Wires
    int8_t next_Value;

    logic empty;
    logic writeEnable;

    UartTx #(
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency)
    ) m_UartTx (
        .empty,
        .uartTx,
        .writeEnable,
        .writeValue(reg_Value),
        .clk,
        .rst
    );

    always_comb begin
        writeEnable = empty;

        if (writeEnable) begin
            next_Value = (reg_Value == MaxValue)
                ? MinValue
                : reg_Value + 1;
        end
        else begin
            next_Value = reg_Value;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_Value <= MinValue;
        end
        else begin
            reg_Value <= next_Value;
        end
    end
endmodule
