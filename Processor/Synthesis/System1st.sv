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

module System1st(
    // DRAM
    output wire [12:0] DRAM_ADDR,
    output wire [1:0] DRAM_BA,
    output wire DRAM_CAS_N,
    output wire DRAM_CKE,
    output wire DRAM_CLK,
    output wire DRAM_CS_N,
    inout  wire [15:0] DRAM_DQ,
    output wire DRAM_LDQM,
    output wire DRAM_RAS_N,
    output wire DRAM_UDQM,
    output wire DRAM_WE_N,

    // MISC
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,
    output wire [35:0] GPIO_1,
    input wire [17:0] SW,
    input wire [3:0] KEY,
    input wire [35:0] GPIO_0,
    input wire CLOCK_50
);
    // parameter
    parameter BaudRate = 115200;
    parameter ClockFrequency = 50 * 1000 * 1000;
    
    parameter SdramAddrWidth = 20;
    
    localparam SdramBankWidth = 3;
    localparam SdramDataWidth = 16;

    // typedef
    typedef enum logic [1:0]
    {
        UartLoadSizeType_0,
        UartLoadSizeType_64,
        UartLoadSizeType_32K,
        UartLoadSizeType_4M
    } UartLoadSizeType;

    // Registers
    UartLoadSizeType reg_UartLoadSize;

    // Wires
    logic clk;
    logic rst;

    logic uartRx;
    logic uartTx;
    int32_t uartLoadSize;

    logic [6:0] ledOut[6];
    logic [3:0] ledValue[6];

    int32_t hostIoValue;
    int32_t debugOut;
    int8_t  debugIn;

    logic unused;

    logic sdramWriteReq;
    logic sdramWriteAck;
    logic sdramWriteDataEnable;
    logic [SdramAddrWidth-1:0] sdramWriteAddr;
    logic [SdramDataWidth-1:0] sdramWriteData;
    logic sdramReadReq;
    logic sdramReadAck;
    logic [SdramAddrWidth-1:0] sdramReadAddr;
    logic sdramReadDataEnable;
    logic [SdramDataWidth-1:0] sdramReadData;

    logic [3:0] sdramState;
    logic sdramOutEnable;
    logic [SdramDataWidth-1:0] sdramOutDQ;

    // Modules
    System #(
        .SdramAddrWidth(SdramAddrWidth),
        .SdramBankWidth(SdramBankWidth),
        .SdramDataWidth(SdramDataWidth),
        .BaudRate(BaudRate),
        .ClockFrequency(ClockFrequency)
    ) m_Top (
        // sdram
        .sdramWriteReq,
        .sdramWriteAck,
        .sdramWriteDataEnable,
        .sdramWriteAddr,
        .sdramWriteData,
        .sdramReadReq,
        .sdramReadAck,
        .sdramReadAddr,
        .sdramReadDataEnable,
        .sdramReadData,

        // debug
        .hostIoValue,
        .debugOut,
        .debugIn,

        // uart
        .uartLoadSize,
        .uartRx,
        .uartTx,

        // clk & rst
        .clk,
        .rst
    );

    sdram_ctrl m_SdramController (
        .ram_clke(DRAM_CKE),
        .ram_cs_n(DRAM_CS_N), 
        .ram_cas_n(DRAM_CAS_N),
        .ram_ras_n(DRAM_RAS_N),
        .ram_we_n(DRAM_WE_N),
        .ram_dqml(DRAM_LDQM),
        .ram_dqmu(DRAM_UDQM),
        .ram_ba0(DRAM_BA[0]),
        .ram_ba1(DRAM_BA[1]),
        .ram_adr(DRAM_ADDR),
        .ram_dq_w(sdramOutDQ),
        .ram_dq_r(DRAM_DQ),
        .u_wreq(sdramWriteReq),
        .u_wack(sdramWriteAck),
        .u_wr_da_en(sdramWriteDataEnable),
        .u_wadr(sdramWriteAddr),
        .u_wr_da(sdramWriteData),
        .u_rreq(sdramReadReq),
        .u_rack(sdramReadAck),
        .u_radr(sdramReadAddr),
        .u_rd_da_en(sdramReadDataEnable),
        .u_rd_da(sdramReadData),
        .out_en(sdramOutEnable),
        .state(sdramState),
        .clk,
        .reset_n(~rst)
    );

    assign DRAM_DQ = sdramOutEnable ? sdramOutDQ : 'z;
    assign DRAM_CLK = clk;

    Led7segDecoder m_Decoder0 (
        .in(ledValue[0]),
        .out(ledOut[0])
    );

    Led7segDecoder m_Decoder1 (
        .in(ledValue[1]),
        .out(ledOut[1])
    );

    Led7segDecoder m_Decoder2 (
        .in(ledValue[2]),
        .out(ledOut[2])
    );

    Led7segDecoder m_Decoder3 (
        .in(ledValue[3]),
        .out(ledOut[3])
    );

    Led7segDecoder m_Decoder4 (
        .in(ledValue[4]),
        .out(ledOut[4])
    );

    Led7segDecoder m_Decoder5 (
        .in(ledValue[5]),
        .out(ledOut[5])
    );

    always_comb begin
        LEDR[9:8] = reg_UartLoadSize;

        for (int i = 0; i < 8; i++) begin
            LEDR[i] = debugOut[i + 24];
        end
        ledValue[5] = debugOut[23:20];
        ledValue[4] = debugOut[19:16];
        ledValue[3] = debugOut[15:12];
        ledValue[2] = debugOut[11:8];
        ledValue[1] = debugOut[7:4];
        ledValue[0] = debugOut[3:0];

        HEX0 = ~ledOut[0];
        HEX1 = ~ledOut[1];
        HEX2 = ~ledOut[2];
        HEX3 = ~ledOut[3];
        HEX4 = ~ledOut[4];
        HEX5 = ~ledOut[5];

        clk = CLOCK_50;
        rst = ~KEY[0];
        uartRx = GPIO_0[0];
        debugIn = SW[7:0];

        GPIO_1[0] = uartTx;

        unique case (reg_UartLoadSize)
        UartLoadSizeType_64:    uartLoadSize = 64;
        UartLoadSizeType_32K:   uartLoadSize = 32 * 1024;
        UartLoadSizeType_4M:    uartLoadSize = 4 * 1024 * 1024;
        default:                uartLoadSize = 0;
        endcase

        // To suppress warning, do something for unused pins.
        unused = (|KEY[3:1]) || (|GPIO_0[35:1]);
        GPIO_1[35:1] = unused ? '1 : '0;
    end

    always @(posedge clk) begin
        if (rst) begin
            reg_UartLoadSize <= UartLoadSizeType'(SW[9:8]);
        end
        else begin
            reg_UartLoadSize <= reg_UartLoadSize;
        end
    end
endmodule
