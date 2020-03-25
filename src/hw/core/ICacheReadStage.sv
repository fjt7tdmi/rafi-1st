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

import CacheTypes::*;
import RafiTypes::*;

module ICacheReadStage(
    FetchAddrTranslateStageIF.NextStage prevStage,
    ICacheReadStageIF.ThisStage nextStage,
    FetchPipeControllerIF.ICacheReadStage ctrl,
    input   logic clk,
    input   logic rst
);
    // Dummy
    paddr_t memAddr;
    logic memReadEnable;
    logic memReadDone;
    icache_line_t memReadValue;
    always_comb begin
        memReadDone = 0;
        memReadValue = '0;
    end

    // ICache
    logic nextStageValid;
    logic nextStageCacheMiss;
    icache_line_t nextStageReadValue;

    ICache #(
        .LINE_SIZE(ICACHE_LINE_SIZE),
        .TAG_WIDTH(ICACHE_TAG_WIDTH),
        .INDEX_WIDTH(ICACHE_INDEX_WIDTH)
    ) iCache (
        .memAddr(memAddr),
        .memReadEnable(memReadEnable),
        .memReadDone(memReadDone),
        .memReadValue(memReadValue),
        .nextStageValid(nextStageValid),
        .nextStageCacheMiss(nextStageCacheMiss),
        .nextStageReadValue(nextStageReadValue),
        .stall(ctrl.stallFromICacheReadStage),
        .fetchEnable(prevStage.valid),
        .addr(prevStage.pc_paddr),
        .invalidateDone(ctrl.invalidateICacheDone),
        .invalidateEnable(ctrl.invalidateICache),
        .clk,
        .rst
    );

    // ICacheReadStageIF
    always_ff @(posedge clk) begin
        if (rst || ctrl.flush) begin
            nextStage.valid <= '0;
            nextStage.fault <= '0;
            nextStage.pc_vaddr <= '0;
            nextStage.pc_paddr <= '0;
            nextStage.iCacheLine <= '0;
        end
        else if (ctrl.stall) begin
            nextStage.valid <= nextStage.valid;
            nextStage.fault <= nextStage.fault;
            nextStage.pc_vaddr <= nextStage.pc_vaddr;
            nextStage.pc_paddr <= nextStage.pc_paddr;
            nextStage.iCacheLine <= nextStage.iCacheLine;
        end
        else begin
            nextStage.valid <= nextStageValid;
            nextStage.fault <= prevStage.fault;
            nextStage.pc_vaddr <= prevStage.pc_vaddr;
            nextStage.pc_paddr <= prevStage.pc_paddr;
            nextStage.iCacheLine <= nextStageReadValue;
        end
    end
endmodule