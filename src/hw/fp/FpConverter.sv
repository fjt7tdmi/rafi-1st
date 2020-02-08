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
import OpTypes::*;

module FpConverter (
    output word_t intResult,
    output uint64_t fpResult,
    output fflags_t flags,
    input FpConverterCommand command,
    input logic [2:0] roundingMode,
    input word_t intSrc,
    input uint64_t fpSrc,
    input logic clk,
    input logic rst
);

    always_comb begin
        intResult = '0;
        fpResult = '0;
        flags = '0;
    end
endmodule
