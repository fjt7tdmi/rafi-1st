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

import ProcessorTypes::*;

module PipelineController(
    PipelineControllerIF.PipelineController bus,
    input logic clk,
    input logic rst
);
    always_comb begin
        bus.flush = bus.flushReq;

        bus.ifStall = bus.exStallReq;
        bus.idStall = bus.exStallReq;
        bus.rrStall = bus.exStallReq;
        bus.bypassStall = bus.exStallReq;
    end
endmodule